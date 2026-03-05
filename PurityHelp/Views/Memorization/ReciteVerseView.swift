//
//  ReciteVerseView.swift
//  PurityHelp
//
//  List of learned/learning verses for use in urge moment: tap to see reference and text or say from memory.
//

import SwiftUI
import SwiftData

struct ReciteVerseView: View {
    @Environment(\.dismiss) private var dismiss
    @Query private var memorized: [MemorizedVerse]

    private let defaultVerses = ScriptureService.versesForMemorization()

    private var allVersesCombined: [ScriptureVerse] {
        let customVerses = memorized.compactMap { $0.toScriptureVerse() }
        let customIds = Set(customVerses.map { $0.id })
        let staticVerses = defaultVerses.filter { !customIds.contains($0.id) }
        return customVerses + staticVerses
    }

    private var learningOrLearned: [MemorizedVerse] {
        memorized.filter { $0.status == "learning" || $0.status == "learned" }
    }

    var body: some View {
        NavigationStack {
            Group {
                if learningOrLearned.isEmpty {
                    ContentUnavailableView(
                        "No verses yet",
                        systemImage: "book.closed",
                        description: Text("Add verses in Settings → Spiritual → Hide in your heart, then mark them as Learning or Learned.")
                    )
                } else {
                    List {
                        ForEach(learningOrLearned, id: \.verseId) { mv in
                            if let verse = allVersesCombined.first(where: { $0.id == mv.verseId }) {
                                NavigationLink(destination: ReciteVerseDetailView(verse: verse)) {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(verse.reference)
                                            .font(.headline)
                                        Text(verse.text)
                                            .font(.caption)
                                            
                                            .lineLimit(2)
                                    }
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Recite a verse")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark").font(.headline).padding(6).background(Color(uiColor: .tertiarySystemFill), in: Circle())
                            
                    }
                }
            }
        }
    }
}

struct ReciteVerseDetailView: View {
    let verse: ScriptureVerse
    @State private var showText = false

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text(verse.reference)
                .font(.title2)
            if showText {
                Text(verse.text)
                    .font(.body)
                Button("Hide text (say from memory)") {
                    showText = false
                }
                .buttonStyle(.bordered)
            } else {
                Text("Say it from memory.")
                    .font(.subheadline)
                    
                Button("Show verse") {
                    showText = true
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    ReciteVerseView()
        .modelContainer(for: MemorizedVerse.self, inMemory: true)
}
