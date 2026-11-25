//
//  ExamenView.swift
//

import SwiftUI

struct ExamenView: View {
    @Environment(AppStore.self) private var store
    @State private var step = 0
    @State private var thanks = ""
    @State private var light = ""
    @State private var examine = ""
    @State private var forgiveness = ""
    @State private var resolve = ""
    @State private var how = ""
    @State private var saved = false

    private let prompts = [
        "Give thanks for one concrete thing.",
        "Ask for light. Where was God in this day?",
        "Walk the day. Where did you turn away?",
        "Ask forgiveness, and let it be given.",
        "Choose one resolution for tomorrow."
    ]

    var body: some View {
        NavigationStack {
            ZStack {
                PurityBackground()
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Five quiet steps. This closes the prayer ring.")
                            .foregroundStyle(PurityColor.muted)
                        if store.derived.practice.examen || saved {
                            GlassPanel {
                                Text("An examen is already recorded for today. You can write another if the day changed.")
                            }
                        }
                        GlassPanel {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Step \(step + 1) of 5")
                                    .font(.caption)
                                    .foregroundStyle(PurityColor.green)
                                Text(prompts[step])
                                    .font(.system(.title3, design: .serif))
                                TextField("Write a little, or a lot", text: binding, axis: .vertical)
                                    .lineLimit(4...8)
                                    .textFieldStyle(.roundedBorder)
                                HStack {
                                    if step > 0 {
                                        Button("Back") { step -= 1 }
                                    }
                                    Spacer()
                                    if step < 4 {
                                        Button("Next") { step += 1 }
                                            .buttonStyle(.borderedProminent)
                                            .tint(PurityColor.green)
                                    } else {
                                        Button("Save the examen") { save() }
                                            .buttonStyle(.borderedProminent)
                                            .tint(PurityColor.green)
                                    }
                                }
                            }
                        }
                        GlassPanel {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("How was today, in a sentence?")
                                    .font(.headline)
                                TextField("Optional", text: $how, axis: .vertical)
                                    .textFieldStyle(.roundedBorder)
                            }
                        }
                    }
                    .padding(20)
                }
            }
            .navigationTitle("Examen")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private var binding: Binding<String> {
        switch step {
        case 0: return $thanks
        case 1: return $light
        case 2: return $examine
        case 3: return $forgiveness
        default: return $resolve
        }
    }

    private func save() {
        store.logEvent([
            "kind": "examen",
            "thanks": thanks,
            "light": light,
            "examine": examine,
            "forgiveness": forgiveness,
            "resolve": resolve,
            "how": how
        ])
        saved = true
        step = 0
    }
}
