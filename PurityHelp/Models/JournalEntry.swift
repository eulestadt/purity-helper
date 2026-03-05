//
//  JournalEntry.swift
//  PurityHelp
//
//  Structured journal schema: date, type, optional text, tags, mood/outcome.
//  Types: Examen, urge log, reset reflection, boundary note.
//

import Foundation
import SwiftData

enum JournalEntryType: String, Codable {
    case examen
    case urgeLog
    case resetReflection
    case boundaryNote
    case vigilPrayer
}

@Model
final class JournalEntry {
    var date: Date = Date.now
    var type: String = ""
    var optionalText: String?
    var tags: String?
    var moodOutcome: String?
    var durationCompleted: TimeInterval?
    var outcome: String?

    init(
        date: Date = .now,
        type: JournalEntryType,
        optionalText: String? = nil,
        tags: String? = nil,
        moodOutcome: String? = nil,
        durationCompleted: TimeInterval? = nil,
        outcome: String? = nil
    ) {
        self.date = date
        self.type = type.rawValue
        self.optionalText = optionalText
        self.tags = tags
        self.moodOutcome = moodOutcome
        self.durationCompleted = durationCompleted
        self.outcome = outcome
    }

    var entryType: JournalEntryType? {
        JournalEntryType(rawValue: type)
    }

    var tagList: [String] {
        guard let tags, !tags.isEmpty else { return [] }
        return tags.split(separator: ",").map { String($0).trimmingCharacters(in: .whitespaces) }
    }
}
