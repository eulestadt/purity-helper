//
//  SyncTransferModels.swift
//  PurityHelp
//
//  Codable representations of SwiftData models for full JSON export/import via Partner API.
//

import Foundation

struct TransferStreakRecord: Codable {
    var pornographyStreakDays: Int
    var masturbationStreakDays: Int
    var pureThoughtsStreakDays: Int
    var pureThoughtsEnabled: Bool
    var pornographyLastResetDate: Date?
    var masturbationLastResetDate: Date?
    var pureThoughtsLastResetDate: Date?
    var pornographyLastCheckDate: Date?
    var masturbationLastCheckDate: Date?
    var pureThoughtsLastCheckDate: Date?
    var createdAt: Date
    var updatedAt: Date
}

struct TransferResetRecord: Codable {
    var type: String
    var date: Date
    var optionalNote: String?
    var triggerTag: String?
}

struct TransferUrgeLog: Codable {
    var date: Date
    var outcome: String
    var optionalNote: String?
    var durationMinutes: Int?
    var quickActionUsed: String?
    var replaceActivityUsed: String?
}

struct TransferExamenEntry: Codable {
    var date: Date
    var step1Thanks: String?
    var step2Light: String?
    var step3Examine: String?
    var step4Forgiveness: String?
    var step5Resolve: String?
    var howWasToday: String?
}

struct TransferIfThenPlan: Codable {
    var trigger: String
    var action: String
    var reminderEnabled: Bool
    var createdAt: Date
    var order: Int
}

struct TransferJournalEntry: Codable {
    var date: Date
    var type: String
    var optionalText: String?
    var tags: String?
    var moodOutcome: String?
    var durationCompleted: TimeInterval?
    var outcome: String?
}

struct TransferUserMission: Codable {
    var text: String
    var updatedAt: Date
}

struct TransferMemorizedVerse: Codable {
    var verseId: String
    var status: String
    var lastReviewedDate: Date?
    var customReference: String?
    var customText: String?
    var customTranslation: String?
}

struct FullSyncPayload: Codable {
    var exportedAt: Date = Date()
    var streakRecords: [TransferStreakRecord] = []
    var resetRecords: [TransferResetRecord] = []
    var urgeLogs: [TransferUrgeLog] = []
    var examenEntries: [TransferExamenEntry] = []
    var ifThenPlans: [TransferIfThenPlan] = []
    var journalEntries: [TransferJournalEntry] = []
    var userMissions: [TransferUserMission] = []
    var memorizedVerses: [TransferMemorizedVerse] = []
}
