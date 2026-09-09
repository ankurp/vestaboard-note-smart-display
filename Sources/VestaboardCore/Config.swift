import Foundation

/// Centralized configuration and behavior tuning, sourced from environment
/// variables (with `.env` fallback) and sensible defaults.
public struct Config: Sendable {
    public let vestaboardToken: String?
    public let zipCode: String?
    public let city: String?
    public let calendarNames: [String]

    // Vestaboard Note geometry.
    public static let rows = 3
    public static let cols = 15

    // Behavior tuning.
    public static let eventWindowMinutes = 60  // How soon an event takes over the board.
    public static let weatherHourStart = 7  // Weather window begins (24h, inclusive).
    public static let weatherHourEnd = 8  // Weather window ends (24h, exclusive).
    public static let weatherCache: TimeInterval = 30 * 60  // How long weather stays fresh.
    public static let updateInterval: TimeInterval = 60  // How often the board is re-evaluated.

    public init(vestaboardToken: String?, zipCode: String?, city: String?, calendarNames: [String]) {
        self.vestaboardToken = vestaboardToken
        self.zipCode = zipCode
        self.city = city
        self.calendarNames = calendarNames
    }

    /// Loads configuration from the process environment, falling back to a
    /// `.env` file for any variables not already set.
    public static func load(envPath: String = ".env") -> Config {
        let fileEnv = DotEnv.load(path: envPath)
        let processEnv = ProcessInfo.processInfo.environment

        func value(_ key: String) -> String? {
            let raw = processEnv[key] ?? fileEnv[key]
            guard let raw, !raw.isEmpty else { return nil }
            return raw
        }

        let names = (value("CALENDAR_NAME") ?? "Family")
            .split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }

        return Config(
            vestaboardToken: value("VESTABOARD_TOKEN"),
            zipCode: value("ZIP_CODE"),
            city: value("CITY"),
            calendarNames: names.isEmpty ? ["Family"] : names
        )
    }

    /// Whether a weather location has been configured.
    public var isWeatherConfigured: Bool {
        zipCode != nil || city != nil
    }

    /// Throws if required configuration is missing.
    public func assertValid() throws {
        if vestaboardToken == nil {
            throw ConfigError.missingToken
        }
    }
}

public enum ConfigError: Error, CustomStringConvertible {
    case missingToken

    public var description: String {
        switch self {
        case .missingToken:
            return "VESTABOARD_TOKEN is required in .env"
        }
    }
}
