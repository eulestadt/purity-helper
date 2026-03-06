//
//  ResetRecord.swift
//  PurityHelp
//
//  Preserves reset history for pattern analysis (danger zones, time of day, emotional triggers).
//

import Foundation
import SwiftData

enum ResetType: String, Codable, Identifiable {
    case pornography
    case masturbation
    case pureThoughts
    
    var id: Self { self }
}

@Model
final class ResetRecord {
    var id: String = UUID().uuidString
    var updatedAt: Date = Date.now
    var type: String = "pornography"
    var date: Date = Date.now
    var optionalNote: String?
    var triggerTag: String?

    init(
        id: String = UUID().uuidString,
        updatedAt: Date = .now,
        type: ResetType,
        date: Date = .now,
        optionalNote: String? = nil,
        triggerTag: String? = nil
    ) {
        self.id = id
        self.updatedAt = updatedAt
        self.type = type.rawValue
        self.date = date
        self.optionalNote = optionalNote
        self.triggerTag = triggerTag
    }

    var resetType: ResetType? {
        ResetType(rawValue: type)
    }
}
