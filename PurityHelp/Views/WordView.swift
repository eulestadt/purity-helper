//
//  WordView.swift
//

import SwiftUI

struct WordView: View {
    @Environment(AppStore.self) private var store
    @State private var verses: [ScriptureVerse] = []
    @State private var hidden = false
    @State private var lookup = "Matthew 5:8"
    @State private var lookedUp = ""
    @State private var looking = false

    var body: some View {
        let today = ScriptureLibrary.verseForToday(verses)
        NavigationStack {
            ZStack {
                PurityBackground()
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        if let today {
                            GlassPanel {
                                VStack(alignment: .leading, spacing: 10) {
                                    Text(today.reference)
                                        .font(.caption)
                                        .tracking(1)
                                        .textCase(.uppercase)
                                        .foregroundStyle(PurityColor.green)
                                    if hidden {
                                        Text("Say it from memory.")
                                            .font(.system(.title3, design: .serif))
                                    } else {
                                        Text(today.text)
                                            .font(.system(.title3, design: .serif))
                                    }
                                    HStack {
                                        Button(hidden ? "Show the text" : "Hide the text") { hidden.toggle() }
                                        Spacer()
                                        Button("I reviewed it") {
                                            store.logEvent(["kind": "verse", "reference": today.reference])
                                            store.put(key: "verse/\(today.id)", value: [
                                                "reference": today.reference,
                                                "text": today.text,
                                                "lastReviewedDay": DayDomain.todayString()
                                            ])
                                        }
                                        .buttonStyle(.borderedProminent)
                                        .tint(PurityColor.green)
                                    }
                                    Button(store.derived.practice.scripture ? "Reading recorded" : "I read this today") {
                                        store.logEvent(["kind": "scripture", "reference": today.reference])
                                    }
                                    .disabled(store.derived.practice.scripture)
                                }
                            }
                        }
                        GlassPanel {
                            VStack(alignment: .leading, spacing: 10) {
                                Text("Look up a passage").font(.headline)
                                TextField("John 8:11", text: $lookup)
                                    .textFieldStyle(.roundedBorder)
                                    .textInputAutocapitalization(.words)
                                Button(looking ? "Looking" : "Fetch") { Task { await fetchPassage() } }
                                    .disabled(looking || lookup.trimmingCharacters(in: .whitespaces).isEmpty)
                                if !lookedUp.isEmpty {
                                    Text(lookedUp).font(.body)
                                }
                            }
                        }
                        GlassPanel {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Hide it in your heart").font(.headline)
                                Text("Psalm 119:11. A short review is enough. The Word ring closes when you read and when you recite.")
                                    .foregroundStyle(PurityColor.muted)
                            }
                        }
                    }
                    .padding(20)
                }
            }
            .navigationTitle("Word")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear { if verses.isEmpty { verses = ScriptureLibrary.load() } }
        }
    }

    private func fetchPassage() async {
        looking = true
        defer { looking = false }
        let query = lookup.trimmingCharacters(in: .whitespaces).replacingOccurrences(of: " ", with: "+")
        guard let url = URL(string: "https://bible-api.com/\(query)?translation=kjv") else { return }
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
            lookedUp = (json?["text"] as? String)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? "That reference did not return a text."
        } catch {
            lookedUp = "The passage could not be loaded. The verse of the day is still on this phone."
        }
    }
}
