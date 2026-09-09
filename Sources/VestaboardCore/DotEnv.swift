import Foundation

/// Minimal `.env` file loader — a small replacement for the Node `dotenv`
/// package. Parses `KEY=VALUE` lines and returns them as a dictionary without
/// overwriting variables already present in the process environment.
public enum DotEnv {
    /// Loads variables from the given `.env` file, if it exists.
    ///
    /// - Parameter path: Path to the `.env` file. Defaults to `.env` in the
    ///   current working directory.
    /// - Returns: The parsed key/value pairs (empty when the file is missing).
    public static func load(path: String = ".env") -> [String: String] {
        guard let contents = try? String(contentsOfFile: path, encoding: .utf8) else {
            return [:]
        }

        var values: [String: String] = [:]
        for rawLine in contents.split(separator: "\n", omittingEmptySubsequences: true) {
            let line = rawLine.trimmingCharacters(in: .whitespaces)
            if line.isEmpty || line.hasPrefix("#") { continue }

            guard let separator = line.firstIndex(of: "=") else { continue }
            let key = line[..<separator].trimmingCharacters(in: .whitespaces)
            var value = line[line.index(after: separator)...].trimmingCharacters(in: .whitespaces)

            // Strip surrounding single or double quotes.
            if value.count >= 2,
                let first = value.first, let last = value.last,
                first == last, first == "\"" || first == "'"
            {
                value = String(value.dropFirst().dropLast())
            }

            if !key.isEmpty { values[key] = value }
        }
        return values
    }
}
