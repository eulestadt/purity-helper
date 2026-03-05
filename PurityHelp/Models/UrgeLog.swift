//
//  UrgeLog.swift
//  PurityHelp
//
//  Log of urge moments for pattern insight and journaling.
//

import Foundation
import SwiftData

@Model
final class UrgeLog {
    var date: Date = Date.now
    var outcome: String = "held_firm"
    var optionalNote: String?
    var durationMinutes: Int?
    /// Quick action chosen (e.g. "Call accountability partner", "Leave the room").
    var quickActionUsed: String?
    /// Replace activity chosen (e.g. "Read", "Pray").
    var replaceActivityUsed: String?

    init(
        date: Date = .now,
        outcome: String = "held_firm",
        optionalNote: String? = nil,
        durationMinutes: Int? = nil,
        quickActionUsed: String? = nil,
        replaceActivityUsed: String? = nil
    ) {
        self.date = date
        self.outcome = outcome
        self.optionalNote = optionalNote
        self.durationMinutes = durationMinutes
        self.quickActionUsed = quickActionUsed
        self.replaceActivityUsed = replaceActivityUsed
    }
}
