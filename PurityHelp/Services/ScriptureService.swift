//
//  ScriptureService.swift
//  PurityHelp
//
//  RSV verses by feature; daily passage from JSON or fallback.
//

import Foundation

struct ScriptureVerse: Identifiable {
    let id: String
    let reference: String
    let text: String
    var translation: String? = nil
}

private struct ScriptureVerseJSON: Codable {
    let id: String
    let reference: String
    let text: String
    let category: String?
}

struct ScriptureService {
    static let coreAnchor: [ScriptureVerse] = [
        ScriptureVerse(id: "mt5_8", reference: "Matthew 5:8", text: "Blessed are the pure in heart, for they shall see God."),
        ScriptureVerse(id: "ps51_12", reference: "Psalm 51:12", text: "Create in me a clean heart, O God, and put a new and right spirit within me.")
    ]

    static let urgeMoment: [ScriptureVerse] = [
        ScriptureVerse(id: "1cor10_13", reference: "1 Corinthians 10:13", text: "God is faithful, and he will not let you be tempted beyond your strength, but with the temptation will also provide the way of escape."),
        ScriptureVerse(id: "mt26_41", reference: "Matthew 26:41", text: "Watch and pray that you may not enter into temptation; the spirit indeed is willing, but the flesh is weak."),
        ScriptureVerse(id: "phil4_13", reference: "Philippians 4:13", text: "I can do all things in him who strengthens me.")
    ]

    static let reset: [ScriptureVerse] = [
        ScriptureVerse(id: "lam3_22", reference: "Lamentations 3:22-23", text: "The steadfast love of the Lord never ceases, his mercies never come to an end; they are new every morning."),
        ScriptureVerse(id: "2cor5_17", reference: "2 Corinthians 5:17", text: "If any one is in Christ, he is a new creation; the old has passed away, behold, the new has come.")
    ]

    static let allVerses: [ScriptureVerse] = coreAnchor + urgeMoment + reset

    /// Today's verse: load from daily_scripture.json, pick by day-of-year % count; fallback to coreAnchor.
    static func verseForToday() -> ScriptureVerse {
        let url = Bundle.main.url(forResource: "daily_scripture", withExtension: "json", subdirectory: "Resources/Scripture")
            ?? Bundle.main.url(forResource: "daily_scripture", withExtension: "json", subdirectory: "Scripture")
            ?? Bundle.main.url(forResource: "daily_scripture", withExtension: "json")
        guard let u = url,
              let data = try? Data(contentsOf: u),
              let decoded = try? JSONDecoder().decode([ScriptureVerseJSON].self, from: data),
              !decoded.isEmpty
        else {
            return coreAnchor[0]
        }
        let dayOfYear = Calendar.current.ordinality(of: .day, in: .year, for: Date()) ?? 1
        let index = dayOfYear % decoded.count
        let j = decoded[index]
        return ScriptureVerse(id: j.id, reference: j.reference, text: j.text)
    }

    /// Curated verses for "Hide in your heart" memorization (RSV). Loads from daily_scripture.json when available.
    static func versesForMemorization() -> [ScriptureVerse] {
        let url = Bundle.main.url(forResource: "daily_scripture", withExtension: "json", subdirectory: "Resources/Scripture")
            ?? Bundle.main.url(forResource: "daily_scripture", withExtension: "json", subdirectory: "Scripture")
            ?? Bundle.main.url(forResource: "daily_scripture", withExtension: "json")
        guard let u = url,
              let data = try? Data(contentsOf: u),
              let decoded = try? JSONDecoder().decode([ScriptureVerseJSON].self, from: data),
              !decoded.isEmpty
        else {
            return [coreAnchor[0], urgeMoment[0], urgeMoment[1], urgeMoment[2], reset[0], reset[1]]
        }
        return decoded.map { ScriptureVerse(id: $0.id, reference: $0.reference, text: $0.text) }
    }

    static func verseForUrgeMoment() -> ScriptureVerse {
        urgeMoment.randomElement() ?? urgeMoment[0]
    }

    static func verseForReset() -> ScriptureVerse {
        reset.randomElement() ?? reset[0]
    }
}
