import EventKit
import Foundation

let store = EKEventStore()

// Check authorization status
let status = EKEventStore.authorizationStatus(for: .event)

if status == .notDetermined {
    let semaphore = DispatchSemaphore(value: 0)
    if #available(macOS 14.0, *) {
        store.requestFullAccessToEvents { _, _ in
            semaphore.signal()
        }
    } else {
        store.requestAccess(to: .event) { _, _ in
            semaphore.signal()
        }
    }
    semaphore.wait()
} else if status == .denied || status == .restricted {
    fputs("Calendar access denied. Grant access in System Settings > Privacy & Security > Calendars for Terminal.\n", stderr)
    exit(1)
}

// Get calendar names from args or default to "Family"
let calNames: [String]
if CommandLine.arguments.count > 1 {
    calNames = CommandLine.arguments[1].components(separatedBy: ",").map { $0.trimmingCharacters(in: .whitespaces) }
} else {
    calNames = ["Family"]
}

let now = Date()
let future = Calendar.current.date(byAdding: .day, value: 2, to: Calendar.current.startOfDay(for: now))!

// Find matching calendars
let allCalendars = store.calendars(for: .event)
let matchingCals = allCalendars.filter { calNames.contains($0.title) }

guard !matchingCals.isEmpty else {
    fputs("No matching calendars found for: \(calNames.joined(separator: ", "))\n", stderr)
    exit(0)
}

// Predicate fetches all events including recurring instances
let predicate = store.predicateForEvents(withStart: now, end: future, calendars: matchingCals)
let events = store.events(matching: predicate)

// Filter to only events that haven't started yet, then sort
let upcoming = events.filter { $0.startDate > now }
let sorted = upcoming.sorted { $0.startDate < $1.startDate }

for event in sorted {
    let formatter = DateFormatter()
    formatter.dateFormat = "EEEE, MMMM d, yyyy 'at' h:mm:ss a"
    let dateStr = formatter.string(from: event.startDate)
    let allDay = event.isAllDay ? "true" : "false"
    let summary = event.title ?? "Event"
    print("\(summary)||\(dateStr)||\(allDay)")
}
