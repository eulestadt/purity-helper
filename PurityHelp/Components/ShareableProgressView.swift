//
//  ShareableProgressView.swift
//  PurityHelp
//
//  Read-only summary for accountability partner (includes hours reclaimed if opted in).
//

import SwiftUI
import SwiftData

struct ShareableProgressView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var streakRecords: [StreakRecord]
    @Query private var urgeLogs: [UrgeLog]

    private var streakRecord: StreakRecord? { streakRecords.first }
    private var summary: ShareableSummary? {
        guard let r = streakRecord else { return nil }
        let urgeCount = urgeLogs.count
        let minutesPerDay = UserDefaults.standard.object(forKey: "minutesPerDayReclaimed") as? Int ?? 0
        let hoursReclaimed = minutesPerDay > 0 ? (r.effectiveBehavioralStreak * minutesPerDay) / 60 : nil
        return ShareableSummary(
            pornographyDays: r.pornographyStreakDays,
            masturbationDays: r.masturbationStreakDays,
            pureThoughtsDays: r.pureThoughtsStreakDays,
            urgeMomentsCount: urgeCount,
            hoursReclaimed: hoursReclaimed
        )
    }

    private var exportText: String {
        guard let r = streakRecord else { return "No data yet." }
        let minutesPerDay = UserDefaults.standard.object(forKey: "minutesPerDayReclaimed") as? Int ?? 0
        let hours = minutesPerDay > 0 ? (r.effectiveBehavioralStreak * minutesPerDay) / 60 : nil
        return ShareableProgressService.generateSummary(
            streakRecord: r,
            urgeLogs: urgeLogs,
            hoursReclaimed: hours
        )
    }

    var body: some View {
        if let s = summary {
            List {
                Section("Days of purity") {
                    LabeledContent("Pornography", value: "\(s.pornographyDays) days")
                    LabeledContent("Masturbation", value: "\(s.masturbationDays) days")
                    if s.pureThoughtsDays >= 0 {
                        LabeledContent("Guarding thoughts", value: "\(s.pureThoughtsDays) days")
                    }
                }
                Section("Urge moments") {
                    Text("\(s.urgeMomentsCount) logged")
                }
                if let hours = s.hoursReclaimed, hours > 0 {
                    Section("Hours reclaimed") {
                        Text("\(hours) hours")
                    }
                }
                Section {
                    ShareLink(item: exportText, subject: Text("Purity Help progress"), message: Text("Progress summary")) {
                        Label("Export summary", systemImage: "square.and.arrow.up")
                    }
                }
            }
            .navigationTitle("Progress summary")
        } else {
            ContentUnavailableView("No data yet", systemImage: "chart.bar")
        }
    }
}

struct ShareableSummary {
    let pornographyDays: Int
    let masturbationDays: Int
    let pureThoughtsDays: Int
    let urgeMomentsCount: Int
    let hoursReclaimed: Int?
}

#Preview {
    NavigationStack {
        ShareableProgressView()
            .modelContainer(for: [StreakRecord.self, UrgeLog.self], inMemory: true)
    }
}
