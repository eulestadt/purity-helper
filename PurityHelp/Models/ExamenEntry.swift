//
//  ExamenEntry.swift
//  PurityHelp
//
//  Daily Examen (Jesuit 5-step) entry.
//

import Foundation
import SwiftData

@Model
final class ExamenEntry {
    var date: Date = Date.now
    var step1Thanks: String?
    var step2Light: String?
    var step3Examine: String?
    var step4Forgiveness: String?
    var step5Resolve: String?
    var howWasToday: String?

    init(
        date: Date = .now,
        step1Thanks: String? = nil,
        step2Light: String? = nil,
        step3Examine: String? = nil,
        step4Forgiveness: String? = nil,
        step5Resolve: String? = nil,
        howWasToday: String? = nil
    ) {
        self.date = date
        self.step1Thanks = step1Thanks
        self.step2Light = step2Light
        self.step3Examine = step3Examine
        self.step4Forgiveness = step4Forgiveness
        self.step5Resolve = step5Resolve
        self.howWasToday = howWasToday
    }
}
