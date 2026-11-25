//
//  ScriptureLibrary.swift
//

import Foundation

struct ScriptureVerse: Identifiable, Decodable {
    var id: String
    var reference: String
    var text: String
    var category: String
}

enum ScriptureLibrary {
    static func load() -> [ScriptureVerse] {
        guard let url = Bundle.main.url(forResource: "daily_scripture", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let verses = try? JSONDecoder().decode([ScriptureVerse].self, from: data) else {
            return [ScriptureVerse(id: "mt5_8", reference: "Matthew 5:8", text: "Blessed are the pure in heart, for they shall see God.", category: "Core")]
        }
        return verses
    }

    static func verseForToday(_ verses: [ScriptureVerse], date: Date = Date()) -> ScriptureVerse? {
        guard !verses.isEmpty else { return nil }
        let day = Calendar.current.ordinality(of: .day, in: .year, for: date) ?? 1
        return verses[(day - 1) % verses.count]
    }
}

struct HopeStory: Identifiable, Decodable {
    var id: String
    var title: String
    var category: String
    var tradition: String?
    var context: String
    var whatHelped: String
    var takeaway: String
}

enum StoryLibrary {
    static func load() -> [HopeStory] {
        guard let url = Bundle.main.url(forResource: "stories", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let stories = try? JSONDecoder().decode([HopeStory].self, from: data) else { return [] }
        return stories
    }
}
