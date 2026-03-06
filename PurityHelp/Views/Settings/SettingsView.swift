//
//  SettingsView.swift
//  PurityHelp
//
//  Mission, pure thoughts toggle, hours reclaimed, daily pause reminder, etc.
//

import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var streakRecords: [StreakRecord]

    @State private var pureThoughtsEnabled: Bool = false
    @State private var hoursPerDayEstimate: Int = 30
    @AppStorage("dailyPauseReminderEnabled") private var dailyPauseReminderEnabled: Bool = true
    @AppStorage("dailyPauseReminderHour") private var dailyPauseReminderHour: Int = 9
    @AppStorage("dailyPauseReminderMinute") private var dailyPauseReminderMinute: Int = 0
    @State private var reminderTime: Date = Calendar.current.date(from: DateComponents(hour: 9, minute: 0)) ?? Date()
    @AppStorage("accountabilityPartnerPhone") private var accountabilityPartnerPhone: String = ""

    private var streakRecord: StreakRecord? { streakRecords.first }

    var body: some View {
        NavigationStack {
            ZStack {
                PurityBackground()
                Form {
                    Section {
                        NavigationLink("My Anchor", destination: MissionView())
                        NavigationLink("If–Then plans", destination: IfThenPlansView())
                    } header: {
                        Text("Mission")
                    }

                Section {
                    Toggle("Track pure thoughts (days guarding thoughts)", isOn: $pureThoughtsEnabled)
                        .onChange(of: pureThoughtsEnabled) { _, newValue in
                            streakRecord?.pureThoughtsEnabled = newValue
                            try? modelContext.save()
                        }
                } header: {
                    Text("Streaks")
                } footer: {
                    Text("Daily check-in: \"I guarded my thoughts today\" / \"I did not consent to lustful thoughts.\"")
                }

                Section {
                    Picker("Minutes per day previously spent", selection: $hoursPerDayEstimate) {
                        Text("15 min").tag(15)
                        Text("30 min").tag(30)
                        Text("45 min").tag(45)
                        Text("60 min").tag(60)
                    }
                    .onChange(of: hoursPerDayEstimate) { _, _ in
                        UserDefaults.standard.set(hoursPerDayEstimate, forKey: "minutesPerDayReclaimed")
                    }
                } header: {
                    Text("Hours reclaimed")
                } footer: {
                    Text("Used to show cumulative hours reclaimed for your life.")
                }

                Section {
                    Toggle("Daily pause for your heart", isOn: $dailyPauseReminderEnabled)
                    if dailyPauseReminderEnabled {
                        DatePicker("Reminder time", selection: $reminderTime, displayedComponents: .hourAndMinute)
                            .onChange(of: reminderTime) { _, newValue in
                                let c = Calendar.current.dateComponents([.hour, .minute], from: newValue)
                                dailyPauseReminderHour = c.hour ?? 9
                                dailyPauseReminderMinute = c.minute ?? 0
                            }
                    }
                    NavigationLink("Wisdom of the Ages", destination: WisdomOfTheAgesView())
                } header: {
                    Text("Spiritual")
                } footer: {
                    Text("A gentle moment each day to return to your journey—guard your heart and refocus.")
                }

                Section {
                    TextField("Accountability partner phone", text: $accountabilityPartnerPhone)
                        .keyboardType(.phonePad)
                } header: {
                    Text("Urge support")
                } footer: {
                    Text("Optional. Used when you tap \"Call accountability partner\" in urge support.")
                }

                Section {
                    NavigationLink("Account", destination: AccountProfileView())
                    NavigationLink("Walking Together", destination: CloudSyncSettingsView())
                }

                Section {
                    NavigationLink("Urge insights", destination: UrgeInsightsView())
                    NavigationLink("Danger zone", destination: DangerZoneView())
                } header: {
                    Text("Insights & Patterns")
                }
                }
                .scrollContentBackground(.hidden)
                .background(.clear)
                .navigationTitle("Settings")
                .onAppear {
                    pureThoughtsEnabled = streakRecord?.pureThoughtsEnabled ?? false
                    hoursPerDayEstimate = UserDefaults.standard.object(forKey: "minutesPerDayReclaimed") as? Int ?? 30
                    reminderTime = Calendar.current.date(from: DateComponents(hour: dailyPauseReminderHour, minute: dailyPauseReminderMinute)) ?? Date()
                }
            }
        }
    }
}

#Preview {
    SettingsView()
        .modelContainer(for: StreakRecord.self, inMemory: true)
}
