//
//  UrgeInsightsView.swift
//  PurityHelp
//
//  Display patterns and statistics from UrgeLog data.
//

import SwiftUI
import SwiftData

struct UrgeInsightsView: View {
    @Query(sort: \UrgeLog.date, order: .reverse) private var logs: [UrgeLog]
    
    private var peakStruggleTime: String {
        guard !logs.isEmpty else { return "No data yet" }
        var counts: [Int: Int] = [:]
        for log in logs {
            let hour = Calendar.current.component(.hour, from: log.date)
            counts[hour, default: 0] += 1
        }
        if let topHour = counts.max(by: { $0.value < $1.value })?.key {
            let nextHour = (topHour + 1) % 24
            return "\(formatHour(topHour)) - \(formatHour(nextHour))"
        }
        return "Not enough data"
    }
    
    private var topAction: String {
        var actions: [String: Int] = [:]
        for log in logs {
            if let a = log.quickActionUsed { actions[a, default: 0] += 1 }
            if let r = log.replaceActivityUsed { actions[r, default: 0] += 1 }
        }
        if let top = actions.max(by: { $0.value < $1.value }) {
            return top.key
        }
        return "None yet"
    }
    
    private func formatHour(_ hour: Int) -> String {
        let h = hour % 12 == 0 ? 12 : hour % 12
        let ampm = hour < 12 ? "AM" : "PM"
        return "\(h) \(ampm)"
    }
    
    var body: some View {
        ZStack {
            PurityBackground()
            List {
                Section {
                    HStack {
                        Text("Peak Struggle Time")
                        Spacer()
                        Text(peakStruggleTime)
                            .foregroundStyle(.secondary)
                    }
                    HStack {
                        Text("Most Used Tool")
                        Spacer()
                        Text(topAction)
                            .foregroundStyle(.secondary)
                    }
                    HStack {
                        Text("Total Victories")
                        Spacer()
                        Text("\(logs.count)")
                            .foregroundStyle(.secondary)
                    }
                } header: {
                    Text("Your Patterns")
                } footer: {
                    Text("Identifying these patterns helps you be more watchful and prepared during high-risk moments.")
                }
                
                Section {
                    if logs.isEmpty {
                        Text("No logs yet. Use the 'Urge' button when struggling to build your insights.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(logs.prefix(20)) { log in
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(log.date.formatted(date: .abbreviated, time: .shortened))
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                    let action = log.quickActionUsed ?? log.replaceActivityUsed ?? "Held Firm"
                                    Text(action)
                                        .font(.subheadline.bold())
                                }
                                Spacer()
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(.green)
                            }
                            .padding(.vertical, 4)
                        }
                    }
                } header: {
                    Text("Recent Victories")
                }
            }
            .scrollContentBackground(.hidden)
            .navigationTitle("Urge Insights")
        }
    }
}

#Preview {
    NavigationStack {
        UrgeInsightsView()
            .modelContainer(for: UrgeLog.self, inMemory: true)
    }
}
