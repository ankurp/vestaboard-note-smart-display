import Foundation
import VestaboardCore

/// Main process. Every minute it selects a board by priority and pushes it to
/// the Vestaboard only when the layout has changed:
///   1. Event   - an event starts within the next hour
///   2. Weather - the morning weather window
///   3. Default - the idle kitchen/date display
@main
struct VestaboardApp {
    static func main() async {
        let config = Config.load()
        do {
            try config.assertValid()
        } catch {
            FileHandle.standardError.write(Data("\(error)\n".utf8))
            exit(1)
        }

        let app = BoardRunner(config: config)
        await app.tick()
        print("Board running. Checking every minute. Press Ctrl+C to stop.")

        while true {
            try? await Task.sleep(nanoseconds: UInt64(Config.updateInterval * 1_000_000_000))
            await app.tick()
        }
    }
}

/// Owns the runtime state and per-tick board selection logic.
actor BoardRunner {
    private let config: Config
    private let client: VestaboardClient
    private let weather: WeatherService
    private let events: EventKitProvider
    private let summarizer = Summarizer()
    private var lastBoard: Board?

    init(config: Config) {
        self.config = config
        self.client = VestaboardClient(token: config.vestaboardToken ?? "")
        self.weather = WeatherService(config: config)
        self.events = EventKitProvider(calendarNames: config.calendarNames)
    }

    private func isWeatherWindow(now: Date = Date()) -> Bool {
        let hour = Calendar.current.component(.hour, from: now)
        return hour >= Config.weatherHourStart && hour < Config.weatherHourEnd
    }

    private func pickBoard() async -> (mode: String, board: Board) {
        // 1. An imminent event takes over the board.
        do {
            let upcoming = try await events.upcomingEvents()
            let imminent = CalendarBoard.selectImminent(upcoming)
            if !imminent.isEmpty {
                let board: Board
                if imminent.count == 1 {
                    board = CalendarBoard.buildEventBoard(imminent)
                } else {
                    let names = imminent.map { $0.summary.isEmpty ? "EVENT" : $0.summary }
                    let summaries = await summarizer.summarize(names)
                    board = CalendarBoard.buildEventBoard(imminent, summaries: summaries)
                }
                return ("event", board)
            }
        } catch {
            FileHandle.standardError.write(Data("Event lookup failed: \(error)\n".utf8))
        }

        // 2. Morning weather window.
        if config.isWeatherConfigured, isWeatherWindow() {
            if let board = await weather.board() {
                return ("weather", board)
            }
        }

        // 3. Default idle display.
        return ("default", Clock.buildBoard())
    }

    func tick() async {
        let timeStr = Self.timeFormatter.string(from: Date())
        let (mode, board) = await pickBoard()

        if let lastBoard, Display.boardsEqual(board, lastBoard) {
            print("[\(timeStr)] \(mode): unchanged, skipping.")
            return
        }

        print("[\(timeStr)] \(mode): updating board...")
        do {
            let result = try await client.send(board)
            lastBoard = board
            print("[\(timeStr)] Done: \(result)")
        } catch {
            FileHandle.standardError.write(Data("Update failed: \(error)\n".utf8))
        }
    }

    private static let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "h:mm:ss a"
        return formatter
    }()
}
