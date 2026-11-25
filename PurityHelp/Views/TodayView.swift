//
//  TodayView.swift
//

import SwiftUI

struct TodayView: View {
    @Environment(AppStore.self) private var store
    @Binding var showUrge: Bool

    var body: some View {
        let day = store.derived
        NavigationStack {
            ZStack {
                PurityBackground()
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        Text(day.today)
                            .font(.caption)
                            .tracking(1.4)
                            .textCase(.uppercase)
                            .foregroundStyle(PurityColor.green)
                        Text(day.treeName)
                            .font(.system(size: 40, weight: .regular, design: .serif))
                            .foregroundStyle(PurityColor.ink)
                        Text("\(day.streaks.clear) clear days")
                            .font(.title3)
                            .foregroundStyle(PurityColor.muted)
                        Text(day.streaks.clear < 90
                             ? "A different path is worn by repetition. The early months do the most."
                             : "The path is worn. Keep walking it.")
                            .font(.footnote)
                            .foregroundStyle(PurityColor.muted)
                        Text(day.mission.isEmpty ? "Name why this day matters in Settings." : day.mission)
                            .font(.body)
                            .foregroundStyle(PurityColor.ink)
                            .fixedSize(horizontal: false, vertical: true)
                        GlassPanel {
                            VStack(alignment: .leading, spacing: 12) {
                                Text(day.fullDay ? "The day is full." : "The day is still open.")
                                    .font(.headline)
                                RingCluster(rings: day.rings)
                                if let next = day.nextMilestone {
                                    Text("Next mark: \(next) clear days")
                                        .font(.footnote)
                                        .foregroundStyle(PurityColor.muted)
                                }
                            }
                        }
                        GlassPanel {
                            VStack(alignment: .leading, spacing: 12) {
                                practice("Morning offering", done: day.practice.intention) {
                                    store.logEvent(["kind": "prayer", "form": "intention"])
                                }
                                practice("Scripture", done: day.practice.scripture) {
                                    store.logEvent(["kind": "scripture", "reference": "today"])
                                }
                                practice("Watch", done: day.practice.surfed || day.practice.vigil) {
                                    store.logEvent(["kind": "prayer", "form": "watch"])
                                }
                                HStack {
                                    Image(systemName: day.practice.examen ? "checkmark.circle.fill" : "circle")
                                        .foregroundStyle(day.practice.examen ? PurityColor.green : PurityColor.muted)
                                    Text("Evening examen")
                                    Spacer()
                                    Text("Examen tab")
                                        .font(.caption)
                                        .foregroundStyle(PurityColor.muted)
                                }
                                .foregroundStyle(PurityColor.ink)
                            }
                        }
                        Button {
                            showUrge = true
                        } label: {
                            Text("I am in an urge")
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 6)
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(PurityColor.green)
                        Text(store.status)
                            .font(.footnote)
                            .foregroundStyle(PurityColor.muted)
                    }
                    .padding(20)
                }
            }
            .navigationTitle("Today")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private func practice(_ title: String, done: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack {
                Image(systemName: done ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(done ? PurityColor.green : PurityColor.muted)
                Text(title)
                    .foregroundStyle(PurityColor.ink)
                Spacer()
                if !done {
                    Text("Mark")
                        .font(.caption)
                        .foregroundStyle(PurityColor.green)
                }
            }
        }
        .buttonStyle(.plain)
        .disabled(done)
    }
}
