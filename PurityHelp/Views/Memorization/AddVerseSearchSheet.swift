//
//  AddVerseSearchSheet.swift
//  PurityHelp
//
//  Sheet to search API.bible for custom verses and save them to SwiftData.
//

import SwiftUI
import SwiftData

struct AddVerseSearchSheet: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @State private var query = ""
    @State private var searchResults: [ScriptureVerse] = []
    
    enum BibleTranslation: String, CaseIterable, Identifiable {
        case asv = "06125adad2d5898a-01"
        case kjv = "de4e12af7f28f599-01"
        case niv = "78a9f6124f344018-01"
        case nlt = "d6e14a625393b4da-01"
        case grc = "901dcd9744e1bf69-01"
        
        var id: String { rawValue }
        
        var displayName: String {
            switch self {
            case .asv: return "ASV"
            case .kjv: return "KJV"
            case .niv: return "NIV"
            case .nlt: return "NLT"
            case .grc: return "Greek"
            }
        }
    }
    
    @AppStorage("selectedBibleTranslation") private var selectedTranslationRaw = BibleTranslation.niv.rawValue
    
    private var selectedTranslation: BibleTranslation {
        get { BibleTranslation(rawValue: selectedTranslationRaw) ?? .niv }
        set { selectedTranslationRaw = newValue.rawValue }
    }
    @State private var isSearching = false
    @State private var errorMessage: String?
    
    @State private var bibleAPIService = BibleAPIService()

    var body: some View {
        NavigationStack {
            VStack {
                // Search Bar
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundStyle(.secondary)
                    TextField("Search for a verse or keyword...", text: $query)
                        .onSubmit {
                            performSearch()
                        }
                        .submitLabel(.search)
                    
                    if !query.isEmpty {
                        Button {
                            query = ""
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .padding()
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .padding(.horizontal)
                .padding(.top)
                
                if isSearching {
                    Spacer()
                    ProgressView("Searching API.bible...")
                    Spacer()
                } else if let error = errorMessage {
                    Spacer()
                    Text(error)
                        .foregroundStyle(.red)
                        .multilineTextAlignment(.center)
                        .padding()
                    Spacer()
                } else if searchResults.isEmpty && !query.isEmpty {
                    Spacer()
                    Text("No results found. Press Search to query.")
                        .foregroundStyle(.secondary)
                        .padding()
                    Spacer()
                } else {
                    List {
                        ForEach(searchResults) { verse in
                            Button {
                                saveCustomVerse(verse)
                            } label: {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("\(verse.reference) (\(verse.translation ?? ""))")
                                        .font(.headline)
                                        .foregroundStyle(.primary)
                                    Text(verse.text)
                                        .font(.body)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle("Add custom verse")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.secondary)
                    }
                }
                ToolbarItem(placement: .primaryAction) {
                    Menu {
                        Picker("Translation", selection: $selectedTranslationRaw) {
                            ForEach(BibleTranslation.allCases) { translation in
                                Text(translation.displayName).tag(translation.rawValue)
                            }
                        }
                    } label: {
                        Label(selectedTranslation.displayName, systemImage: "chevron.up.chevron.down")
                    }
                    .onChange(of: selectedTranslationRaw) { _, _ in
                        if !query.isEmpty {
                            performSearch()
                        }
                    }
                }
            }
        }
    }
    
    private func performSearch() {
        let trimmedQuery = query.trimmingCharacters(in: .whitespaces)
        guard !trimmedQuery.isEmpty else { return }
        
        isSearching = true
        errorMessage = nil
        
        Task {
            do {
                // Initial search with selected translation
                let allResults = try await bibleAPIService.searchVerses(
                    query: trimmedQuery,
                    bibleId: selectedTranslation.rawValue,
                    translationName: selectedTranslation.displayName
                )
                
                    
                    self.searchResults = uniqueResults
                    self.isSearching = false
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = "Failed to load verses: \(error.localizedDescription)"
                    self.isSearching = false
                }
            }
        }
    }
    
    private func saveCustomVerse(_ verse: ScriptureVerse) {
        // Create a MemorizedVerse with custom fields
        let mVerse = MemorizedVerse(
            verseId: verse.id,
            status: "learning",
            lastReviewedDate: nil,
            customReference: verse.reference,
            customText: verse.text,
            customTranslation: verse.translation
        )
        modelContext.insert(mVerse)
        try? modelContext.save()
        
        // Use a generic success haptic
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
        
        dismiss()
    }
}

#Preview {
    AddVerseSearchSheet()
        .modelContainer(for: MemorizedVerse.self, inMemory: true)
}
