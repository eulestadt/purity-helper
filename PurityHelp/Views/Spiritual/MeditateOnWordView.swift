//
//  MeditateOnWordView.swift
//  PurityHelp
//
//  Read → Reflect → Pray → Rest; optional Memorize step (Hide in your heart).
//

import SwiftUI
import SwiftData

struct MeditateOnWordView: View {
    private let verse = ScriptureService.verseForToday()
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \MemorizedVerse.verseId) private var memorized: [MemorizedVerse]
    @State private var step = 0
    @State private var showMemorizeStep = false

    private let steps: [(title: String, prompt: String)] = [
        ("Read", "Read the verse slowly. Let it sink in."),
        ("Reflect", "What is God saying to you in this passage?"),
        ("Pray", "Talk to God about it—thanks, need, or surrender."),
        ("Rest", "Rest in his presence. No words needed.")
    ]
    
    enum TextDisplayMode: String, CaseIterable, Identifiable {
        case full = "Full"
        case firstLetters = "Letters"
        case hidden = "Hidden"
        var id: String { rawValue }
    }
    
    @State private var displayMode: TextDisplayMode = .full

    private var firstLettersText: String {
        verse.text.split(separator: " ").map { word in
            guard let firstChar = word.first(where: { $0.isLetter || $0.isNumber }) else { return String(word) }
            return String(firstChar) + String(repeating: "_", count: max(0, word.count - 1))
        }.joined(separator: " ")
    }

    var body: some View {
        ZStack {
            PurityBackground()
            ScrollView(showsIndicators: false) {
                VStack(spacing: 24) {
                    if step < steps.count {
                        stepCard
                    } else if step == steps.count && showMemorizeStep {
                        memorizeStepContent
                    } else {
                        completionCard
                    }
                }
                .frame(maxWidth: .infinity)
                .padding()
                .padding(.bottom, 32)
            }
        }
        .navigationTitle("Meditate on the Word")
        .onAppear {
            showMemorizeStep = true
        }
    }

    @ViewBuilder
    private var stepCard: some View {
        let (title, prompt) = steps[step]
        VStack(alignment: .leading, spacing: 16) {
            Text(title)
                .font(.title2)
                .fontWeight(.semibold)
            Text(prompt)
                .font(.body)
                

            if step == 0 {
                NavigationLink(destination: HideInYourHeartView()) {
                    Label("Hide in your heart", systemImage: "heart.text.square.fill")
                        .font(.subheadline.weight(.medium))
                }
                .padding(.vertical, 4)

                Text(verse.text)
                    .font(.system(size: 20, weight: .medium, design: .serif))
                    .multilineTextAlignment(.leading)
                Text(verse.reference)
                    .font(.caption)
                    
            }

            HStack {
                if step > 0 {
                    Button("Back") { step -= 1 }
                        .buttonStyle(.bordered)
                }
                Spacer()
                if step < steps.count - 1 {
                    Button("Next") { step += 1 }
                        .buttonStyle(.borderedProminent)
                } else {
                    Button("Next") { step += 1 }
                        .buttonStyle(.borderedProminent)
                    Button("Skip memorization") { step = steps.count + 1 }
                        .buttonStyle(.bordered)
                }
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassCard(cornerRadius: 20)
    }

    private var memorizeStepContent: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack(spacing: 8) {
                Image(systemName: "heart.text.square.fill")
                    .font(.title2)
                    
                Text("Hide in your heart")
                    .font(.title2)
                    .fontWeight(.semibold)
            }
            Text("Use these modes to help you memorize. First Letters mode helps train your brain to recall.")
                .font(.subheadline)
                
            Picker("Display Mode", selection: $displayMode) {
                ForEach(TextDisplayMode.allCases) { mode in
                    Text(mode.rawValue).tag(mode)
                }
            }
            .pickerStyle(.segmented)

            VStack(alignment: .leading, spacing: 10) {
                switch displayMode {
                case .full:
                    Text(verse.text)
                        .font(.system(size: 18, weight: .medium, design: .serif))
                case .firstLetters:
                    Text(firstLettersText)
                        .font(.system(size: 18, weight: .medium, design: .serif))
                case .hidden:
                    Text("Say the verse from memory.")
                        .font(.subheadline)
                        .italic()
                        .foregroundStyle(.secondary)
                }
                
                Text(verse.reference)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.white.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: 12))

            HStack(spacing: 12) {
                Button("Back") { step = steps.count - 1 }
                    .buttonStyle(.bordered)
                Button("Done") {
                    saveMemorizationProgress(status: "learned")
                    step = steps.count + 1
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassCard(cornerRadius: 20)
    }

    private func saveMemorizationProgress(status: String) {
        if let p = memorized.first(where: { $0.verseId == verse.id }) {
            p.status = status
            p.lastReviewedDate = Date()
            p.updatedAt = Date.now
        } else {
            let m = MemorizedVerse(verseId: verse.id, status: status, lastReviewedDate: Date())
            modelContext.insert(m)
        }
        try? modelContext.save()
        Task { @MainActor in AutoSyncManager.shared.performBackgroundSync(modelContext: modelContext) }
    }

    private var completionCard: some View {
        VStack(spacing: 24) {
            Text("Peace be with you.")
                .font(.title2)
                .fontWeight(.medium)
            NavigationLink(destination: HideInYourHeartView()) {
                HStack {
                    Image(systemName: "heart.text.square.fill")
                    Text("Hide in your heart")
                }
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding()
            }
            .buttonStyle(.borderedProminent)
        }
        .padding(24)
        .frame(maxWidth: .infinity)
        .glassCard(cornerRadius: 20)
    }
}

#Preview {
    NavigationStack {
        MeditateOnWordView()
    }
    .modelContainer(for: MemorizedVerse.self, inMemory: true)
}
