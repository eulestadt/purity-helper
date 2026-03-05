//
//  ExamenHistoryView.swift
//  PurityHelp
//
//  List of past Daily Examen entries; tap for read-only detail.
//

import SwiftUI
import SwiftData

struct ExamenHistoryView: View {
    @Query(sort: \ExamenEntry.date, order: .reverse) private var entries: [ExamenEntry]
    @State private var selectedEntry: ExamenEntry?

    var body: some View {
        ZStack {
            PurityBackground()
            ScrollView {
                VStack(spacing: 16) {
                    ForEach(entries) { entry in
                        Button {
                            selectedEntry = entry
                        } label: {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(entry.date.formatted(date: .abbreviated, time: .omitted))
                                    .font(.headline)
                                    .foregroundStyle(.primary)

                                if let how = entry.howWasToday, !how.isEmpty {
                                    Text(how)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                } else if let first = entry.step1Thanks, !first.isEmpty {
                                    Text(first)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                        .lineLimit(1)
                                }
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding()
                            .glassCard(cornerRadius: 16)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding()
            }
        }
        .navigationTitle("Past examens")
        .sheet(item: $selectedEntry) { entry in
            ExamenEntryDetailView(entry: entry)
        }
    }
}

struct ExamenEntryDetailView: View {
    let entry: ExamenEntry
    @Environment(\.dismiss) private var dismiss

    private let stepLabels = ["Give thanks", "Ask for light", "Examine the day", "Seek forgiveness", "Resolve to change"]

    var body: some View {
        ZStack {
            PurityBackground()
            
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        Text(entry.date.formatted(date: .long, time: .shortened))
                            .font(.headline.weight(.bold))
                            .foregroundStyle(.primary)
                        Spacer()
                        Button("Done") { dismiss() }
                            .buttonStyle(.bordered)
                            .buttonBorderShape(.capsule)
                    }

                    if let how = entry.howWasToday, !how.isEmpty {
                        Text("How was today?")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(.primary)
                            
                        Text(how)
                            .font(.body)
                            .foregroundStyle(.primary)
                    }

                    ForEach(Array(stepLabels.enumerated()), id: \.offset) { index, label in
                        let text = stepText(for: index)
                        if let t = text, !t.isEmpty {
                            VStack(alignment: .leading, spacing: 6) {
                                Text(label)
                                    .font(.caption.weight(.bold))
                                    .foregroundStyle(.primary)
                                    
                                Text(t)
                                    .font(.body)
                                    .foregroundStyle(.primary)
                            }
                            .padding(.top, 4)
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
                .glassCard(cornerRadius: 16)
                .padding()
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }

    private func stepText(for index: Int) -> String? {
        switch index {
        case 0: return entry.step1Thanks
        case 1: return entry.step2Light
        case 2: return entry.step3Examine
        case 3: return entry.step4Forgiveness
        case 4: return entry.step5Resolve
        default: return nil
        }
    }
}

#Preview {
    NavigationStack {
        ExamenHistoryView()
            .modelContainer(for: ExamenEntry.self, inMemory: true)
    }
}
