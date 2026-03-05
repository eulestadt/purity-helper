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
    var type: String = ""
    var date: Date = Date.now
    var optionalNote: String?
    var triggerTag: String?

    init(type: ResetType, date: Date = .now, optionalNote: String? = nil, triggerTag: String? = nil) {
        self.type = type.rawValue
        self.date = date
        self.optionalNote = optionalNote
        self.triggerTag = triggerTag
    }

    var resetType: ResetType? {
        ResetType(rawValue: type)
    }
}
