import Foundation

/// The default "idle" board: a message plus the weekday and date.
public enum Clock {
    static let days = ["SUN", "MON", "TUE", "WED", "THU", "FRI", "SAT"]

    /// Builds the idle board for the given moment.
    public static func buildBoard(now: Date = Date()) -> Board {
        var calendar = Calendar(identifier: .gregorian)
        calendar.locale = Locale(identifier: "en_US_POSIX")
        let components = calendar.dateComponents(
            [.year, .month, .day, .weekday], from: now)

        let month = String(format: "%02d", components.month ?? 1)
        let day = String(format: "%02d", components.day ?? 1)
        let year = String(components.year ?? 0)
        // Calendar weekday is 1-based starting on Sunday.
        let weekday = Clock.days[((components.weekday ?? 1) - 1) % 7]

        return [
            Display.centerRow(Display.textToCharCodes("KITCHEN IS THE")),
            Display.centerRow([Display.heart] + Display.textToCharCodes(" OF THE HOME")),
            Display.centerRow(Display.textToCharCodes("\(weekday) \(month)/\(day)/\(year)")),
        ]
    }
}
