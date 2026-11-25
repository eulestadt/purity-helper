//
//  PathView.swift
//

import SwiftUI

struct PathView: View {
    @Environment(AppStore.self) private var store
    @State private var section = 0
    @State private var trigger = ""
    @State private var action = ""
    @State private var stories: [HopeStory] = []

    private let practices: [(String, String)] = [
        ("Jay Stringer", "The urge is a signpost. Ask what hunger it points to, and do not obey it."),
        ("Michael Cusick", "The pull is often a search for a real passion. Return to the joy you actually want."),
        ("William Struthers", "A different path is worn by repetition. Give the body a true reward: move, cold water, prayer, a person."),
        ("Nate Larkin", "Solitary heroism fails. One honest sentence, said to one safe person, is enough of a meeting."),
        ("Heath Lambert", "Grace is not passivity. Tell the truth, make the old path harder, and put a verse where the image was.")
    ]
    private let wisdom: [(String, String)] = [
        ("Thomas à Kempis", "A pure heart can see God. Keep the heart, and the eyes follow."),
        ("Augustine", "Our heart is restless until it rests in you."),
        ("Francis de Sales", "Have patience with all things, but chiefly with yourself."),
        ("John Bunyan", "There is a way, though it is narrow, and the burden falls on it."),
        ("C. S. Lewis", "We are half-hearted creatures, fooling about with drink and sex and ambition when infinite joy is offered us.")
    ]
    private let weekdayNames = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]

    var body: some View {
        let day = store.derived
        NavigationStack {
            ZStack {
                PurityBackground()
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        Picker("Section", selection: $section) {
                            Text("Plans").tag(0)
                            Text("Hours").tag(1)
                            Text("Stories").tag(2)
                            Text("Wisdom").tag(3)
                        }
                        .pickerStyle(.segmented)
                        switch section {
                        case 0: plans(day)
                        case 1: hours(day)
                        case 2: storyList
                        default: wisdomList
                        }
                    }
                    .padding(20)
                }
            }
            .navigationTitle("Path")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear { if stories.isEmpty { stories = StoryLibrary.load() } }
        }
    }

    @ViewBuilder
    private func plans(_ day: DerivedDay) -> some View {
        GlassPanel {
            VStack(alignment: .leading, spacing: 10) {
                Text("If this happens, then I will").font(.headline)
                TextField("If I am alone after 11", text: $trigger)
                    .textFieldStyle(.roundedBorder)
                TextField("I will walk and pray", text: $action)
                    .textFieldStyle(.roundedBorder)
                Button("Save this plan") {
                    let id = UUID().uuidString.lowercased()
                    store.put(key: "plan/\(id)", value: ["trigger": trigger, "action": action])
                    trigger = ""
                    action = ""
                }
                .buttonStyle(.borderedProminent)
                .tint(PurityColor.green)
                .disabled(trigger.trimmingCharacters(in: .whitespaces).isEmpty || action.trimmingCharacters(in: .whitespaces).isEmpty)
            }
        }
        if day.plans.isEmpty {
            Text("No plans yet. One sentence is enough.")
                .foregroundStyle(PurityColor.muted)
        }
        ForEach(day.plans) { plan in
            GlassPanel {
                VStack(alignment: .leading, spacing: 6) {
                    Text(plan.trigger).font(.headline)
                    Text(plan.action)
                    Button("Remove", role: .destructive) { store.delete(key: "plan/\(plan.id)") }
                        .font(.caption)
                }
            }
        }
    }

    @ViewBuilder
    private func hours(_ day: DerivedDay) -> some View {
        GlassPanel {
            VStack(alignment: .leading, spacing: 8) {
                Text("When the wave usually comes").font(.headline)
                if let hour = day.danger.busiestHour {
                    Text("Most often around \(hourName(hour)).")
                        .foregroundStyle(PurityColor.muted)
                } else {
                    Text("Urges and relapses will draw this picture as you record them.")
                        .foregroundStyle(PurityColor.muted)
                }
                if let thirst = day.danger.commonThirst {
                    Text("The thirst underneath, most often: \(thirst).")
                        .foregroundStyle(PurityColor.muted)
                }
                let peak = max(day.danger.hours.max() ?? 1, 1)
                HStack(alignment: .bottom, spacing: 3) {
                    ForEach(0..<24, id: \.self) { hour in
                        Capsule()
                            .fill(hour == day.danger.busiestHour ? PurityColor.clay : PurityColor.green.opacity(0.45))
                            .frame(height: CGFloat(day.danger.hours[hour]) / CGFloat(peak) * 72 + 4)
                    }
                }
                .frame(height: 80)
                HStack {
                    ForEach(0..<7, id: \.self) { dayIndex in
                        VStack {
                            Text("\(day.danger.weekdays[dayIndex])").font(.caption.monospacedDigit())
                            Text(weekdayNames[dayIndex]).font(.caption2).foregroundStyle(PurityColor.muted)
                        }
                        .frame(maxWidth: .infinity)
                    }
                }
            }
        }
        GlassPanel {
            VStack(alignment: .leading, spacing: 6) {
                Text("\(day.hoursReclaimed, specifier: "%.1f") hours reclaimed")
                    .font(.title2)
                Text("Clear days times the hours you set in Settings. The number is derived. It is not a counter the cloud can overwrite.")
                    .foregroundStyle(PurityColor.muted)
            }
        }
    }

    private var storyList: some View {
        ForEach(stories) { story in
            NavigationLink {
                ScrollView {
                    VStack(alignment: .leading, spacing: 12) {
                        Text(story.category).font(.caption).foregroundStyle(PurityColor.green)
                        Text(story.context)
                        Text(story.whatHelped)
                        Text(story.takeaway).font(.system(.body, design: .serif))
                    }
                    .padding(20)
                }
                .background(PurityBackground())
                .navigationTitle(story.title)
                .navigationBarTitleDisplayMode(.inline)
            } label: {
                GlassPanel {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(story.title).font(.headline).foregroundStyle(PurityColor.ink)
                        Text(story.takeaway)
                            .font(.subheadline)
                            .foregroundStyle(PurityColor.muted)
                            .lineLimit(3)
                    }
                }
            }
            .buttonStyle(.plain)
        }
    }

    private var wisdomList: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("What has helped, distilled in our words. The names mark the counsel. They are not quotations.")
                .font(.footnote)
                .foregroundStyle(PurityColor.muted)
            ForEach(practices + wisdom, id: \.0) { item in
                GlassPanel {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(item.1).font(.system(.body, design: .serif))
                        Text(item.0).font(.caption).foregroundStyle(PurityColor.gold)
                    }
                }
            }
        }
    }

    private func hourName(_ hour: Int) -> String {
        let suffix = hour < 12 ? "in the morning" : "in the evening"
        let face = hour % 12 == 0 ? 12 : hour % 12
        if hour < 12 { return "\(face) \(suffix)" }
        return "\(face) \(hour < 17 ? "in the afternoon" : "in the evening")"
    }
}
