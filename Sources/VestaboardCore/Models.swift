import Foundation

/// A Vestaboard layout: three rows of fifteen character codes each.
public typealias Board = [[Int]]

/// A calendar event as read from the system and rendered on the board.
public struct CalendarEvent: Sendable, Equatable {
    /// The event title (e.g. "Soccer Practice").
    public var summary: String
    /// The raw start-time string (e.g. "Fri, Aug 28, 2026 at 6:30:00 PM").
    public var start: String
    /// Whether this is an all-day event.
    public var allDay: Bool
    /// The parsed start date, when available.
    public var date: Date?

    public init(summary: String, start: String, allDay: Bool, date: Date? = nil) {
        self.summary = summary
        self.start = start
        self.allDay = allDay
        self.date = date
    }
}
