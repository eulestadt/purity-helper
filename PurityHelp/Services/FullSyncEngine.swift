//
//  FullSyncEngine.swift
//  PurityHelp
//
//  Orchestrates the export and import of full SwiftData schema to/from a JSON payload.
//

import Foundation
import SwiftData

struct FullSyncEngine {
    let context: ModelContext

    // MARK: - Export

    func exportFullData() throws -> FullSyncPayload {
        var payload = FullSyncPayload()

        payload.streakRecords = try context.fetch(FetchDescriptor<StreakRecord>()).map {
            TransferStreakRecord(
                pornographyStreakDays: $0.pornographyStreakDays,
                masturbationStreakDays: $0.masturbationStreakDays,
                pureThoughtsStreakDays: $0.pureThoughtsStreakDays,
                pureThoughtsEnabled: $0.pureThoughtsEnabled,
                pornographyLastResetDate: $0.pornographyLastResetDate,
                masturbationLastResetDate: $0.masturbationLastResetDate,
                pureThoughtsLastResetDate: $0.pureThoughtsLastResetDate,
                pornographyLastCheckDate: $0.pornographyLastCheckDate,
                masturbationLastCheckDate: $0.masturbationLastCheckDate,
                pureThoughtsLastCheckDate: $0.pureThoughtsLastCheckDate,
                createdAt: $0.createdAt,
                updatedAt: $0.updatedAt
            )
        }

        payload.resetRecords = try context.fetch(FetchDescriptor<ResetRecord>()).map {
            TransferResetRecord(
                type: $0.type,
                date: $0.date,
                optionalNote: $0.optionalNote,
                triggerTag: $0.triggerTag
            )
        }

        payload.urgeLogs = try context.fetch(FetchDescriptor<UrgeLog>()).map {
            TransferUrgeLog(
                date: $0.date,
                outcome: $0.outcome,
                optionalNote: $0.optionalNote,
                durationMinutes: $0.durationMinutes,
                quickActionUsed: $0.quickActionUsed,
                replaceActivityUsed: $0.replaceActivityUsed
            )
        }

        payload.examenEntries = try context.fetch(FetchDescriptor<ExamenEntry>()).map {
            TransferExamenEntry(
                date: $0.date,
                step1Thanks: $0.step1Thanks,
                step2Light: $0.step2Light,
                step3Examine: $0.step3Examine,
                step4Forgiveness: $0.step4Forgiveness,
                step5Resolve: $0.step5Resolve,
                howWasToday: $0.howWasToday
            )
        }

        payload.ifThenPlans = try context.fetch(FetchDescriptor<IfThenPlan>()).map {
            TransferIfThenPlan(
                trigger: $0.trigger,
                action: $0.action,
                reminderEnabled: $0.reminderEnabled,
                createdAt: $0.createdAt,
                order: $0.order
            )
        }

        payload.journalEntries = try context.fetch(FetchDescriptor<JournalEntry>()).map {
            TransferJournalEntry(
                date: $0.date,
                type: $0.type,
                optionalText: $0.optionalText,
                tags: $0.tags,
                moodOutcome: $0.moodOutcome,
                durationCompleted: $0.durationCompleted,
                outcome: $0.outcome
            )
        }

        payload.userMissions = try context.fetch(FetchDescriptor<UserMission>()).map {
            TransferUserMission(
                text: $0.text,
                updatedAt: $0.updatedAt
            )
        }

        payload.memorizedVerses = try context.fetch(FetchDescriptor<MemorizedVerse>()).map {
            TransferMemorizedVerse(
                verseId: $0.verseId,
                status: $0.status,
                lastReviewedDate: $0.lastReviewedDate,
                customReference: $0.customReference,
                customText: $0.customText,
                customTranslation: $0.customTranslation
            )
        }

        return payload
    }

    // MARK: - Import

    func importFullData(_ payload: FullSyncPayload) throws {
        // Warning: This performs a destructive overwrite / upsert. 
        // We delete all local records and insert the incoming ones to ensure a perfect mirror.
        
        try clearAllLocalData()

        for t in payload.streakRecords {
            let record = StreakRecord(
                pornographyStreakDays: t.pornographyStreakDays,
                masturbationStreakDays: t.masturbationStreakDays,
                pureThoughtsStreakDays: t.pureThoughtsStreakDays,
                pureThoughtsEnabled: t.pureThoughtsEnabled,
                pornographyLastResetDate: t.pornographyLastResetDate,
                masturbationLastResetDate: t.masturbationLastResetDate,
                pureThoughtsLastResetDate: t.pureThoughtsLastResetDate,
                pornographyLastCheckDate: t.pornographyLastCheckDate,
                masturbationLastCheckDate: t.masturbationLastCheckDate,
                pureThoughtsLastCheckDate: t.pureThoughtsLastCheckDate,
                createdAt: t.createdAt,
                updatedAt: t.updatedAt
            )
            context.insert(record)
        }

        for t in payload.resetRecords {
            let record = ResetRecord(type: ResetType(rawValue: t.type) ?? .pornography, date: t.date, optionalNote: t.optionalNote, triggerTag: t.triggerTag)
            record.type = t.type 
            context.insert(record)
        }

        for t in payload.urgeLogs {
            let record = UrgeLog(
                date: t.date,
                outcome: t.outcome,
                optionalNote: t.optionalNote,
                durationMinutes: t.durationMinutes,
                quickActionUsed: t.quickActionUsed,
                replaceActivityUsed: t.replaceActivityUsed
            )
            context.insert(record)
        }

        for t in payload.examenEntries {
            let record = ExamenEntry(
                date: t.date,
                step1Thanks: t.step1Thanks,
                step2Light: t.step2Light,
                step3Examine: t.step3Examine,
                step4Forgiveness: t.step4Forgiveness,
                step5Resolve: t.step5Resolve,
                howWasToday: t.howWasToday
            )
            context.insert(record)
        }

        for t in payload.ifThenPlans {
            let record = IfThenPlan(
                trigger: t.trigger,
                action: t.action,
                reminderEnabled: t.reminderEnabled,
                createdAt: t.createdAt,
                order: t.order
            )
            context.insert(record)
        }

        for t in payload.journalEntries {
            let record = JournalEntry(
                date: t.date,
                type: JournalEntryType(rawValue: t.type) ?? .urgeLog,
                optionalText: t.optionalText,
                tags: t.tags,
                moodOutcome: t.moodOutcome,
                durationCompleted: t.durationCompleted,
                outcome: t.outcome
            )
            record.type = t.type
            context.insert(record)
        }

        for t in payload.userMissions {
            let record = UserMission(
                text: t.text,
                updatedAt: t.updatedAt
            )
            context.insert(record)
        }

        for t in payload.memorizedVerses {
            let record = MemorizedVerse(
                verseId: t.verseId,
                status: t.status,
                lastReviewedDate: t.lastReviewedDate,
                customReference: t.customReference,
                customText: t.customText,
                customTranslation: t.customTranslation
            )
            context.insert(record)
        }

        try context.save()
    }

    private func clearAllLocalData() throws {
        try context.delete(model: StreakRecord.self)
        try context.delete(model: ResetRecord.self)
        try context.delete(model: UrgeLog.self)
        try context.delete(model: ExamenEntry.self)
        try context.delete(model: IfThenPlan.self)
        try context.delete(model: JournalEntry.self)
        try context.delete(model: UserMission.self)
        try context.delete(model: MemorizedVerse.self)
        try context.save()
    }
}
