import Foundation

#if canImport(FoundationNetworking)
    import FoundationNetworking
#endif

/// Fetches local weather from Open-Meteo and renders it as a board.
public enum Weather {
    static let descriptions: [Int: String] = [
        0: "CLEAR",
        1: "MOSTLY CLR",
        2: "PARTLY CLD",
        3: "OVERCAST",
        45: "FOG",
        48: "RIME FOG",
        51: "LIGHT DRZL",
        53: "MOD DRIZZL",
        55: "DENSE DRZL",
        61: "LIGHT RAIN",
        63: "RAIN",
        65: "HEAVY RAIN",
        71: "LIGHT SNOW",
        73: "SNOW",
        75: "HEAVY SNOW",
        77: "SNOW GRAIN",
        80: "LGT SHOWER",
        81: "SHOWERS",
        82: "HVY SHOWER",
        85: "SNOW SHWR",
        86: "HVY SN SHR",
        95: "TSTORM",
        96: "TSTORM+HAL",
        99: "HVY TSTRM",
    ]

    /// Renders a fetched forecast as a board.
    public static func buildBoard(current: CurrentWeather, cityName: String) -> Board {
        let temp = Int(current.temperature.rounded())
        let description = descriptions[current.weatherCode] ?? "WEATHER"

        let city = String(cityName.uppercased().prefix(Config.cols))
        return [
            Display.centerRow(Display.textToCharCodes(city)),
            Display.centerRow(Display.textToCharCodes("\(temp)°F")),
            Display.centerRow(Display.textToCharCodes(description)),
        ]
    }
}

/// A resolved weather location.
public struct WeatherLocation: Sendable {
    public let name: String
    public let latitude: Double
    public let longitude: Double
}

/// The current-conditions slice of an Open-Meteo forecast.
public struct CurrentWeather: Sendable {
    public let temperature: Double
    public let weatherCode: Int

    public init(temperature: Double, weatherCode: Int) {
        self.temperature = temperature
        self.weatherCode = weatherCode
    }
}

public enum WeatherError: Error, CustomStringConvertible {
    case geocoding(status: Int)
    case cityNotFound(String)
    case zipNotFound(String)
    case forecast(status: Int)

    public var description: String {
        switch self {
        case let .geocoding(status): return "Geocoding error: \(status)"
        case let .cityNotFound(city): return "City not found: \(city)"
        case let .zipNotFound(zip): return "Could not geocode ZIP: \(zip)"
        case let .forecast(status): return "Weather API error: \(status)"
        }
    }
}

// MARK: - Open-Meteo response models

private struct GeocodeResponse: Decodable {
    struct Result: Decodable {
        let name: String
        let latitude: Double
        let longitude: Double
    }
    let results: [Result]?
}

private struct ZipResponse: Decodable {
    struct Place: Decodable {
        let name: String
        let latitude: String
        let longitude: String
        enum CodingKeys: String, CodingKey {
            case name = "place name"
            case latitude
            case longitude
        }
    }
    let places: [Place]
}

private struct ForecastResponse: Decodable {
    struct Current: Decodable {
        let temperature: Double
        let weatherCode: Int
        enum CodingKeys: String, CodingKey {
            case temperature = "temperature_2m"
            case weatherCode = "weather_code"
        }
    }
    let current: Current
}

/// Fetches and caches a weather board, avoiding a refetch on every tick.
public actor WeatherService {
    private static let geocodeURL = "https://geocoding-api.open-meteo.com/v1/search"
    private static let zipURL = "https://api.zippopotam.us/us"
    private static let forecastURL = "https://api.open-meteo.com/v1/forecast"

    private let config: Config
    private let session: URLSession

    private var cachedLocation: WeatherLocation?
    private var cachedBoard: Board?
    private var cachedAt: Date = .distantPast

    public init(config: Config, session: URLSession = .shared) {
        self.config = config
        self.session = session
    }

    /// Returns a weather board, using a short-lived cache. Returns `nil` if the
    /// fetch fails.
    public func board(now: Date = Date()) async -> Board? {
        if let cachedBoard, now.timeIntervalSince(cachedAt) < Config.weatherCache {
            return cachedBoard
        }

        do {
            let location: WeatherLocation
            if let cachedLocation {
                location = cachedLocation
            } else {
                location = try await geocode()
                cachedLocation = location
            }
            let current = try await fetchWeather(
                latitude: location.latitude, longitude: location.longitude)
            let board = Weather.buildBoard(current: current, cityName: location.name)
            cachedBoard = board
            cachedAt = now
            return board
        } catch {
            FileHandle.standardError.write(
                Data("Weather fetch failed: \(error)\n".utf8))
            return nil
        }
    }

    private func geocode() async throws -> WeatherLocation {
        if let zip = config.zipCode {
            let url = "\(Self.geocodeURL)?name=\(zip)&count=1&language=en&format=json"
            let (data, response) = try await get(url)
            guard response.statusCode == 200 else {
                throw WeatherError.geocoding(status: response.statusCode)
            }
            let decoded = try JSONDecoder().decode(GeocodeResponse.self, from: data)
            if let first = decoded.results?.first {
                return WeatherLocation(
                    name: first.name, latitude: first.latitude, longitude: first.longitude)
            }

            // Fall back to a US ZIP lookup when the geocoder has no match.
            let (zipData, zipResponse) = try await get("\(Self.zipURL)/\(zip)")
            guard zipResponse.statusCode == 200 else {
                throw WeatherError.zipNotFound(zip)
            }
            let place = try JSONDecoder().decode(ZipResponse.self, from: zipData).places[0]
            return WeatherLocation(
                name: place.name,
                latitude: Double(place.latitude) ?? 0,
                longitude: Double(place.longitude) ?? 0)
        }

        let city = config.city ?? ""
        let encoded = city.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? city
        let url = "\(Self.geocodeURL)?name=\(encoded)&count=1&language=en&format=json"
        let (data, response) = try await get(url)
        guard response.statusCode == 200 else {
            throw WeatherError.geocoding(status: response.statusCode)
        }
        let decoded = try JSONDecoder().decode(GeocodeResponse.self, from: data)
        guard let first = decoded.results?.first else {
            throw WeatherError.cityNotFound(city)
        }
        return WeatherLocation(
            name: first.name, latitude: first.latitude, longitude: first.longitude)
    }

    private func fetchWeather(latitude: Double, longitude: Double) async throws -> CurrentWeather {
        let url =
            "\(Self.forecastURL)?latitude=\(latitude)&longitude=\(longitude)"
            + "&current=temperature_2m,weather_code,wind_speed_10m"
            + "&temperature_unit=fahrenheit&wind_speed_unit=mph&timezone=auto"
        let (data, response) = try await get(url)
        guard response.statusCode == 200 else {
            throw WeatherError.forecast(status: response.statusCode)
        }
        let decoded = try JSONDecoder().decode(ForecastResponse.self, from: data)
        return CurrentWeather(
            temperature: decoded.current.temperature,
            weatherCode: decoded.current.weatherCode)
    }

    private func get(_ urlString: String) async throws -> (Data, HTTPURLResponse) {
        guard let url = URL(string: urlString) else {
            throw WeatherError.geocoding(status: -1)
        }
        let (data, response) = try await session.data(from: url)
        guard let http = response as? HTTPURLResponse else {
            throw WeatherError.geocoding(status: -1)
        }
        return (data, http)
    }
}
