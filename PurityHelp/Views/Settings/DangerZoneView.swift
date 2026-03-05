//
//  DangerZoneView.swift
//  PurityHelp
//
//  Pattern insights from reset history: "You often struggle on [day/time]".
//

import SwiftUI
import SwiftData

struct DangerZoneView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \ResetRecord.date, order: .reverse) private var resets: [ResetRecord]

    private var patternSummary: String? {
        guard resets.count >= 2 else { return nil }
        let calendar = Calendar.current
        var weekdayCount: [Int: Int] = [:]
        var hourCount: [Int: Int] = [:]
        for r in resets.prefix(50) {
            let day = calendar.component(.weekday, from: r.date)
            let hour = calendar.component(.hour, from: r.date)
            weekdayCount[day, default: 0] += 1
            hourCount[hour, default: 0] += 1
        }
        let topDay = weekdayCount.max(by: { $0.value < $1.value }).map(\.key)
        let topHour = hourCount.max(by: { $0.value < $1.value }).map(\.key)
        let dayNames = ["", "Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"]
        if let d = topDay, let h = topHour {
            return "Resets often occur on \(dayNames[d]) and around \(h):00."
        }
        return nil
    }

    var body: some View {
        List {
            Section {
                Text("Environmental tips: screen-free bedroom, device limits, accountability software (e.g. Covenant Eyes).")
                    .font(.subheadline)
            } header: {
                Text("Tips")
            }
            if let pattern = patternSummary {
                Section {
                    Text(pattern)
                        .font(.subheadline)
                } header: {
                    Text("Your pattern")
                }
            }
            Section {
                ForEach(resets.prefix(20), id: \.date) { r in
                    HStack {
                        Text(r.resetType?.rawValue ?? r.type)
                        Spacer()
                        Text(r.date.formatted(date: .abbreviated, time: .shortened))
                            
                    }
                }
            } header: {
                Text("Recent resets")
            }
        }
        .navigationTitle("Danger zone")
    }
}

#Preview {
    NavigationStack {
        DangerZoneView()
            .modelContainer(for: ResetRecord.self, inMemory: true)
    }
}
