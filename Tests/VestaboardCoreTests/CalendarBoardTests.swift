import Foundation
import Testing

@testable import VestaboardCore

@Suite struct CalendarBoardTests {
    // MARK: formatTime

    @Test func returnsAllForAllDayEvents() {
        #expect(CalendarBoard.formatTime("anything", allDay: true) == "ALL")
    }

    @Test func parses12HourTimesInto24HourHHMM() {
        #expect(
            CalendarBoard.formatTime("Fri, Aug 28, 2026 at 6:30:00 PM", allDay: false) == "18:30")
        #expect(
            CalendarBoard.formatTime("Fri, Aug 28, 2026 at 12:05:00 AM", allDay: false) == "00:05")
        #expect(
            CalendarBoard.formatTime("Fri, Aug 28, 2026 at 12:00:00 PM", allDay: false) == "12:00")
    }

    @Test func parses24HourTimes() {
        #expect(CalendarBoard.formatTime("2026-08-28 16:30:00", allDay: false) == "16:30")
    }

    @Test func returnsEmptyStringWhenNoTimePresent() {
        #expect(CalendarBoard.formatTime("no time here", allDay: false) == "")
    }

    // MARK: parseEventDate

    @Test func parsesTheHelperDateFormat() throws {
        let date = try #require(CalendarBoard.parseEventDate("Fri, Aug 28, 2026 at 6:30:00 PM"))
        var calendar = Calendar(identifier: .gregorian)
        calendar.locale = Locale(identifier: "en_US_POSIX")
        let components = calendar.dateComponents([.hour, .minute], from: date)
        #expect(components.hour == 18)
        #expect(components.minute == 30)
    }

    @Test func returnsNilForUnparseableInput() {
        #expect(CalendarBoard.parseEventDate("not a date") == nil)
    }

    // MARK: selectImminent

    private let now = makeDate(year: 2026, month: 8, day: 28, hour: 12)
    private func at(_ mins: Int) -> Date { now.addingTimeInterval(Double(mins) * 60) }

    @Test func keepsEventsStartingWithinNext60Minutes() {
        let events = [
            CalendarEvent(summary: "Soon", start: "", allDay: false, date: at(30)),
            CalendarEvent(summary: "TooFar", start: "", allDay: false, date: at(90)),
            CalendarEvent(summary: "Past", start: "", allDay: false, date: at(-10)),
        ]
        let result = CalendarBoard.selectImminent(events, now: now)
        #expect(result.map { $0.summary } == ["Soon"])
    }

    @Test func sortsBySoonestFirst() {
        let events = [
            CalendarEvent(summary: "Later", start: "", allDay: false, date: at(45)),
            CalendarEvent(summary: "Sooner", start: "", allDay: false, date: at(5)),
        ]
        let result = CalendarBoard.selectImminent(events, now: now)
        #expect(result.map { $0.summary } == ["Sooner", "Later"])
    }

    @Test func excludesAllDayEvents() {
        let events = [CalendarEvent(summary: "AllDay", start: "", allDay: true, date: at(10))]
        #expect(CalendarBoard.selectImminent(events, now: now).count == 0)
    }

    @Test func limitsResultToThreeEvents() {
        let events = (0..<5).map {
            CalendarEvent(summary: "E\($0)", start: "", allDay: false, date: at($0 + 1))
        }
        #expect(CalendarBoard.selectImminent(events, now: now).count == 3)
    }

    // MARK: buildEventBoard (single event)

    @Test func producesA3x15Board() {
        let soon = Date().addingTimeInterval(30 * 60)
        let event = CalendarEvent(summary: "Soccer Practice", start: "", allDay: false, date: soon)
        let board = CalendarBoard.buildEventBoard([event])
        #expect(board.count == 3)
        #expect(board.allSatisfy { $0.count == 15 })
    }

    @Test func rendersEventNameOnFirstRow() {
        let soon = Date().addingTimeInterval(30 * 60)
        let event = CalendarEvent(summary: "Soccer Practice", start: "", allDay: false, date: soon)
        let board = CalendarBoard.buildEventBoard([event])
        let codes = board[0].filter { $0 != 0 }
        // "SOCCER PRACTICE" -> starts with S, O, C
        #expect(Array(codes.prefix(3)) == [19, 15, 3])
    }

    @Test func framesTimeRowWithColorChipsRedForToday() {
        let soon = Date().addingTimeInterval(30 * 60)
        let event = CalendarEvent(summary: "Soccer Practice", start: "", allDay: false, date: soon)
        let board = CalendarBoard.buildEventBoard([event])
        let chips = board[1].filter { $0 == Display.red }
        #expect(chips.count == 2)
    }
}
