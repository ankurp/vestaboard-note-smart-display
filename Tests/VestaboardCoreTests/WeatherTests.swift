import Testing

@testable import VestaboardCore

@Suite struct WeatherTests {
    @Test func buildsA3x15Board() {
        let board = Weather.buildBoard(
            current: CurrentWeather(temperature: 71.6, weatherCode: 0), cityName: "Irvine")
        #expect(board.count == 3)
        #expect(board.allSatisfy { $0.count == 15 })
    }

    @Test func roundsTheTemperature() {
        let board = Weather.buildBoard(
            current: CurrentWeather(temperature: 71.6, weatherCode: 0), cityName: "Irvine")
        // 71.6 -> 72; "72°F" -> 7, 2, degree, F
        let codes = board[1].filter { $0 != 0 }
        #expect(codes == [33, 28, 62, 6])
    }

    @Test func fallsBackToWeatherForUnknownCodes() {
        let board = Weather.buildBoard(
            current: CurrentWeather(temperature: 50, weatherCode: 999), cityName: "X")
        let codes = board[2].filter { $0 != 0 }
        // "WEATHER" -> W E A T H E R
        #expect(codes == [23, 5, 1, 20, 8, 5, 18])
    }
}
