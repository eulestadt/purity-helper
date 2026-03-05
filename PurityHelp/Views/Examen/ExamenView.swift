//
//  ExamenView.swift
//  PurityHelp
//
//  5-step Jesuit Examen: Give thanks, Ask for light, Examine the day, Seek forgiveness, Resolve to change.
//

import SwiftUI
import SwiftData

struct ExamenView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var step: Int = 0
    @State private var step1Thanks: String = ""
    @State private var step2Light: String = ""
    @State private var step3Examine: String = ""
    @State private var step4Forgiveness: String = ""
    @State private var step5Resolve: String = ""
    @State private var howWasToday: String = "peaceful"
    @State private var saved: Bool = false

    private let steps = [
        ("Give thanks", "What are you grateful for today?"),
        ("Ask for light", "Ask the Holy Spirit to help you see the day clearly."),
        ("Examine the day", "Consolation and desolation—where did you feel close to God? Where did you struggle?"),
        ("Seek forgiveness", "Where do you need to ask forgiveness or forgive yourself?"),
        ("Resolve to change", "What will you do differently tomorrow?")
    ]

    var body: some View {
        NavigationStack {
            ZStack {
                PurityBackground()
                if saved {
                    completionView
                } else {
                    stepContent
                }
            }
        }
    }

    private var stepContent: some View {
        VStack(alignment: .leading, spacing: 20) {
            ProgressView(value: Double(step + 1), total: 5)
                .padding()

            let (title, prompt) = steps[step]
            Text(title)
                .font(.title2)
                .fontWeight(.semibold)
            Text(prompt)
                .font(.body)
                

            textFieldForStep(step)

            if step == 2 {
                Picker("How was today?", selection: $howWasToday) {
                    Text("Struggled").tag("struggled")
                    Text("Held firm").tag("held_firm")
                    Text("Peaceful").tag("peaceful")
                }
                .pickerStyle(.segmented)
            }

            Spacer()

            HStack {
                if step > 0 {
                    Button("Back") {
                        step -= 1
                    }
                    .buttonStyle(.bordered)
                }
                Spacer()
                if step < 4 {
                    Button("Next") {
                        step += 1
                    }
                    .buttonStyle(.borderedProminent)
                } else {
                    Button("Finish Examen") {
                        saveExamen()
                        saved = true
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
            .padding(.top)
        }
        .padding()
        .glassCard(cornerRadius: 18)
        .padding()
        .navigationTitle("Daily Examen")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                NavigationLink("Past examens", destination: ExamenHistoryView())
            }
        }
    }

    @ViewBuilder
    private func textFieldForStep(_ s: Int) -> some View {
        let binding: Binding<String> = switch s {
        case 0: $step1Thanks
        case 1: $step2Light
        case 2: $step3Examine
        case 3: $step4Forgiveness
        case 4: $step5Resolve
        default: $step1Thanks
        }
        TextField("Write here...", text: binding, axis: .vertical)
            .lineLimit(4...8)
            .textFieldStyle(.roundedBorder)
    }

    private var completionView: some View {
        VStack(spacing: 16) {
            Image(systemName: "checkmark.circle.fill")
                .font(.largeTitle)
                .foregroundStyle(.green)
            Text("Examen saved")
                .font(.headline)
            Button("Start another") {
                saved = false
                step = 0
                step1Thanks = ""
                step2Light = ""
                step3Examine = ""
                step4Forgiveness = ""
                step5Resolve = ""
            }
            .buttonStyle(.bordered)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
        .navigationTitle("Daily Examen")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                NavigationLink("Past examens", destination: ExamenHistoryView())
            }
        }
    }

    private func saveExamen() {
        let entry = ExamenEntry(
            step1Thanks: step1Thanks.isEmpty ? nil : step1Thanks,
            step2Light: step2Light.isEmpty ? nil : step2Light,
            step3Examine: step3Examine.isEmpty ? nil : step3Examine,
            step4Forgiveness: step4Forgiveness.isEmpty ? nil : step4Forgiveness,
            step5Resolve: step5Resolve.isEmpty ? nil : step5Resolve,
            howWasToday: howWasToday
        )
        modelContext.insert(entry)
        let journal = JournalEntry(type: .examen, moodOutcome: howWasToday)
        modelContext.insert(journal)
        try? modelContext.save()
        Task { @MainActor in AutoSyncManager.shared.performBackgroundSync(modelContext: modelContext) }
    }
}

#Preview {
    ExamenView()
        .modelContainer(for: [ExamenEntry.self, JournalEntry.self], inMemory: true)
}
