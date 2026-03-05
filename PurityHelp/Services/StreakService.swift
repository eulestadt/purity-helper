//
//  StreakService.swift
//  PurityHelp
//
//  Manages streak state: daily check, reset, and effective streak for tree.
//

import Foundation
import SwiftData

@Observable
final class StreakService {
    private let calendar = Calendar.current

    func todayStart() -> Date {
        calendar.startOfDay(for: Date())
    }

    func isSameDay(_ a: Date, _ b: Date) -> Bool {
        calendar.isDate(a, inSameDayAs: b)
    }

    func fetchOrCreateStreakRecord(modelContext: ModelContext) throws -> StreakRecord {
        let descriptor = FetchDescriptor<StreakRecord>()
        let records = try modelContext.fetch(descriptor)
        if let existing = records.first {
            return existing
        }
        let newRecord = StreakRecord()
        modelContext.insert(newRecord)
        return newRecord
    }

    func recordPornographyCheck(record: StreakRecord, didReset: Bool, modelContext: ModelContext) {
        let today = todayStart()
        if didReset {
            record.pornographyStreakDays = 0
            record.pornographyLastResetDate = today
            let reset = ResetRecord(type: .pornography, date: today)
            modelContext.insert(reset)
        } else {
            let lastCheck = record.pornographyLastCheckDate
            if lastCheck == nil || !isSameDay(lastCheck!, today) {
                if lastCheck == nil || !isSameDay(record.pornographyLastResetDate ?? .distantPast, today) {
                    record.pornographyStreakDays += 1
                }
            }
            record.pornographyLastCheckDate = today
        }
        record.updatedAt = .now
    }

    func recordMasturbationCheck(record: StreakRecord, didReset: Bool, modelContext: ModelContext) {
        let today = todayStart()
        if didReset {
            record.masturbationStreakDays = 0
            record.masturbationLastResetDate = today
            let reset = ResetRecord(type: .masturbation, date: today)
            modelContext.insert(reset)
        } else {
            let lastCheck = record.masturbationLastCheckDate
            if lastCheck == nil || !isSameDay(lastCheck!, today) {
                if lastCheck == nil || !isSameDay(record.masturbationLastResetDate ?? .distantPast, today) {
                    record.masturbationStreakDays += 1
                }
            }
            record.masturbationLastCheckDate = today
        }
        record.updatedAt = .now
    }

    func recordPureThoughtsCheck(record: StreakRecord, guarded: Bool, modelContext: ModelContext) {
        guard record.pureThoughtsEnabled else { return }
        let today = todayStart()
        if !guarded {
            record.pureThoughtsStreakDays = 0
            record.pureThoughtsLastResetDate = today
            let reset = ResetRecord(type: .pureThoughts, date: today)
            modelContext.insert(reset)
        } else {
            let lastCheck = record.pureThoughtsLastCheckDate
            if lastCheck == nil || !isSameDay(lastCheck!, today) {
                if lastCheck == nil || !isSameDay(record.pureThoughtsLastResetDate ?? .distantPast, today) {
                    record.pureThoughtsStreakDays += 1
                }
            }
            record.pureThoughtsLastCheckDate = today
        }
        record.updatedAt = .now
    }

    func resetPornography(record: StreakRecord, modelContext: ModelContext, note: String? = nil, tag: String? = nil) {
        record.pornographyStreakDays = 0
        record.pornographyLastResetDate = todayStart()
        modelContext.insert(ResetRecord(type: .pornography, date: .now, optionalNote: note, triggerTag: tag))
        record.updatedAt = .now
    }

    func resetMasturbation(record: StreakRecord, modelContext: ModelContext, note: String? = nil, tag: String? = nil) {
        record.masturbationStreakDays = 0
        record.masturbationLastResetDate = todayStart()
        modelContext.insert(ResetRecord(type: .masturbation, date: .now, optionalNote: note, triggerTag: tag))
        record.updatedAt = .now
    }

    func resetPureThoughts(record: StreakRecord, modelContext: ModelContext, note: String? = nil, tag: String? = nil) {
        record.pureThoughtsStreakDays = 0
        record.pureThoughtsLastResetDate = todayStart()
        modelContext.insert(ResetRecord(type: .pureThoughts, date: .now, optionalNote: note, triggerTag: tag))
        record.updatedAt = .now
    }

    /// Tree stage from days of purity (effective behavioral streak).
    func treeStage(days: Int) -> PurityTreeStage {
        switch days {
        case 1...6: return .sprout
        case 7...13: return .seedling
        case 14...29: return .sapling
        case 30...89: return .youngTree
        case 90...: return .matureTree
        default: return .sprout
        }
    }
}

enum PurityTreeStage: String, CaseIterable {
    case seedling
    case sprout
    case sapling
    case youngTree
    case matureTree

    var label: String {
        switch self {
        case .seedling: return "Seedling"
        case .sprout: return "Sprout"
        case .sapling: return "Sapling"
        case .youngTree: return "Young tree"
        case .matureTree: return "Mature tree"
        }
    }

    var dayRange: String {
        switch self {
        case .seedling: return "7–13 days"
        case .sprout: return "1–6 days"
        case .sapling: return "14–29 days"
        case .youngTree: return "30–89 days"
        case .matureTree: return "90+ days"
        }
    }
}
