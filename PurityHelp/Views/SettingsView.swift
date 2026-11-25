//
//  SettingsView.swift
//

import SwiftUI

struct SettingsView: View {
    @Environment(AppStore.self) private var store
    @State private var mission = ""
    @State private var hours = 1.0
    @State private var baseURL = ""
    @State private var email = ""
    @State private var password = ""
    @State private var createAccount = false

    var body: some View {
        let day = store.derived
        NavigationStack {
            ZStack {
                PurityBackground()
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        GlassPanel {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Why this day").font(.headline)
                                TextField("I want a clean heart", text: $mission, axis: .vertical)
                                    .textFieldStyle(.roundedBorder)
                                Stepper(value: $hours, in: 0...12, step: 0.5) {
                                    Text("Hours a clear day gives back: \(hours, specifier: "%.1f")")
                                }
                                Button("Save") {
                                    store.updateProfile { profile in
                                        profile["mission"] = mission
                                        profile["hoursPerDay"] = hours
                                        if profile["journeyStart"] == nil {
                                            profile["journeyStart"] = DayDomain.todayString()
                                        }
                                    }
                                }
                                .buttonStyle(.borderedProminent)
                                .tint(PurityColor.green)
                            }
                        }
                        GlassPanel {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Sync").font(.headline)
                                Text("The phone works alone. Sign in when you want another device, or a partner link, to see the same events.")
                                    .font(.subheadline)
                                    .foregroundStyle(PurityColor.muted)
                                TextField("https://your-app.up.railway.app", text: $baseURL)
                                    .textFieldStyle(.roundedBorder)
                                    .textInputAutocapitalization(.never)
                                    .keyboardType(.URL)
                                    .autocorrectionDisabled()
                                TextField("Email", text: $email)
                                    .textFieldStyle(.roundedBorder)
                                    .textInputAutocapitalization(.never)
                                    .keyboardType(.emailAddress)
                                SecureField("Password", text: $password)
                                    .textFieldStyle(.roundedBorder)
                                Toggle("Create an account", isOn: $createAccount)
                                HStack {
                                    Button(store.busy ? "Working" : (createAccount ? "Create" : "Log in")) {
                                        store.setBaseURL(baseURL)
                                        Task { await store.login(email: email, password: password, create: createAccount) }
                                    }
                                    .buttonStyle(.borderedProminent)
                                    .tint(PurityColor.green)
                                    .disabled(store.busy)
                                    Button("Sync now") {
                                        store.setBaseURL(baseURL)
                                        Task { await store.syncNow() }
                                    }
                                    .disabled(store.busy)
                                }
                                if store.isSignedIn {
                                    Button("Sign out") { store.logout() }
                                        .foregroundStyle(PurityColor.clay)
                                }
                                Text(store.status).font(.footnote).foregroundStyle(PurityColor.muted)
                                if !store.email.isEmpty {
                                    Text(store.email).font(.footnote).foregroundStyle(PurityColor.muted)
                                }
                            }
                        }
                        GlassPanel {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("What a partner sees").font(.headline)
                                Text("One honest sentence to one safe person does more than a private streak.")
                                    .font(.subheadline)
                                    .foregroundStyle(PurityColor.muted)
                                toggle("Rings", key: "shareRings", value: day.shareRings)
                                toggle("Streaks", key: "shareStreaks", value: day.shareStreaks)
                                toggle("Mission", key: "shareMission", value: day.shareMission)
                                toggle("Relapses", key: "shareRelapses", value: day.shareRelapses)
                                toggle("Urges", key: "shareUrges", value: day.shareUrges)
                                toggle("Examens", key: "shareExamens", value: day.shareExamens)
                                if !store.shareLink.isEmpty {
                                    Text(store.shareLink).font(.caption).textSelection(.enabled)
                                }
                                HStack {
                                    Button("Share link") { Task { await store.refreshShareLink() } }
                                    Button("New link") { Task { await store.refreshShareLink(regenerate: true) } }
                                }
                                .disabled(!store.isSignedIn)
                            }
                        }
                        GlassPanel {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Reminders").font(.headline)
                                Text("A morning offering at 7:30 and an examen at 9:15.")
                                    .foregroundStyle(PurityColor.muted)
                                Button("Turn on reminders") {
                                    Task { await NotificationManager.scheduleDailyReminders() }
                                }
                            }
                        }
                    }
                    .padding(20)
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                mission = day.mission
                hours = day.hoursPerDay
                baseURL = store.baseURL
                if email.isEmpty { email = store.email }
            }
        }
    }

    private func toggle(_ title: String, key: String, value: Bool) -> some View {
        Toggle(title, isOn: Binding(
            get: { value },
            set: { newValue in
                store.updateProfile { $0[key] = newValue }
            }
        ))
    }
}
