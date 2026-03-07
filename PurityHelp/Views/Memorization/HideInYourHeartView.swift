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
    private let dailyVerse = ScriptureService.verseForToday()
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
        ZStack {
            PurityBackground().ignoresSafeArea()
            
            List {
                Section {
                    VStack(alignment: .leading, spacing: 0) {
                        Text("Daily Scripture")
                            .font(.caption)
                            
                        Text(dailyVerse.reference)
                            .font(.caption)
                            
                        Text(dailyVerse.text)
                            .font(.body)
                    }
                    .frame(maxWidth: .infinity)
                }
                .listRowBackground(Color.clear)
                
                Section {
                    NavigationLink(destination: MemorizeReviewView()) {
                        HStack {
                            let dueCount = memorized.filter { ($0.status == "learning" || $0.status == "learned") && $0.nextReviewDate <= Date.now }.count
                            Label("Review verses", systemImage: "arrow.clockwise")
                            Spacer()
                            if dueCount > 0 {
                                Text("\(dueCount)")
                                    .font(.caption.bold())
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Color.red)
                                    .clipShape(Capsule())
                            } else {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.green)
                            }
                        }
                    }
                }
                .listRowBackground(Color.white.opacity(0.15))
                
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
                        .listRowBackground(Color.white.opacity(0.15))
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
                } // End Section
            } // End List
            .scrollContentBackground(.hidden)
        } // End ZStack
        //.navigationTitle(dailyVerse.reference)
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
        Task { @MainActor in AutoSyncManager.shared.performBackgroundSync(modelContext: modelContext) }
    }
    
    private func unlearnVerse(_ verse: MemorizedVerse) {
        verse.status = "none"
        verse.updatedAt = Date.now
        try? modelContext.save()
        Task { @MainActor in AutoSyncManager.shared.performBackgroundSync(modelContext: modelContext) }
    }
}

struct MemorizeLearnView: View {
    let verse: ScriptureVerse
    let progress: MemorizedVerse?
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    enum TextDisplayMode: String, CaseIterable, Identifiable {
        case full = "Full Text"
        case firstLetters = "First Letters"
        case hidden = "Hidden"
        var id: String { rawValue }
    }
    
    @State private var displayMode: TextDisplayMode = .full
    @State private var status: String

    init(verse: ScriptureVerse, progress: MemorizedVerse?) {
        self.verse = verse
        self.progress = progress
        _status = State(initialValue: progress?.status ?? "learning")
    }
    
