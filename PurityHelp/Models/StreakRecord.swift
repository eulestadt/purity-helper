//
//  StreakRecord.swift
//  PurityHelp
//
//  Pornography, masturbation, and optional pure-thoughts streak state.
//

import Foundation
import SwiftData

@Model
final class StreakRecord {
    var id: String = UUID().uuidString
    var pornographyStreakDays: Int = 0
    var masturbationStreakDays: Int = 0
    var pureThoughtsStreakDays: Int = 0
    var pureThoughtsEnabled: Bool = false
    var pornographyLastResetDate: Date?
    var masturbationLastResetDate: Date?
    var pureThoughtsLastResetDate: Date?
    var pornographyLastCheckDate: Date?
    var masturbationLastCheckDate: Date?
    var pureThoughtsLastCheckDate: Date?
    var createdAt: Date = Date.now
    var updatedAt: Date = Date.now

    init(
        id: String = UUID().uuidString,
        pornographyStreakDays: Int = 0,
        masturbationStreakDays: Int = 0,
        pureThoughtsStreakDays: Int = 0,
        pureThoughtsEnabled: Bool = false,
        pornographyLastResetDate: Date? = nil,
        masturbationLastResetDate: Date? = nil,
        pureThoughtsLastResetDate: Date? = nil,
        pornographyLastCheckDate: Date? = nil,
        masturbationLastCheckDate: Date? = nil,
        pureThoughtsLastCheckDate: Date? = nil,
        createdAt: Date = .now,
        updatedAt: Date = .now
    ) {
        self.id = id
        self.pornographyStreakDays = pornographyStreakDays
        self.masturbationStreakDays = masturbationStreakDays
        self.pureThoughtsStreakDays = pureThoughtsStreakDays
        self.pureThoughtsEnabled = pureThoughtsEnabled
        self.pornographyLastResetDate = pornographyLastResetDate
        self.masturbationLastResetDate = masturbationLastResetDate
        self.pureThoughtsLastResetDate = pureThoughtsLastResetDate
        self.pornographyLastCheckDate = pornographyLastCheckDate
        self.masturbationLastCheckDate = masturbationLastCheckDate
        self.pureThoughtsLastCheckDate = pureThoughtsLastCheckDate
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    /// Stricter of the two behavioral streaks (for tree visualization).
    var effectiveBehavioralStreak: Int {
        min(pornographyStreakDays, masturbationStreakDays)
    }
}
