import Foundation
import Testing

@testable import VestaboardCore

/// Builds a `Date` from local calendar components, matching the way the JS
/// tests constructed dates like `new Date("2026-08-28T09:00:00")`.
func makeDate(
    year: Int, month: Int, day: Int, hour: Int = 0, minute: Int = 0, second: Int = 0
) -> Date {
    var components = DateComponents()
    components.year = year
    components.month = month
    components.day = day
    components.hour = hour
    components.minute = minute
    components.second = second
    return Calendar.current.date(from: components)!
}

@Suite struct ClockTests {
    @Test func buildsA3x15Board() {
        let board = Clock.buildBoard(now: makeDate(year: 2026, month: 8, day: 28, hour: 9))
        #expect(board.count == 3)
        #expect(board.allSatisfy { $0.count == 15 })
    }

    @Test func includesHeartOnSecondRow() {
        let board = Clock.buildBoard(now: makeDate(year: 2026, month: 8, day: 28, hour: 9))
        #expect(board[1].contains(Display.heart))
    }

    @Test func rendersWeekdayAndDate() {
        // 2026-08-28 is a Friday.
        let board = Clock.buildBoard(now: makeDate(year: 2026, month: 8, day: 28, hour: 9))
        let codes = board[2].filter { $0 != 0 }
        // "FRI 08/28/2026" -> starts with F, R, I.
        #expect(Array(codes.prefix(3)) == [6, 18, 9])
    }
}
