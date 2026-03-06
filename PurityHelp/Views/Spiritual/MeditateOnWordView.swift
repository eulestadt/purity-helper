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
    @State private var memorizeShowText = true

    private let steps: [(title: String, prompt: String)] = [
        ("Read", "Read the verse slowly. Let it sink in."),
        ("Reflect", "What is God saying to you in this passage?"),
        ("Pray", "Talk to God about it—thanks, need, or surrender."),
        ("Rest", "Rest in his presence. No words needed.")
    ]
    

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
            Text("Repeat the verse slowly 2–3 times; then try saying it without looking.")
                .font(.subheadline)
                

            if memorizeShowText {
                Text(verse.text)
                    .font(.system(size: 18, weight: .medium, design: .serif))
                    .multilineTextAlignment(.leading)
                Text(verse.reference)
                    .font(.caption)
                    
                Button("Tap when you want to try without looking") {
                    memorizeShowText = false
                    saveMemorizationProgress(status: "learning")
                }
                .buttonStyle(.bordered)
            } else {
                Text(verse.reference)
                    .font(.headline)
                Text("Say the verse from memory.")
                    .font(.subheadline)
                    
                Button("Show verse again") {
                    memorizeShowText = true
                }
                .buttonStyle(.bordered)
            }

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
