import Testing

@testable import VestaboardCore

@Suite struct DisplayTests {
    @Test func mapsTextToCharCodesUppercasing() {
        #expect(Display.textToCharCodes("AB") == [1, 2])
        #expect(Display.textToCharCodes("ab") == [1, 2])
    }

    @Test func mapsUnknownCharactersToBlank() {
        #expect(Display.textToCharCodes("~") == [Display.blank])
    }

    @Test func buildsFullWidthBlankRow() {
        let row = Display.blankRow()
        #expect(row.count == 15)
        #expect(row.allSatisfy { $0 == 0 })
    }

    @Test func centersCodesWithin15WideRow() {
        let row = Display.centerRow(Display.textToCharCodes("HI"))
        #expect(row.count == 15)
        // "HI" (2 chars) -> padding of 6 on the left.
        #expect(Array(row[6..<8]) == [8, 9])
    }

    @Test func leftAlignsCodesWithin15WideRow() {
        let row = Display.leftRow(Display.textToCharCodes("HI"))
        #expect(row.count == 15)
        #expect(Array(row[0..<2]) == [8, 9])
    }

    @Test func truncatesRowsLongerThanBoardWidth() {
        let row = Display.centerRow(Display.textToCharCodes("ABCDEFGHIJKLMNOPQRST"))
        #expect(row.count == 15)
    }

    @Test func comparesBoardsForDeepEquality() {
        let a = [Display.blankRow(), Display.blankRow(), Display.blankRow()]
        var b = [Display.blankRow(), Display.blankRow(), Display.blankRow()]
        #expect(Display.boardsEqual(a, b))
        b[0][0] = 1
        #expect(!Display.boardsEqual(a, b))
    }
}
