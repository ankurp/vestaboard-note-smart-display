import Foundation

#if canImport(FoundationNetworking)
    import FoundationNetworking
#endif

/// Vestaboard character encoding and row-building helpers. A "board" is an
/// array of rows; each row is an array of character codes.
public enum Display {
    /// Named character codes for the Vestaboard Note.
    public static let blank = 0
    public static let heart = 62
    public static let degree = 62
    public static let red = 63  // Color chip used for today's events.
    public static let green = 66  // Color chip used for future events.

    /// Maps display characters to their Vestaboard character codes.
    static let charMap: [Character: Int] = [
        " ": 0,
        "A": 1, "B": 2, "C": 3, "D": 4, "E": 5, "F": 6, "G": 7, "H": 8, "I": 9,
        "J": 10, "K": 11, "L": 12, "M": 13, "N": 14, "O": 15, "P": 16, "Q": 17,
        "R": 18, "S": 19, "T": 20, "U": 21, "V": 22, "W": 23, "X": 24, "Y": 25,
        "Z": 26,
        "1": 27, "2": 28, "3": 29, "4": 30, "5": 31, "6": 32, "7": 33, "8": 34,
        "9": 35, "0": 36,
        "!": 37, "@": 38, "#": 39, "$": 40, "(": 41, ")": 42, "-": 44, "+": 46,
        "&": 47, "=": 48, ";": 49, ":": 50, "'": 52, "\"": 53, "%": 54, ",": 55,
        ".": 56, "/": 59, "?": 60, "°": 62,
    ]

    /// Converts text into an array of Vestaboard character codes.
    public static func textToCharCodes(_ text: String) -> [Int] {
        text.uppercased().map { charMap[$0] ?? blank }
    }

    /// Returns a full-width blank row.
    public static func blankRow() -> [Int] {
        Array(repeating: blank, count: Config.cols)
    }

    /// Places codes into a centered, full-width row (truncating if too long).
    public static func centerRow(_ codes: [Int]) -> [Int] {
        if codes.count >= Config.cols { return Array(codes.prefix(Config.cols)) }
        let padding = (Config.cols - codes.count) / 2
        var row = blankRow()
        for (i, code) in codes.enumerated() {
            row[padding + i] = code
        }
        return row
    }

    /// Places codes into a left-aligned, full-width row (truncating if too long).
    public static func leftRow(_ codes: [Int]) -> [Int] {
        if codes.count >= Config.cols { return Array(codes.prefix(Config.cols)) }
        var row = blankRow()
        for (i, code) in codes.enumerated() {
            row[i] = code
        }
        return row
    }

    /// Deep-compares two boards for equality.
    public static func boardsEqual(_ a: Board, _ b: Board) -> Bool {
        a == b
    }
}

/// Errors raised while talking to the Vestaboard Cloud API.
public enum VestaboardError: Error, CustomStringConvertible {
    case httpError(status: Int, body: String)
    case invalidResponse

    public var description: String {
        switch self {
        case let .httpError(status, body):
            return "Vestaboard API error: \(status) - \(body)"
        case .invalidResponse:
            return "Vestaboard API error: invalid response"
        }
    }
}

/// Client for the Vestaboard Cloud API.
public struct VestaboardClient: Sendable {
    private static let url = URL(string: "https://cloud.vestaboard.com/")!
    private let token: String
    private let session: URLSession

    public init(token: String, session: URLSession = .shared) {
        self.token = token
        self.session = session
    }

    /// Sends a board to the Vestaboard. A 409 (fingerprint match) means the
    /// board already shows this message and is treated as success.
    ///
    /// - Returns: A short status string (e.g. `"ok"` or `"unchanged"`).
    @discardableResult
    public func send(_ board: Board) async throws -> String {
        var request = URLRequest(url: Self.url)
        request.httpMethod = "POST"
        request.setValue(token, forHTTPHeaderField: "X-Vestaboard-Token")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: ["characters": board])

        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse else {
            throw VestaboardError.invalidResponse
        }

        guard (200..<300).contains(http.statusCode) else {
            if http.statusCode == 409 { return "unchanged" }
            let body = String(data: data, encoding: .utf8) ?? ""
            throw VestaboardError.httpError(status: http.statusCode, body: body)
        }

        return "ok"
    }
}
