with open("PurityHelp/Services/FullSyncEngine.swift", "r") as f:
    text = f.read()

import_code = """
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
        let resetMap = Dictionary(uniqueKeysWithValues: localResets.map { ($0.id, $0) })
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
        let urgeMap = Dictionary(uniqueKeysWithValues: localUrges.map { ($0.id, $0) })
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
        let examenMap = Dictionary(uniqueKeysWithValues: localExamens.map { ($0.id, $0) })
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
        let planMap = Dictionary(uniqueKeysWithValues: localPlans.map { ($0.id, $0) })
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
        let journalMap = Dictionary(uniqueKeysWithValues: localJournals.map { ($0.id, $0) })
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
        let verseMap = Dictionary(uniqueKeysWithValues: localVerses.map { ($0.verseId, $0) })
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
"""

import sys
start_idx = text.find('    func importFullData(_ payload: FullSyncPayload)')
end_idx = text.find('    private func clearAllLocalData() throws {')
if start_idx == -1 or end_idx == -1:
    print("Could not find start/end bound")
    sys.exit(1)

new_text = text[:start_idx] + import_code + text[end_idx:]
with open("PurityHelp/Services/FullSyncEngine.swift", "w") as f:
    f.write(new_text)

print("Merged import code.")
