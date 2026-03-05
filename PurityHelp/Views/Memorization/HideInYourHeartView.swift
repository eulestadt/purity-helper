//
//  HideInYourHeartView.swift
//  PurityHelp
//
//  Curated verses to memorize: Learn and Review. "Hide in your heart" (Psalm 119:11).
//

import SwiftUI
import SwiftData

struct HideInYourHeartView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \MemorizedVerse.verseId) private var memorized: [MemorizedVerse]

    private let defaultVerses = ScriptureService.versesForMemorization()
    @State private var showAddVerse = false

    private var allVersesCombined: [ScriptureVerse] {
        // Start with custom verses from data layer
        let customVerses = memorized.compactMap { $0.toScriptureVerse() }
        
        // Append default verses if they aren't already representing a custom one
        let customIds = Set(customVerses.map { $0.id })
        let staticVerses = defaultVerses.filter { !customIds.contains($0.id) }
        
        return customVerses + staticVerses
    }

    var body: some View {
        List {
                Section {
                    NavigationLink(destination: MemorizeReviewView()) {
                        Label("Verse to review today", systemImage: "arrow.clockwise")
                    }
                }
                Section("Verses to memorize") {
                    ForEach(allVersesCombined) { verse in
                        let progress = memorized.first { $0.verseId == verse.id }
                        NavigationLink(destination: MemorizeLearnView(verse: verse, progress: progress)) {
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(verse.reference)
                                        .font(.headline)
                                    Text(verse.text)
                                        .font(.caption)
                                        
                                        .lineLimit(2)
                                }
                                Spacer()
                                if let p = progress, p.status != "none" {
                                    Text(p.status == "learned" ? "Learned" : "Learning")
                                        .font(.caption2)
                                        
                                }
                            }
                        }
                        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                            if let p = progress {
                                Button(role: .destructive) {
                                    removeVerse(p)
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                        }
                        .swipeActions(edge: .leading, allowsFullSwipe: true) {
                            if let p = progress, p.status != "none" {
                                Button {
                                    unlearnVerse(p)
                                } label: {
                                    Label("Unlearn", systemImage: "arrow.uturn.backward")
                                }
                                .tint(.orange)
                            }
                        }
                    }
            }
        }
        .navigationTitle("Hide in your heart")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    showAddVerse = true
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $showAddVerse) {
            AddVerseSearchSheet()
        }
    }
    
    private func removeVerse(_ verse: MemorizedVerse) {
        modelContext.delete(verse)
        try? modelContext.save()
    }
    
    private func unlearnVerse(_ verse: MemorizedVerse) {
        verse.status = "none"
        try? modelContext.save()
    }
}

struct MemorizeLearnView: View {
    let verse: ScriptureVerse
    let progress: MemorizedVerse?
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @State private var showText = true
    @State private var status: String

    init(verse: ScriptureVerse, progress: MemorizedVerse?) {
        self.verse = verse
        self.progress = progress
        _status = State(initialValue: progress?.status ?? "learning")
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("Repeat the verse slowly 2–3 times. Then try saying it without looking.")
                    .font(.subheadline)
                    

                if showText {
                    Text(verse.text)
                        .font(.title3)
                    if let translation = verse.translation {
                        Text("\(verse.reference) (\(translation))")
                            .font(.caption)
                            
                    } else {
                        Text(verse.reference)
                            .font(.caption)
                            
                    }
                    Button("Tap when you want to try without looking") {
                        showText = false
                    }
                    .buttonStyle(.bordered)
                } else {
                    if let translation = verse.translation {
                        Text("\(verse.reference) (\(translation))")
                            .font(.headline)
                    } else {
                        Text(verse.reference)
                            .font(.headline)
                    }
                    Text("Say the verse from memory.")
                        .font(.subheadline)
                        
                    Button("Show verse again") {
                        showText = true
                    }
                    .buttonStyle(.bordered)
                }

                Picker("Status", selection: $status) {
                    Text("Learning").tag("learning")
                    Text("Learned").tag("learned")
                }
                .pickerStyle(.segmented)
                .onChange(of: status) { _, newValue in
                    saveProgress(status: newValue)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
        }
        .navigationTitle(verse.reference)
        .onDisappear {
            saveProgress(status: status)
        }
    }

    private func saveProgress(status: String) {
        if let p = progress {
            p.status = status
            p.lastReviewedDate = Date()
        } else {
            let m = MemorizedVerse(verseId: verse.id, status: status, lastReviewedDate: Date())
            modelContext.insert(m)
        }
        try? modelContext.save()
    }
}

struct MemorizeReviewView: View {
    @Query(sort: \MemorizedVerse.lastReviewedDate) private var memorized: [MemorizedVerse]
    @Environment(\.modelContext) private var modelContext

    private let defaultVerses = ScriptureService.versesForMemorization()

    var body: some View {
        Group {
            let toReview = verseToReviewToday()
            if let v = toReview {
                MemorizeReviewDetailView(verse: v)
            } else {
                ContentUnavailableView(
                    "No verse to review",
                    systemImage: "checkmark.circle",
                    description: Text("Add verses in \"Hide in your heart\" and mark some as Learning or Learned to get a verse to review each day.")
                )
            }
        }
        .navigationTitle("Review")
    }

    /// One verse per day from learned set: pick by day-of-year % count of learned/learning verses.
    private func verseToReviewToday() -> ScriptureVerse? {
        let learningOrLearned = memorized.filter { $0.status == "learning" || $0.status == "learned" }
        guard !learningOrLearned.isEmpty else { return nil }
        let dayOfYear = Calendar.current.ordinality(of: .day, in: .year, for: Date()) ?? 1
        let index = dayOfYear % learningOrLearned.count
        let mv = learningOrLearned[index]
        
        if let custom = mv.toScriptureVerse() {
            return custom
        }
        return defaultVerses.first { $0.id == mv.verseId }
    }
}

struct MemorizeReviewDetailView: View {
    let verse: ScriptureVerse
    @Environment(\.modelContext) private var modelContext
    @Query private var memorized: [MemorizedVerse]
    @State private var revealed = false

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            if let translation = verse.translation {
                Text("\(verse.reference) (\(translation))")
                    .font(.title2)
            } else {
                Text(verse.reference)
                    .font(.title2)
            }
            if revealed {
                Text(verse.text)
                    .font(.body)
            } else {
                Button("I'll say it from memory") {
                    revealed = true
                }
                .buttonStyle(.borderedProminent)
                Button("Show verse") {
                    revealed = true
                }
                .buttonStyle(.bordered)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .onAppear {
            updateLastReviewed()
        }
    }

    private func updateLastReviewed() {
        if let m = memorized.first(where: { $0.verseId == verse.id }) {
            m.lastReviewedDate = Date()
            try? modelContext.save()
        }
    }
}

#Preview {
    NavigationStack {
        HideInYourHeartView()
            .modelContainer(for: MemorizedVerse.self, inMemory: true)
    }
}
