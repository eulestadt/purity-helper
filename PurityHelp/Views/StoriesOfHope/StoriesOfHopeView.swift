//
//  StoriesOfHopeView.swift
//  PurityHelp
//
//  Curated recovery examples; categories; linked from Urge Moment.
//  Loads from Resources/StoriesOfHope/stories.json when present; otherwise uses built-in historical stories.
//  Renders "What helped" as a bullet list and supports *emphasis* in text via AttributedString(markdown:).
//

import SwiftUI

struct StoryOfHope: Identifiable {
    let id: String
    let title: String
    let category: String
    let summary: String
    let takeaway: String
    var whatHelped: String?
    var tradition: String?
    var source: String?
}

/// JSON shape from Gemini research prompt (stories.json).
private struct StoryOfHopeJSON: Codable {
    let id: String
    let title: String
    let category: String
    let tradition: String?
    let context: String
    let whatHelped: String?
    let takeaway: String
    let source: String?
}

/// Renders a string that may contain Markdown (*italic*, **bold**) using AttributedString.
private struct MarkdownText: View {
    let source: String

    var body: some View {
        if let attr = try? AttributedString(markdown: source) {
            Text(attr)
        } else {
            Text(source)
        }
    }
}

/// Splits "What helped" content (bullet lines with optional *emphasis*) into list items and renders as bullets + markdown.
private struct WhatHelpedBlock: View {
    let raw: String

    private var lines: [String] {
        raw.components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .map { line in
                if line.hasPrefix("• ") {
                    return String(line.dropFirst(2))
                }
                return line
            }
            .filter { !$0.isEmpty }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            ForEach(Array(lines.enumerated()), id: \.offset) { _, line in
                HStack(alignment: .top, spacing: 8) {
                    Text("•")
                        .font(.body)
                        .foregroundStyle(.secondary)
                    MarkdownText(source: line)
                        .font(.body)
                }
            }
        }
    }
}

enum StoriesOfHopeLoader {
    static func load() -> [StoryOfHope] {
        let url = Bundle.main.url(forResource: "stories", withExtension: "json", subdirectory: "Resources/StoriesOfHope")
            ?? Bundle.main.url(forResource: "stories", withExtension: "json", subdirectory: "StoriesOfHope")
            ?? Bundle.main.url(forResource: "stories", withExtension: "json")
        guard let u = url,
              let data = try? Data(contentsOf: u),
              let decoded = try? JSONDecoder().decode([StoryOfHopeJSON].self, from: data),
              !decoded.isEmpty
        else {
            return builtInStories
        }
        return decoded.map { j in
            StoryOfHope(
                id: j.id,
                title: j.title,
                category: j.category,
                summary: j.context,
                takeaway: j.takeaway,
                whatHelped: j.whatHelped,
                tradition: j.tradition,
                source: j.source
            )
        }
    }

    private static let builtInStories: [StoryOfHope] = [
        StoryOfHope(id: "mary", title: "St. Mary of Egypt", category: "Historical", summary: "17 years in sexual sin; conversion before the icon of the Theotokos; 47 years in the desert in penance.", takeaway: "Even the gravest fall can be turned into a life of repentance and holiness."),
        StoryOfHope(id: "anthony", title: "St. Anthony the Great", category: "Historical", summary: "Intense temptation in the desert; resistance through prayer and asceticism.", takeaway: "Spiritual warfare is real; persistence in prayer and discipline brings freedom."),
        StoryOfHope(id: "augustine", title: "St. Augustine", category: "Historical", summary: "Lust and \"Give me chastity, but not yet\"; conversion at the fig tree (Rom 13:13–14).", takeaway: "Honest struggle and eventual surrender to grace—God meets us where we are."),
        StoryOfHope(id: "newton", title: "John Newton", category: "Historical", summary: "Debauchery and the slave trade; cry for mercy in a storm (1748); gradual conversion; \"Amazing Grace.\"", takeaway: "Grace can save the worst; redemption is possible for everyone."),
        StoryOfHope(id: "markji", title: "St. Mark Ji Tianxiang", category: "Historical", summary: "30 years faithful despite opium addiction and being denied the sacraments; freed at last; patron of addicts.", takeaway: "Never give up. Remain faithful even when the road is long."),
    ]
}

struct StoriesOfHopeView: View {
    @State private var selectedCategory: String? = nil
    @State private var selectedStory: StoryOfHope? = nil
    private let allStories = StoriesOfHopeLoader.load()

    /// Categories are derived from the JSON: unique category values, sorted, with "All" first.
    private var categories: [String] {
        let unique = Array(Set(allStories.map(\.category))).sorted()
        return ["All"] + unique
    }

    private var stories: [StoryOfHope] {
        if let cat = selectedCategory, cat != "All" {
            return allStories.filter { $0.category == cat }
        }
        return allStories
    }

    var body: some View {
        ZStack {
            PurityBackground()
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 14) {
                    Text("Categories")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(categories, id: \.self) { cat in
                                Button {
                                    selectedCategory = cat
                                } label: {
                                    Text(cat)
                                        .font(.subheadline.weight(.semibold))
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 7)
                                        .background(selectedCategory == cat ? Color.white.opacity(0.55) : Color.white.opacity(0.25))
                                        .clipShape(Capsule())
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }

                    Text("Stories")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)

                    ForEach(stories) { story in
                        Button {
                            selectedStory = story
                        } label: {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(story.title)
                                    .font(.headline)
                                Text(story.summary)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                    .lineLimit(2)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding()
                            .glassCard(cornerRadius: 16)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding()
            }
        }
        .navigationTitle("Stories of Hope")
        .sheet(item: $selectedStory) { story in
            StoryDetailSheet(story: story)
        }
    }
}

struct StoryDetailView: View {
    let story: StoryOfHope

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                if let tradition = story.tradition, !tradition.isEmpty {
                    Text(tradition)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                MarkdownText(source: story.summary)
                    .font(.body)
                if let whatHelped = story.whatHelped, !whatHelped.isEmpty {
                    Text("What helped")
                        .font(.headline)
                    WhatHelpedBlock(raw: whatHelped)
                }
                Text("Takeaway")
                    .font(.headline)
                MarkdownText(source: story.takeaway)
                    .font(.body)
                if let source = story.source, !source.isEmpty {
                    Text(source)
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
            }
            .padding()
        }
        .navigationTitle(story.title)
    }
}

private struct StoryDetailSheet: View {
    let story: StoryOfHope
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            PurityBackground()
            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    HStack {
                        Text(story.title)
                            .font(.title3.weight(.bold))
                        Spacer()
                        Button("Done") { dismiss() }
                            .buttonStyle(.bordered)
                    }

                    if let tradition = story.tradition, !tradition.isEmpty {
                        Text(tradition)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    MarkdownText(source: story.summary)
                        .font(.body)
                    if let whatHelped = story.whatHelped, !whatHelped.isEmpty {
                        Text("What helped")
                            .font(.headline)
                        WhatHelpedBlock(raw: whatHelped)
                    }
                    Text("Takeaway")
                        .font(.headline)
                    MarkdownText(source: story.takeaway)
                        .font(.body)
                    if let source = story.source, !source.isEmpty {
                        Text(source)
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                    }
                }
                .padding()
                .glassCard(cornerRadius: 20)
                .padding()
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }
}

#Preview {
    NavigationStack {
        StoriesOfHopeView()
    }
}
