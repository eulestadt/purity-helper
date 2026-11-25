//
//  UrgeMomentView.swift
//

import SwiftUI

struct UrgeMomentView: View {
    @Environment(AppStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    @State private var step = 0
    @State private var trigger = "Habit"
    @State private var thirst: String?
    @State private var activity = "Walk"
    @State private var note = ""
    @State private var relapseType = "pornography"
    @State private var remaining = 10 * 60
    @State private var timing = false

    private let triggers = ["Habit", "Loneliness", "Stress", "Boredom", "Night", "Anger"]
    private let thirsts = ["Comfort", "Being wanted", "Control", "Escape", "Numbness"]
    private let activities = ["Walk", "Cold water", "Pray out loud", "Leave the room", "Text a friend"]
    private let verse = ScriptureLibrary.verseForToday(ScriptureLibrary.load())

    var body: some View {
        NavigationStack {
            ZStack {
                PurityBackground()
                ScrollView {
                    VStack(alignment: .leading, spacing: 18) {
                        Text("This urge is a wave. You are in the ritual, and it can still turn.")
                            .font(.system(.title3, design: .serif))
                            .foregroundStyle(PurityColor.ink)
                        if !store.derived.mission.isEmpty {
                            Text(store.derived.mission)
                                .foregroundStyle(PurityColor.muted)
                        }
                        stepBody
                    }
                    .padding(20)
                }
            }
            .navigationTitle("Urge")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
        }
    }

    @ViewBuilder
    private var stepBody: some View {
        switch step {
        case 0:
            GlassPanel {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Pause").font(.headline)
                    BreathingPacer()
                    Button("I can go on") { step = 1 }
                        .buttonStyle(.borderedProminent)
                        .tint(PurityColor.green)
                }
            }
        case 1:
            GlassPanel {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Name it, without feeding it.").font(.headline)
                    Text("What set it off")
                        .font(.caption)
                        .foregroundStyle(PurityColor.muted)
                    ForEach(triggers, id: \.self) { item in
                        Button(item) { trigger = item }
                            .buttonStyle(.bordered)
                            .tint(trigger == item ? PurityColor.green : PurityColor.muted)
                    }
                    Text("What you were actually thirsty for")
                        .font(.caption)
                        .foregroundStyle(PurityColor.muted)
                    ForEach(thirsts, id: \.self) { item in
                        Button(item) { thirst = item }
                            .buttonStyle(.bordered)
                            .tint(thirst == item ? PurityColor.green : PurityColor.muted)
                    }
                    Button("Wait ten minutes") { step = 2 }
                        .buttonStyle(.borderedProminent)
                        .tint(PurityColor.green)
                }
            }
        case 2:
            GlassPanel {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Delay").font(.headline)
                    Text(timeLabel).font(.system(size: 44, weight: .regular, design: .serif))
                    Button(timing ? "Counting" : "Start the wait") { startTimer() }
                        .buttonStyle(.bordered)
                        .disabled(timing)
                    Button("The wave passed") { finish(surfed: true) }
                        .buttonStyle(.borderedProminent)
                        .tint(PurityColor.green)
                    Button("I still need an answer") { step = 3 }
                        .buttonStyle(.bordered)
                }
            }
        case 3:
            GlassPanel {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Answer it").font(.headline)
                    if let verse {
                        Text(verse.reference).font(.caption).foregroundStyle(PurityColor.green)
                        Text(verse.text).font(.system(.body, design: .serif))
                    }
                    Text("Say the verse once, out loud if you can. Then do something with your body.")
                        .foregroundStyle(PurityColor.muted)
                    ForEach(activities, id: \.self) { item in
                        Button(item) { activity = item }
                            .buttonStyle(.bordered)
                            .tint(activity == item ? PurityColor.green : PurityColor.muted)
                    }
                    Button("I let it pass") { finish(surfed: true) }
                        .buttonStyle(.borderedProminent)
                        .tint(PurityColor.green)
                    Button("I acted") { step = 4 }
                        .buttonStyle(.bordered)
                        .tint(PurityColor.clay)
                }
            }
        default:
            GlassPanel {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Begin again").font(.headline)
                    Text("Record it so the pattern is honest. The streak starts again tomorrow. You are not the worst thing you did in this hour.")
                        .foregroundStyle(PurityColor.muted)
                    Picker("What happened", selection: $relapseType) {
                        Text("Pornography").tag("pornography")
                        Text("Masturbation").tag("masturbation")
                        Text("A thought I entertained").tag("thought")
                    }
                    .pickerStyle(.segmented)
                    TextField("A note, if it helps", text: $note, axis: .vertical)
                        .textFieldStyle(.roundedBorder)
                    Button("Record and close") {
                        store.logEvent(eventFields([
                            "kind": "relapse",
                            "type": relapseType,
                            "trigger": trigger,
                            "note": note
                        ]))
                        dismiss()
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(PurityColor.clay)
                }
            }
        }
    }

    private var timeLabel: String {
        String(format: "%d:%02d", remaining / 60, remaining % 60)
    }

    private func startTimer() {
        timing = true
        Task {
            while remaining > 0 && !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 1_000_000_000)
                remaining -= 1
            }
            timing = false
        }
    }

    private func eventFields(_ fields: [String: Any]) -> [String: Any] {
        var value = fields
        if let thirst { value["thirst"] = thirst }
        return value
    }

    private func finish(surfed: Bool) {
        store.logEvent(eventFields([
            "kind": "urge",
            "outcome": surfed ? "surfed" : "acted",
            "trigger": trigger,
            "activity": activity
        ]))
        store.logEvent(["kind": "prayer", "form": "vigil"])
        dismiss()
    }
}
