import FoundationModels
import Foundation

let session = LanguageModelSession()

let eventNames: [String]
if CommandLine.arguments.count > 1 {
    eventNames = Array(CommandLine.arguments.dropFirst())
} else {
    // Read from stdin, one per line
    var lines: [String] = []
    while let line = readLine() {
        let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmed.isEmpty { lines.append(trimmed) }
    }
    eventNames = lines
}

guard !eventNames.isEmpty else {
    exit(0)
}

let numbered = eventNames.enumerated().map { "\($0.offset + 1). \"\($0.element)\"" }.joined(separator: "\n")

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

do {
    let response = try await session.respond(to: prompt)
    print(response.content)
} catch {
    // Fallback: just truncate
    for name in eventNames {
        print(name.uppercased().prefix(9))
    }
}
