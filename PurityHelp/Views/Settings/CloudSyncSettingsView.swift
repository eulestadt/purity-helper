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
    @AppStorage("partnerName") private var partnerName = "Partner"
    @AppStorage("shareExamens") private var shareExamens = false
    
    @State private var baseURL: String = ""
    @State private var shareLink: String?
    @State private var syncError: String?
    @State private var showAuth = false
    @State private var isLoggedIn = false
    @State private var isSyncing = false
    @State private var isGeneratingLink = false

    private var streakRecord: StreakRecord? { streakRecords.first }

    var body: some View {
        Form {
            Section {
                Toggle(isOn: $syncEnabled) {
                    Label("Enable Partner Sync", systemImage: "person.2.fill")
                }
                .onChange(of: syncEnabled) { _, on in
                    if on { pushFullData() }
                }
                
                if syncEnabled {
                    TextField("Partner's Name (e.g. John)", text: $partnerName)
                        .textInputAutocapitalization(.words)
                }
            } header: {
                Text("Accountability Partner")
            } footer: {
                if syncEnabled {
                    Text("We'll use this name throughout the app.")
                } else {
                    Text("Turn this on to share your progress via a secure web link.")
                }
            }

            if syncEnabled {
                Section {
                    Toggle(isOn: $shareExamens) {
                        Label("Share Daily Examens", systemImage: "lock.open.fill")
                    }
                } header: {
                    Text("Privacy Controls")
                } footer: {
                    Text("When ON, your private Daily Examen reflections will be uploaded and visible on the Share Link portal.")
                }
                
                Section {
                    if let link = shareLink {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Your secure link:")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text(link)
                                .font(.callout)
                                .lineLimit(2)
                                .textSelection(.enabled)
                        }
                        .padding(.vertical, 4)
                        
                        HStack(spacing: 12) {
                            Button {
                                UIPasteboard.general.string = link
                            } label: {
                                Label("Copy", systemImage: "doc.on.doc")
                                    .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(.bordered)
                            .tint(.blue)
                            
                            Button {
                                regenerateLink()
                            } label: {
                                Label("Regenerate", systemImage: "arrow.2.squarepath")
                                    .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(.bordered)
                            .tint(.red)
                        }
                        .padding(.vertical, 4)
                    } else {
                        Button {
                            generateShareLink()
                        } label: {
                            Label("Get Link for \(partnerName)", systemImage: "link")
                        }
                        .disabled(isGeneratingLink || baseURL.isEmpty)
                    }
                } header: {
                    Text("Share Link")
                } footer: {
                    Text("Anyone with this link can view your progress summary. Regenerating it will instantly disable the old link.")
                }
                
                Section {
                    TextField("Server URL", text: $baseURL)
                        .textInputAutocapitalization(.never)
                        .keyboardType(.URL)
                        .onChange(of: baseURL) { _, v in
                            CloudSyncService.baseURL = v.isEmpty ? nil : v
                        }
                } header: {
                    Text("API Configuration")
                } footer: {
                    Text("e.g. https://purity-helper-api.onrender.com (no trailing slash)")
                }

                Section {
                    if isLoggedIn {
                        Button(role: .destructive) {
                            KeychainHelper.delete(forKey: KeychainHelper.authTokenKey)
                            isLoggedIn = false
                        } label: {
                            Label("Log out", systemImage: "rectangle.portrait.and.arrow.right")
                        }
                    } else {
                        Button {
                            showAuth = true
                        } label: {
                            Label("Create account / Log in", systemImage: "person.crop.circle.badge.plus")
                        }
                        .sheet(isPresented: $showAuth) {
                            CloudAuthView(isLoggedIn: $isLoggedIn)
                        }
                    }
                } footer: {
                    Text("Accounts are completely optional. Your data backs up safely to the cloud server even if you don't create an account, but logging in allows you to tie that data to a password so you can recover it across devices if you delete the app.")
                }
                
                Section {
                    Button {
                        pushFullData()
                    } label: {
                        Label("Push library to cloud", systemImage: "arrow.up.doc.fill")
                    }
                    .disabled(isSyncing || baseURL.isEmpty)
                    
                    Button(role: .destructive) {
                        pullFullData()
                    } label: {
                        Label("Pull library from cloud", systemImage: "arrow.down.doc.fill")
                    }
                    .disabled(isSyncing || baseURL.isEmpty)
                    
                    if let err = syncError {
                        Text(err)
                            .foregroundStyle(err.contains("successful") ? .green : .red)
                            .font(.caption)
                    }
                } header: {
                    Text("Manual Sync")
                } footer: {
                    Text("Warning: Pulling from the cloud will completely overwrite all local device data.")
                }
            }
        }
        .navigationTitle("Partner Sync")
        .onAppear {
            baseURL = CloudSyncService.baseURL ?? "https://purity-helper-api.onrender.com"
            isLoggedIn = KeychainHelper.load(forKey: KeychainHelper.authTokenKey) != nil
            if syncEnabled && !baseURL.isEmpty {
                generateShareLink()
            }
        }
    }

    private func pushFullData() {
        guard !baseURL.isEmpty else {
            syncError = "Set base URL first."
            return
        }
        CloudSyncService.baseURL = baseURL.isEmpty ? nil : baseURL
        isSyncing = true
        syncError = nil
        do {
            let engine = FullSyncEngine(context: modelContext)
            var fullModels = try engine.exportFullData()
            
            // Apply Privacy Controls
            if !shareExamens {
                fullModels.examenEntries = []
            }
            
            let r = streakRecord
            let minutesPerDay = UserDefaults.standard.object(forKey: "minutesPerDayReclaimed") as? Int ?? 30
            let hours = ((r?.effectiveBehavioralStreak ?? 0) * minutesPerDay) / 60
            
            let payload = CloudSyncService.buildPayload(
                pornographyDays: r?.pornographyStreakDays ?? 0,
                masturbationDays: r?.masturbationStreakDays ?? 0,
                pureThoughtsDays: r?.pureThoughtsStreakDays ?? 0,
                pureThoughtsEnabled: r?.pureThoughtsEnabled ?? false,
                urgeCount: urgeLogs.count,
                hoursReclaimed: hours > 0 ? hours : nil,
                fullModels: fullModels
            )
            CloudSyncService.sync(payload: payload) { result in
                isSyncing = false
                switch result {
                case .success: syncError = "Push successful!"
                case .failure(let e): syncError = e.localizedDescription
                }
            }
        } catch {
            isSyncing = false
            syncError = "Export failed: \(error.localizedDescription)"
        }
    }

    private func pullFullData() {
        guard !baseURL.isEmpty else {
            syncError = "Set base URL first."
            return
        }
        CloudSyncService.baseURL = baseURL.isEmpty ? nil : baseURL
        isSyncing = true
        syncError = nil
        
        CloudSyncService.fetchMe { result in
            isSyncing = false
            switch result {
            case .success(let payload):
                if let models = payload.models {
                    do {
                        let engine = FullSyncEngine(context: modelContext)
                        try engine.importFullData(models)
                        syncError = "Pull successful!"
                    } catch {
                        syncError = "Import failed: \(error.localizedDescription)"
                    }
                } else {
                    syncError = "No full data found on server."
                }
            case .failure(let e):
                syncError = e.localizedDescription
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
    @Binding var isLoggedIn: Bool
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
                    .disabled(loading || email.isEmpty || (isSignUp ? password.count < 8 : password.isEmpty))
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
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark").font(.headline).padding(6)
                            
                    }
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
                isLoggedIn = true
                dismiss()
            }
        }.resume()
    }
}

#Preview {
    NavigationStack {
        CloudAuthView(isLoggedIn: .constant(false))
    }
}
