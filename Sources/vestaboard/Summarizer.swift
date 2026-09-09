import Foundation
import VestaboardCore

#if canImport(FoundationModels)
    import FoundationModels
#endif

/// Shortens event names to fit the display, caching results per name. Uses
/// Apple's on-device Foundation Models when available (macOS 26+) and falls
/// back to truncation otherwise — the in-process replacement for the former
/// `summarize` Swift helper.
actor Summarizer {
    private var cache: [String: String] = [:]

    /// Returns a shortened name for each input, in order.
    func summarize(_ names: [String]) async -> [String] {
        let uncached = names.filter { cache[$0] == nil }

        if !uncached.isEmpty {
            let shortened = await shorten(uncached)
            for (name, short) in zip(uncached, shortened) {
                cache[name] = short.isEmpty ? CalendarBoard.truncate(name) : short
            }
        }

        return names.map { cache[$0] ?? CalendarBoard.truncate($0) }
    }

    /// Attempts a model-backed summarization, falling back to truncation.
    private func shorten(_ names: [String]) async -> [String] {
        #if canImport(FoundationModels)
            if #available(macOS 26.0, *) {
                do {
                    return try await modelShorten(names)
                } catch {
                    FileHandle.standardError.write(
                        Data("Summarize failed, falling back to truncation: \(error)\n".utf8))
                }
            }
        #endif
        return names.map { CalendarBoard.truncate($0) }
    }

    #if canImport(FoundationModels)
        @available(macOS 26.0, *)
        private func modelShorten(_ names: [String]) async throws -> [String] {
            let numbered = names.enumerated()
                .map { "\($0.offset + 1). \"\($0.element)\"" }
                .joined(separator: "\n")

            let prompt = """
                Shorten these calendar event names for a tiny display. Rules:
                - Each name must be max 9 characters
                - UPPERCASE only
                - Only letters, numbers, and spaces allowed
                - Output must be real recognizable words, NEVER abbreviations or acronyms
                - Keep the most distinctive/unique word from the name
                - If a word fits in 9 chars, just use that whole word
                - NEVER mash parts of words together (e.g. "Om Taekwondo" -> "TAEKWONDO" not "OMTA")
                - NEVER take first letters or syllables from multiple words
                - Examples:
                  "Om Taekwondo" -> "TAEKWONDO"
                  "Om music class" -> "MUSIC"
                  "Movie Theater Big Hero 6" -> "BIG HERO6"
                  "Doctor Appointment" -> "DOCTOR"
                  "Team Standup Meeting" -> "STANDUP"
                  "Soccer Practice" -> "SOCCER"
                - Return ONLY the shortened names, one per line, same order, no numbering

                \(numbered)
                """

            let session = LanguageModelSession()
            let response = try await session.respond(to: prompt)
            return response.content
                .split(separator: "\n", omittingEmptySubsequences: true)
                .map { CalendarBoard.truncate($0.trimmingCharacters(in: .whitespaces)) }
        }
    #endif
}
