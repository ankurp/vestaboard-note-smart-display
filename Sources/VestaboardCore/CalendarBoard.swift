import Foundation

/// Reads-and-renders helpers for calendar events. The board-building and
/// selection logic here is pure and platform-independent; reading events from
/// the system and shortening names live in the executable target.
public enum CalendarBoard {
    static let maxEvents = 3
    static let maxSummaryLen = 9

    private static let weekdaysShort = ["SUN", "MON", "TUE", "WED", "THU", "FRI", "SAT"]
    private static let weekdaysFull = [
        "SUNDAY", "MONDAY", "TUESDAY", "WEDNESDAY", "THURSDAY", "FRIDAY", "SATURDAY",
    ]

    /// Date formats accepted by ``parseEventDate(_:)`` (tried in order).
    private static let parseFormats = [
        "EEE, MMM d, yyyy 'at' h:mm:ss a",
        "EEEE, MMMM d, yyyy 'at' h:mm:ss a",
        "EEE, MMM d, yyyy h:mm:ss a",
        "EEEE, MMMM d, yyyy h:mm:ss a",
        "yyyy-MM-dd HH:mm:ss",
    ]

    /// Parses the helper's date string (e.g. "Thu, May 22, 2026 at 6:30:00 PM").
    public static func parseEventDate(_ dateStr: String) -> Date? {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        for format in parseFormats {
            formatter.dateFormat = format
            if let date = formatter.date(from: dateStr) {
                return date
            }
        }
        return nil
    }

    /// Formats an event start time as "HH:MM" (or "ALL" for all-day events).
    public static func formatTime(_ dateStr: String, allDay: Bool) -> String {
        if allDay { return "ALL" }

        if let match = dateStr.firstMatch(of: /(\d{1,2}):(\d{2}):\d{2}\s*([AaPp][Mm])/) {
            var hour = Int(match.1) ?? 0
            let minute = String(match.2)
            let period = String(match.3).uppercased()
            if period == "PM" && hour != 12 { hour += 12 }
            if period == "AM" && hour == 12 { hour = 0 }
            return String(format: "%02d:%@", hour, minute)
        }

        if let match = dateStr.firstMatch(of: /(\d{1,2}):(\d{2}):\d{2}/) {
            let hour = Int(match.1) ?? 0
            return String(format: "%02d:%@", hour, String(match.2))
        }

        return ""
    }

    /// Whether the given date falls on the same calendar day as `now`.
    static func isToday(_ date: Date, now: Date = Date()) -> Bool {
        Calendar.current.isDate(date, inSameDayAs: now)
    }

    /// Filters events to those starting within the window, soonest first.
    public static func selectImminent(_ events: [CalendarEvent], now: Date = Date())
        -> [CalendarEvent]
    {
        let cutoff = now.addingTimeInterval(Double(Config.eventWindowMinutes) * 60)

        return
            events
            .map { event -> CalendarEvent in
                var copy = event
                copy.date = event.date ?? parseEventDate(event.start)
                return copy
            }
            .filter { event in
                guard !event.allDay, let date = event.date else { return false }
                return date > now && date <= cutoff
            }
            .sorted { ($0.date ?? .distantFuture) < ($1.date ?? .distantFuture) }
            .prefix(maxEvents)
            .map { $0 }
    }

    /// Uppercases and truncates a name to the summary length — the fallback
    /// used when no smarter summarizer is available.
    public static func truncate(_ name: String) -> String {
        String(name.uppercased().prefix(maxSummaryLen))
    }

    /// Renders events as a board using simple truncation for names.
    public static func buildEventBoard(_ events: [CalendarEvent], now: Date = Date()) -> Board {
        let summaries = events.map { truncate($0.summary.isEmpty ? "EVENT" : $0.summary) }
        return buildEventBoard(events, summaries: summaries, now: now)
    }

    /// Renders events as a board. A single event uses the whole board; multiple
    /// events use one compact "HH:MM<color>SUMMARY" row each.
    ///
    /// - Parameter summaries: Pre-computed short names, one per event (used only
    ///   for the multi-event layout).
    public static func buildEventBoard(
        _ events: [CalendarEvent], summaries: [String], now: Date = Date()
    ) -> Board {
        if events.count == 1 {
            return buildSingleEventBoard(events[0], now: now)
        }

        return (0..<Config.rows).map { i in
            guard i < events.count else { return Display.blankRow() }

            let event = events[i]
            let colorCode =
                (event.date.map { isToday($0, now: now) } ?? false) ? Display.red : Display.green
            let summary = i < summaries.count ? summaries[i] : truncate(event.summary)
            let codes =
                Display.textToCharCodes(formatTime(event.start, allDay: event.allDay))
                + [colorCode]
                + Display.textToCharCodes(summary)

            var row = Display.blankRow()
            for j in 0..<min(codes.count, Config.cols) {
                row[j] = codes[j]
            }
            return row
        }
    }

    /// Formats a time as "6:30 PM" for the roomier single-event layout.
    static func formatTime12(_ event: CalendarEvent) -> String {
        guard let date = event.date ?? parseEventDate(event.start) else {
            return formatTime(event.start, allDay: event.allDay)
        }
        var calendar = Calendar(identifier: .gregorian)
        calendar.locale = Locale(identifier: "en_US_POSIX")
        let components = calendar.dateComponents([.hour, .minute], from: date)
        var hour = components.hour ?? 0
        let minute = String(format: "%02d", components.minute ?? 0)
        let period = hour >= 12 ? "PM" : "AM"
        hour %= 12
        if hour == 0 { hour = 12 }
        return "\(hour):\(minute) \(period)"
    }

    /// Relative day label: "TODAY" or the full weekday name.
    static func dayLabel(_ date: Date?, now: Date = Date()) -> String {
        guard let date else { return "" }
        if isToday(date, now: now) { return "TODAY" }
        let weekday = Calendar.current.component(.weekday, from: date)
        return weekdaysFull[(weekday - 1) % 7]
    }

    /// Full-board layout for a single event: name, framed time, and day.
    static func buildSingleEventBoard(_ event: CalendarEvent, now: Date = Date()) -> Board {
        let date = event.date ?? parseEventDate(event.start)
        let color = (date.map { isToday($0, now: now) } ?? false) ? Display.red : Display.green
        let name = String((event.summary.isEmpty ? "EVENT" : event.summary).uppercased().prefix(Config.cols))
        let timeCodes = Display.textToCharCodes(formatTime12(event))

        return [
            Display.centerRow(Display.textToCharCodes(name)),
            Display.centerRow([color, Display.blank] + timeCodes + [Display.blank, color]),
            Display.centerRow(Display.textToCharCodes(dayLabel(date, now: now))),
        ]
    }
}
