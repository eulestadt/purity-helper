//
//  CloudSyncSettingsView.swift
//  PurityHelp
//
//  Sync to cloud (optional), base URL, Create account / Log in, Link for your partner.
//

import SwiftUI
import SwiftData
import UIKit

struct CloudSyncSettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var streakRecords: [StreakRecord]
    @Query private var urgeLogs: [UrgeLog]

    @AppStorage("cloudSyncEnabled") private var syncEnabled = false
    @State private var baseURL: String = ""
    @State private var shareLink: String?
    @State private var syncError: String?
    @State private var showAuth = false
    @State private var isSyncing = false
    @State private var isGeneratingLink = false

    private var streakRecord: StreakRecord? { streakRecords.first }

    var body: some View {
        Form {
            Section {
                Toggle("Partner Sharing (Web Portal)", isOn: $syncEnabled)
                    .onChange(of: syncEnabled) { _, on in
                        if on { triggerSync() }
                    }
            } header: {
                Text("Partner Sharing")
            } footer: {
                Text("Optional. Only turn this on if you want to share your progress via a web link.")
            }

            if syncEnabled {
                Section {
                    TextField("API base URL", text: $baseURL)
                        .textInputAutocapitalization(.never)
                        .keyboardType(.URL)
                        .onChange(of: baseURL) { _, v in
                            CloudSyncService.baseURL = v.isEmpty ? nil : v
                        }
                } footer: {
                    Text("e.g. https://your-api.onrender.com (no trailing slash)")
                }

                Section {
                    Button("Sync now") {
                        triggerSync()
                    }
                    .disabled(isSyncing || baseURL.isEmpty)
                    if let err = syncError {
                        Text(err)
                            .foregroundStyle(.red)
                            .font(.caption)
                    }
                }

                Section {
                    Button("Create account / Log in") {
                        showAuth = true
                    }
                    .sheet(isPresented: $showAuth) {
                        CloudAuthView()
                    }
                } footer: {
                    Text("Create account to recover your progress if you reinstall. Optional—sync works without an account.")
                }

                Section {
                    Text("Share your progress with someone.")
                        .font(.subheadline)
                    Text("Anyone with this link can view your progress summary. Only share it with someone you trust. They can open it in the app or in a browser.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    if let link = shareLink {
                        Text(link)
                            .font(.caption)
                            .lineLimit(2)
                        HStack {
                            Button("Copy link") {
                                UIPasteboard.general.string = link
                            }
                            .buttonStyle(.bordered)
                            Button("Regenerate link") {
                                regenerateLink()
                            }
                            .buttonStyle(.bordered)
                        }
                    } else {
                        Button("Get link for your partner") {
                            generateShareLink()
                        }
                        .disabled(isGeneratingLink || baseURL.isEmpty)
                    }
                } header: {
                    Text("Link for your partner")
                } footer: {
                    Text("Regenerate creates a new link; the old link will stop working.")
                }
            }
        }
        .navigationTitle("Cloud sync")
        .onAppear {
            baseURL = CloudSyncService.baseURL ?? ""
            if syncEnabled && !baseURL.isEmpty {
                generateShareLink()
            }
        }
    }

    private func triggerSync() {
        guard let r = streakRecord, !baseURL.isEmpty else {
            syncError = "Set base URL first."
            return
        }
        CloudSyncService.baseURL = baseURL.isEmpty ? nil : baseURL
        isSyncing = true
        syncError = nil
        let minutesPerDay = UserDefaults.standard.object(forKey: "minutesPerDayReclaimed") as? Int ?? 30
        let hours = (r.effectiveBehavioralStreak * minutesPerDay) / 60
        let payload = CloudSyncService.buildPayload(
            pornographyDays: r.pornographyStreakDays,
            masturbationDays: r.masturbationStreakDays,
            pureThoughtsDays: r.pureThoughtsStreakDays,
            pureThoughtsEnabled: r.pureThoughtsEnabled,
            urgeCount: urgeLogs.count,
            hoursReclaimed: hours > 0 ? hours : nil
        )
        CloudSyncService.sync(payload: payload) { result in
            isSyncing = false
            switch result {
            case .success: syncError = nil
            case .failure(let e): syncError = e.localizedDescription
            }
        }
    }

    private func generateShareLink() {
        guard !baseURL.isEmpty else { return }
        CloudSyncService.baseURL = baseURL
        isGeneratingLink = true
        CloudSyncService.createShareLink { result in
            isGeneratingLink = false
            switch result {
            case .success(let link): shareLink = link
            case .failure: shareLink = nil
            }
        }
    }

    private func regenerateLink() {
        shareLink = nil
        generateShareLink()
    }
}

struct CloudAuthView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var email = ""
    @State private var password = ""
    @State private var isSignUp = true
    @State private var error: String?
    @State private var loading = false

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Email", text: $email)
                        .textInputAutocapitalization(.never)
                        .keyboardType(.emailAddress)
                    SecureField("Password (min 8 characters)", text: $password)
                }
                if let err = error {
                    Section {
                        Text(err)
                            .foregroundStyle(.red)
                    }
                }
                Section {
                    Button(isSignUp ? "Create account" : "Log in") {
                        performAuth()
                    }
                    .disabled(loading || email.isEmpty || password.count < 8)
                    Toggle("I already have an account", isOn: Binding(
                        get: { !isSignUp },
                        set: { isSignUp = !$0 }
                    ))
                    .toggleStyle(.button)
                }
            }
            .navigationTitle(isSignUp ? "Create account" : "Log in")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }

    private func performAuth() {
        guard let base = CloudSyncService.baseURL, !base.isEmpty else {
            error = "Set API base URL in Cloud sync first."
            return
        }
        loading = true
        error = nil
        let path = isSignUp ? "/auth/signup" : "/auth/login"
        guard let url = URL(string: base.trimmingCharacters(in: .whitespacesAndNewlines) + path) else {
            error = "Invalid URL"
            loading = false
            return
        }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try? JSONSerialization.data(withJSONObject: ["email": email, "password": password])

        URLSession.shared.dataTask(with: request) { data, response, _ in
            let code = (response as? HTTPURLResponse)?.statusCode ?? 0
            DispatchQueue.main.async {
                loading = false
                guard code >= 200 && code < 300, let data = data,
                      let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                      let token = json["token"] as? String else {
                    error = (code == 409 ? "Email already registered." : "Invalid email or password.")
                    return
                }
                KeychainHelper.save(token, forKey: KeychainHelper.authTokenKey)
                dismiss()
            }
        }.resume()
    }
}

#Preview {
    NavigationStack {
        CloudSyncSettingsView()
            .modelContainer(for: [StreakRecord.self, UrgeLog.self], inMemory: true)
    }
}
