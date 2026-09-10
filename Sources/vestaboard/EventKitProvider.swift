import EventKit
import Foundation
import VestaboardCore

/// Reads upcoming events from the macOS Calendar via EventKit — the in-process
/// replacement for the former `get-events` Swift helper.
actor EventKitProvider {
    let calendarNames: [String]
    private let store = EKEventStore()

    init(calendarNames: [String]) {
        self.calendarNames = calendarNames
    }

    /// Requests Calendar access if it has not yet been determined.
    ///
    /// - Throws: ``EventProviderError/accessDenied`` if access is denied or
    ///   restricted.
    func requestAccess() async throws {
        let status = EKEventStore.authorizationStatus(for: .event)
        switch status {
        case .notDetermined:
            // Access is granted per-process, so a local store avoids sending
            // the actor-isolated `store` to nonisolated request methods.
            let requestStore = EKEventStore()
            if #available(macOS 14.0, *) {
                _ = try? await requestStore.requestFullAccessToEvents()
            } else {
                _ = try? await requestStore.requestAccess(to: .event)
            }
        case .denied, .restricted:
            throw EventProviderError.accessDenied
        default:
            break
        }
    }

    /// Fetches upcoming events across the configured calendars over the next
    /// two days. All-day events are included and filtered downstream.
    func upcomingEvents() async throws -> [CalendarEvent] {
        try await requestAccess()

        let now = Date()
        let calendar = Calendar.current
        guard
            let future = calendar.date(
                byAdding: .day, value: 2, to: calendar.startOfDay(for: now))
        else {
            return []
        }

        let allCalendars = store.calendars(for: .event)
        let matching = allCalendars.filter { calendarNames.contains($0.title) }
        guard !matching.isEmpty else {
            throw EventProviderError.noMatchingCalendars(calendarNames)
        }

        let predicate = store.predicateForEvents(
            withStart: now, end: future, calendars: matching)
        let events = store.events(matching: predicate)
            .filter { $0.startDate > now }
            .sorted { $0.startDate < $1.startDate }

        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "EEEE, MMMM d, yyyy 'at' h:mm:ss a"

        return events.map { event in
            CalendarEvent(
                summary: event.title ?? "Event",
                start: formatter.string(from: event.startDate),
                allDay: event.isAllDay,
                date: event.startDate)
        }
    }
}

enum EventProviderError: Error, CustomStringConvertible {
    case accessDenied
    case noMatchingCalendars([String])

    var description: String {
        switch self {
        case .accessDenied:
            return
                "Calendar access denied. Grant access in System Settings > Privacy & Security > Calendars."
        case let .noMatchingCalendars(names):
            return "No matching calendars found for: \(names.joined(separator: ", "))"
        }
    }
}
