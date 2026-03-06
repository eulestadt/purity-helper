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
                id: $0.id,
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
                id: $0.id,
                updatedAt: $0.updatedAt,
                type: $0.type,
                date: $0.date,
                optionalNote: $0.optionalNote,
                triggerTag: $0.triggerTag
            )
        }

        payload.urgeLogs = try context.fetch(FetchDescriptor<UrgeLog>()).map {
            TransferUrgeLog(
                id: $0.id,
                updatedAt: $0.updatedAt,
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
                id: $0.id,
                updatedAt: $0.updatedAt,
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
                id: $0.id,
                updatedAt: $0.updatedAt,
                trigger: $0.trigger,
                action: $0.action,
                reminderEnabled: $0.reminderEnabled,
                createdAt: $0.createdAt,
                order: $0.order
            )
        }

        payload.journalEntries = try context.fetch(FetchDescriptor<JournalEntry>()).map {
            TransferJournalEntry(
                id: $0.id,
                updatedAt: $0.updatedAt,
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
                id: $0.id,
                text: $0.text,
                updatedAt: $0.updatedAt
            )
        }

        payload.memorizedVerses = try context.fetch(FetchDescriptor<MemorizedVerse>()).map {
            TransferMemorizedVerse(
                verseId: $0.verseId,
                updatedAt: $0.updatedAt,
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
        // Delta Merge Protocol:
        // Compare incoming Cloud records with Local records via ID. 
        // Overwrite local ONLY if Cloud.updatedAt > Local.updatedAt.
        // Insert if missing locally. Retain local if missing in Cloud.

        // 1. StreakRecords (Single Singleton, merge by newest updatedAt)
        let localStreaks = try context.fetch(FetchDescriptor<StreakRecord>())
        if let cloudStreak = payload.streakRecords.first {
            if let localStreak = localStreaks.first {
                if cloudStreak.updatedAt > localStreak.updatedAt {
                    localStreak.pornographyStreakDays = cloudStreak.pornographyStreakDays
                    localStreak.masturbationStreakDays = cloudStreak.masturbationStreakDays
                    localStreak.pureThoughtsStreakDays = cloudStreak.pureThoughtsStreakDays
                    localStreak.pureThoughtsEnabled = cloudStreak.pureThoughtsEnabled
                    localStreak.pornographyLastResetDate = cloudStreak.pornographyLastResetDate
                    localStreak.masturbationLastResetDate = cloudStreak.masturbationLastResetDate
                    localStreak.pureThoughtsLastResetDate = cloudStreak.pureThoughtsLastResetDate
                    localStreak.pornographyLastCheckDate = cloudStreak.pornographyLastCheckDate
                    localStreak.masturbationLastCheckDate = cloudStreak.masturbationLastCheckDate
                    localStreak.pureThoughtsLastCheckDate = cloudStreak.pureThoughtsLastCheckDate
                    localStreak.updatedAt = cloudStreak.updatedAt
                }
            } else {
                let req = StreakRecord(pornographyStreakDays: cloudStreak.pornographyStreakDays, masturbationStreakDays: cloudStreak.masturbationStreakDays, pureThoughtsStreakDays: cloudStreak.pureThoughtsStreakDays, pureThoughtsEnabled: cloudStreak.pureThoughtsEnabled, pornographyLastResetDate: cloudStreak.pornographyLastResetDate, masturbationLastResetDate: cloudStreak.masturbationLastResetDate, pureThoughtsLastResetDate: cloudStreak.pureThoughtsLastResetDate, pornographyLastCheckDate: cloudStreak.pornographyLastCheckDate, masturbationLastCheckDate: cloudStreak.masturbationLastCheckDate, pureThoughtsLastCheckDate: cloudStreak.pureThoughtsLastCheckDate, createdAt: cloudStreak.createdAt, updatedAt: cloudStreak.updatedAt)
                context.insert(req)
            }
        }

        // 2. ResetRecords
        let localResets = try context.fetch(FetchDescriptor<ResetRecord>())
        let resetMap = Dictionary(localResets.map { ($0.id, $0) }, uniquingKeysWith: { first, _ in first })
        for c in payload.resetRecords {
            if let l = resetMap[c.id] {
                if c.updatedAt > l.updatedAt {
                    l.type = c.type
                    l.date = c.date
                    l.optionalNote = c.optionalNote
                    l.triggerTag = c.triggerTag
                    l.updatedAt = c.updatedAt
                }
            } else {
                let r = ResetRecord(id: c.id, updatedAt: c.updatedAt, type: ResetType(rawValue: c.type) ?? .pornography, date: c.date, optionalNote: c.optionalNote, triggerTag: c.triggerTag)
                context.insert(r)
            }
        }

        // 3. UrgeLogs
        let localUrges = try context.fetch(FetchDescriptor<UrgeLog>())
        let urgeMap = Dictionary(localUrges.map { ($0.id, $0) }, uniquingKeysWith: { first, _ in first })
        for c in payload.urgeLogs {
            if let l = urgeMap[c.id] {
                if c.updatedAt > l.updatedAt {
                    l.date = c.date
                    l.outcome = c.outcome
                    l.optionalNote = c.optionalNote
                    l.durationMinutes = c.durationMinutes
                    l.quickActionUsed = c.quickActionUsed
                    l.replaceActivityUsed = c.replaceActivityUsed
                    l.updatedAt = c.updatedAt
                }
            } else {
                let r = UrgeLog(id: c.id, updatedAt: c.updatedAt, date: c.date, outcome: c.outcome, optionalNote: c.optionalNote, durationMinutes: c.durationMinutes, quickActionUsed: c.quickActionUsed, replaceActivityUsed: c.replaceActivityUsed)
                context.insert(r)
            }
        }

        // 4. ExamenEntries
        let localExamens = try context.fetch(FetchDescriptor<ExamenEntry>())
        let examenMap = Dictionary(localExamens.map { ($0.id, $0) }, uniquingKeysWith: { first, _ in first })
        for c in payload.examenEntries {
            if let l = examenMap[c.id] {
                if c.updatedAt > l.updatedAt {
                    l.date = c.date
                    l.step1Thanks = c.step1Thanks ?? ""
                    l.step2Light = c.step2Light ?? ""
                    l.step3Examine = c.step3Examine ?? ""
                    l.step4Forgiveness = c.step4Forgiveness ?? ""
                    l.step5Resolve = c.step5Resolve ?? ""
                    l.howWasToday = c.howWasToday
                    l.updatedAt = c.updatedAt
                }
            } else {
                let r = ExamenEntry(id: c.id, updatedAt: c.updatedAt, date: c.date, step1Thanks: c.step1Thanks ?? "", step2Light: c.step2Light ?? "", step3Examine: c.step3Examine ?? "", step4Forgiveness: c.step4Forgiveness ?? "", step5Resolve: c.step5Resolve ?? "", howWasToday: c.howWasToday)
                context.insert(r)
            }
        }

        // 5. IfThenPlans
        let localPlans = try context.fetch(FetchDescriptor<IfThenPlan>())
        let planMap = Dictionary(localPlans.map { ($0.id, $0) }, uniquingKeysWith: { first, _ in first })
        for c in payload.ifThenPlans {
            if let l = planMap[c.id] {
                if c.updatedAt > l.updatedAt {
                    l.trigger = c.trigger
                    l.action = c.action
                    l.reminderEnabled = c.reminderEnabled
                    l.order = c.order
                    l.updatedAt = c.updatedAt
                }
            } else {
                let r = IfThenPlan(id: c.id, updatedAt: c.updatedAt, trigger: c.trigger, action: c.action, reminderEnabled: c.reminderEnabled, createdAt: c.createdAt, order: c.order)
                context.insert(r)
            }
        }

        // 6. JournalEntries
        let localJournals = try context.fetch(FetchDescriptor<JournalEntry>())
        let journalMap = Dictionary(localJournals.map { ($0.id, $0) }, uniquingKeysWith: { first, _ in first })
        for c in payload.journalEntries {
            if let l = journalMap[c.id] {
                if c.updatedAt > l.updatedAt {
                    l.date = c.date
                    l.type = c.type
                    l.optionalText = c.optionalText
                    l.tags = c.tags
                    l.moodOutcome = c.moodOutcome
                    l.durationCompleted = c.durationCompleted
                    l.outcome = c.outcome
                    l.updatedAt = c.updatedAt
                }
            } else {
                let r = JournalEntry(id: c.id, updatedAt: c.updatedAt, date: c.date, type: JournalEntryType(rawValue: c.type) ?? .urgeLog, optionalText: c.optionalText, tags: c.tags, moodOutcome: c.moodOutcome, durationCompleted: c.durationCompleted, outcome: c.outcome)
                r.type = c.type
                context.insert(r)
            }
        }

        // 7. UserMissions (Singleton behavior like Streaks)
        let localMissions = try context.fetch(FetchDescriptor<UserMission>())
        if let cloudMission = payload.userMissions.first {
            if let localMission = localMissions.first {
                if cloudMission.updatedAt > localMission.updatedAt {
                    localMission.text = cloudMission.text
                    localMission.updatedAt = cloudMission.updatedAt
                }
            } else {
                context.insert(UserMission(id: cloudMission.id, text: cloudMission.text, updatedAt: cloudMission.updatedAt))
            }
        }

        // 8. MemorizedVerses
        let localVerses = try context.fetch(FetchDescriptor<MemorizedVerse>())
        let verseMap = Dictionary(localVerses.map { ($0.verseId, $0) }, uniquingKeysWith: { first, _ in first })
        for c in payload.memorizedVerses {
            if let l = verseMap[c.verseId] {
                if c.updatedAt > l.updatedAt {
                    l.status = c.status
                    l.lastReviewedDate = c.lastReviewedDate
                    l.customReference = c.customReference
                    l.customText = c.customText
                    l.customTranslation = c.customTranslation
                    l.updatedAt = c.updatedAt
                }
            } else {
                let r = MemorizedVerse(verseId: c.verseId, updatedAt: c.updatedAt, status: c.status, lastReviewedDate: c.lastReviewedDate, customReference: c.customReference, customText: c.customText, customTranslation: c.customTranslation)
                context.insert(r)
            }
        }

        try context.save()
        
        // Push the newly merged hybrid dataset back up to the server.
        Task { @MainActor in AutoSyncManager.shared.performBackgroundSync(modelContext: self.context) }
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