    private var firstLettersText: String {
        // Keep punctuation but replace word characters
        verse.text.split(separator: " ").map { word in
            guard let firstChar = word.first(where: { $0.isLetter || $0.isNumber }) else { return String(word) }
            return String(firstChar) + String(repeating: "_", count: max(0, word.count - 1))
        }.joined(separator: " ")
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("Use the modes below to help you memorize. First Letters mode is a powerful tool to train your brain.")
                    .font(.subheadline)
                    

                Picker("Display Mode", selection: $displayMode) {
                    ForEach(TextDisplayMode.allCases) { mode in
                        Text(mode.rawValue).tag(mode)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.bottom, 10)

                VStack(alignment: .leading, spacing: 10) {
                    if let translation = verse.translation {
                        Text("\(verse.reference) (\(translation))")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    } else {
                        Text(verse.reference)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    
                    switch displayMode {
                    case .full:
                        Text(verse.text)
                            .font(.title3)
                    case .firstLetters:
                        Text(firstLettersText)
                            .font(.title3)
                            .lineSpacing(4)
                    case .hidden:
                        Text("Say the verse from memory.")
                            .font(.title3)
                            .foregroundStyle(.secondary)
                            .italic()
                    }
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color(UIColor.secondarySystemBackground).opacity(0.5))
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .padding(.bottom, 10)

                Text("How well do you know this?")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    
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
        .navigationBarTitleDisplayMode(.inline)
        .onDisappear {
            saveProgress(status: status)
        }
    }

    private func saveProgress(status: String) {
        if let p = progress {
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
}

struct MemorizeReviewView: View {
    @Query private var memorized: [MemorizedVerse]
    @Environment(\.modelContext) private var modelContext
    private let defaultVerses = ScriptureService.versesForMemorization()
    @State private var sessionCompletedIds: Set<String> = []

    private var reviewQueue: [MemorizedVerse] {
        memorized
            .filter { $0.status == "learning" || $0.status == "learned" }
            .sorted { $0.nextReviewDate < $1.nextReviewDate }
    }
    
    private var activeQueue: [MemorizedVerse] {
        reviewQueue.filter { !sessionCompletedIds.contains($0.verseId) }
    }
    
    private var dueCount: Int {
        activeQueue.filter { $0.nextReviewDate <= Date.now }.count
    }

    var body: some View {
        Group {
            if let mv = activeQueue.first, let verse = getScriptureVerse(for: mv) {
                MemorizeReviewDetailView(verse: verse, memorizedVerse: mv) {
                    withAnimation {
                        sessionCompletedIds.insert(mv.verseId)
                    }
                }
            } else if !reviewQueue.isEmpty {
                VStack(spacing: 20) {
                    ContentAvailabilityView(
                        title: "Session complete!",
                        systemImage: "party.popper.fill",
                        description: "You've gone through all your verses for this round."
                    )
                    
                    Button("Practice again") {
                        withAnimation {
                            sessionCompletedIds.removeAll()
                        }
                    }
                    .buttonStyle(.bordered)
                }
            } else {
                ContentUnavailableView(
                    "No verses yet",
                    systemImage: "book.closed",
                    description: Text("Add verses in \"Hide in your heart\" and mark them as Learning or Learned to start reviewing.")
                )
            }
        }
        .navigationTitle(navTitle)
        .navigationBarTitleDisplayMode(.inline)
    }
    
    private var navTitle: String {
        if dueCount > 0 {
            return "Review (\(dueCount) due)"
        } else if !activeQueue.isEmpty {
            return "Practicing ahead"
        } else {
            return "Review"
        }
    }

    private func getScriptureVerse(for mv: MemorizedVerse) -> ScriptureVerse? {
        if let custom = mv.toScriptureVerse() { return custom }
        return defaultVerses.first { $0.id == mv.verseId }
    }
}

struct MemorizeReviewDetailView: View {
    let verse: ScriptureVerse
    let memorizedVerse: MemorizedVerse
    var onComplete: () -> Void
    @Environment(\.modelContext) private var modelContext
    @State private var revealed = false

    var body: some View {
        VStack(spacing: 30) {
            Spacer()
            
            VStack(spacing: 8) {
                if let translation = verse.translation {
                    Text("\(verse.reference) (\(translation))")
                        .font(.title)
                        .fontWeight(.bold)
                } else {
                    Text(verse.reference)
                        .font(.title)
                        .fontWeight(.bold)
                }
            }
            
            if revealed {
                Text(verse.text)
                    .font(.title2)
                    .multilineTextAlignment(.center)
                    .padding()
                    .background(Color(UIColor.secondarySystemBackground).opacity(0.8))
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .padding(.horizontal)
                    
                Spacer()
                
                Text("How did you do?")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                
                HStack(spacing: 16) {
                    Button(action: { processReview(success: false) }) {
                        VStack {
                            Image(systemName: "brain")
                                .font(.title2)
                            Text("Still Learning")
                                .font(.headline)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.orange.opacity(0.2))
                        .foregroundColor(.orange)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    
                    Button(action: { processReview(success: true) }) {
                        VStack {
                            Image(systemName: "checkmark.seal")
                                .font(.title2)
                            Text("Learned!")
                                .font(.headline)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.green.opacity(0.2))
                        .foregroundColor(.green)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                }
                .padding(.horizontal)
            } else {
                Spacer()
                
                Button(action: {
                    withAnimation { revealed = true }
                }) {
                    Text("Reveal Verse")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.accentColor)
                        .foregroundColor(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .padding(.horizontal)
            }
            
            Spacer()
        }
        .frame(maxWidth: .infinity)
        // Reset state when the verse changes
        .id(verse.id)
    }

    private func processReview(success: Bool) {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(success ? .success : .warning)
        
        withAnimation {
            memorizedVerse.processReview(success: success)
            try? modelContext.save()
            Task { @MainActor in AutoSyncManager.shared.performBackgroundSync(modelContext: modelContext) }
            
            // Trigger session completion UI update
            onComplete()
            
            // Auto hide for the next verse
            revealed = false
        }
    }
}

// Simple helper because ContentUnavailableView isn't available in all versions or contexts identically
struct ContentAvailabilityView: View {
    let title: String
    let systemImage: String
    let description: String
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: systemImage)
                .font(.system(size: 48))
                .foregroundStyle(.secondary)
                .padding(.bottom, 8)
            Text(title)
                .font(.title2)
                .fontWeight(.bold)
            Text(description)
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
    }
}

#Preview {
    NavigationStack {
        HideInYourHeartView()
            .modelContainer(for: MemorizedVerse.self, inMemory: true)
    }
}
