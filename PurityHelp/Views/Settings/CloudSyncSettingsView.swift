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
    @AppStorage("accountabilityTerm") private var accountabilityTerm = "Brotherhood"
    private var partnersLabel: String { accountabilityTerm == "Brotherhood" ? "Brothers" : (accountabilityTerm == "Sisterhood" ? "Sisters" : "Partners") }
    @AppStorage("partnerName") private var partnerName = ""
    @AppStorage("shareExamens") private var shareExamens = false
    @AppStorage("shareUrges") private var shareUrges = true
    @AppStorage("shareRelapses") private var shareRelapses = false
    @State private var shareLink: String?
    @State private var syncError: String?
    @State private var showAuth = false
    @State private var isLoggedIn = false
    @State private var isSyncing = false
    @State private var isGeneratingLink = false

    private var streakRecord: StreakRecord? { streakRecords.first }

    var body: some View {
        ZStack {
            PurityBackground().ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 24) {
                    
                    // MARK: - Accountability Setup
                    VStack(alignment: .leading, spacing: 16) {
                        Picker("Accountability Type", selection: $accountabilityTerm) {
                            Text("Brotherhood").tag("Brotherhood")
                            Text("Sisterhood").tag("Sisterhood")
                            Text("Walk Together").tag("Walk Together")
                        }
                        .pickerStyle(.segmented)
                        .padding(.bottom, 8)
                        
                        Toggle(isOn: $syncEnabled) {
                            Text("Enable Shared Walk")
                                .font(.headline)
                        }
                        .tint(.blue)
                        
                        Text("Invite someone you trust to walk this path with you. They will be able to view a secure summary of your journey.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        
                        if syncEnabled {
                            Divider().background(Color.white.opacity(0.1))
                            
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Walking with:")
                                    .font(.subheadline)
                                
                                TextField("e.g. Felix", text: $partnerName)
                                    .textInputAutocapitalization(.words)
                                    .padding()
                                    .background(Color.white.opacity(0.1))
                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                                
                                Text("We'll use this name throughout the app to remind you who is standing with you.")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                    .padding()
                    .glassCard(cornerRadius: 16)
                    
                    // MARK: - Privacy Controls
                    if syncEnabled {
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Privacy Controls")
                                .font(.headline)
                            
                            Toggle(isOn: $shareExamens) {
                                Text("Share Examen Details")
                            }
                            .tint(.blue)
                            Text("When ON, your \(accountabilityTerm) can read the written reflections of your Daily Examens.")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            
                            Divider().background(Color.white.opacity(0.1))
                            
                            Toggle(isOn: $shareUrges) {
                                Text("Share Urge Log Details")
                            }
                            .tint(.blue)
                            Text("When ON, they can see exactly what triggers you faced and the tools you used to fight them off.")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            
                            Divider().background(Color.white.opacity(0.1))
                            
                            Toggle(isOn: $shareRelapses) {
                                Text("Share Relapse Reflections")
                            }
                            .tint(.blue)
                            Text("Note: Your \(accountabilityTerm) will always see your current \"Days of Purity\" count. Turning this ON allows them to read your private \"Begin Again\" recovery notes when a reset occurs.")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .padding()
                        .glassCard(cornerRadius: 16)
                        
                        // MARK: - Share Link
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Share Link")
                                .font(.headline)
                            
                            if let link = shareLink, let url = URL(string: link) {
                                ShareLink(item: url) {
                                    Label("Share my progress link", systemImage: "square.and.arrow.up")
                                        .font(.headline)
                                        .frame(maxWidth: .infinity)
                                        .padding()
                                        .background(Color.blue)
                                        .foregroundStyle(.white)
                                        .clipShape(RoundedRectangle(cornerRadius: 12))
                                        .shadow(color: .blue.opacity(0.3), radius: 5, y: 2)
                                }
                                
                                Button {
                                    regenerateLink()
                                } label: {
                                    Label("Generate a new link", systemImage: "arrow.triangle.2.circlepath")
                                        .font(.subheadline)
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 8)
                                        .foregroundStyle(.secondary)
                                }
                                
                                Divider().background(Color.white.opacity(0.1))
                                
                                NavigationLink(destination: PartnersView()) {
                                    HStack {
                                        Text("Walking with \(partnersLabel)")
                                        Spacer()
                                        Image(systemName: "chevron.right")
                                            .foregroundStyle(.secondary)
                                            .font(.footnote)
                                    }
                                    .font(.headline)
                                    .padding()
                                    .background(Color.white.opacity(0.1))
                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                                }
                                .foregroundStyle(.white)
                                
                            } else {
                                Button {
                                    generateShareLink()
                                } label: {
                                    Label("Generate Link", systemImage: "link")
                                        .frame(maxWidth: .infinity)
                                        .padding()
                                        .background(Color.blue)
                                        .foregroundStyle(.white)
                                        .clipShape(RoundedRectangle(cornerRadius: 12))
                                }
                                .disabled(isGeneratingLink)
                            }
                        }
                        .padding()
                        .glassCard(cornerRadius: 16)
                    }
                    
                    // MARK: - Cloud Backup
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Secure Your Journey (Cloud Backup)")
                            .font(.headline)
                        
                        Button {
                            pushFullData()
                        } label: {
                            Label("Back up my journey", systemImage: "icloud.and.arrow.up.fill")
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .disabled(isSyncing)
                        
                        Text("We'll save a snapshot of your progress to the secure cloud.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        
                        Divider().background(Color.white.opacity(0.1))
                        
                        Button {
                            pullFullData()
                        } label: {
                            Label("Restore from backup", systemImage: "arrow.clockwise.icloud.fill")
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .disabled(isSyncing)
                        
                        Text("Retrieve your previous progress. This will replace your current device data with your last saved backup.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        
                        if let err = syncError {
                            Text(err)
                                .foregroundStyle(err.contains("successful") ? .green : .red)
                                .font(.caption)
                        }
                    }
                    .padding()
                    .glassCard(cornerRadius: 16)
                    
                    // MARK: - Account Access
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Account")
                            .font(.headline)
                        
                        if isLoggedIn {
                            Button {
                                KeychainHelper.delete(forKey: KeychainHelper.authTokenKey)
                                isLoggedIn = false
                            } label: {
                                Text("Sign Out")
                                    .foregroundStyle(.indigo.opacity(0.8))
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }
                        } else {
                            Button {
                                showAuth = true
                            } label: {
                                Label("Create Account / Log In", systemImage: "person.crop.circle.badge.plus")
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }
                            .sheet(isPresented: $showAuth) {
                                CloudAuthView(isLoggedIn: $isLoggedIn)
                            }
                        }
                    }
                    .padding()
                    .glassCard(cornerRadius: 16)
                }
                .padding()
            }
        }
        .navigationTitle(accountabilityTerm)
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            CloudSyncService.baseURL = "https://purity-helper-api.onrender.com"
            isLoggedIn = KeychainHelper.load(forKey: KeychainHelper.authTokenKey) != nil
            if syncEnabled {
                generateShareLink()
            }
        }
    }

    private func pushFullData() {
        CloudSyncService.baseURL = "https://purity-helper-api.onrender.com"
        isSyncing = true
        syncError = nil
        do {
            let engine = FullSyncEngine(context: modelContext)
            var fullModels = try engine.exportFullData()
            
            // Apply Privacy Controls
            if !shareExamens {
                fullModels.examenEntries = []
            }
            if !shareUrges {
                fullModels.urgeLogs = []
            }
            if !shareRelapses {
                fullModels.resetRecords = []
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
        CloudSyncService.baseURL = "https://purity-helper-api.onrender.com"
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
        CloudSyncService.baseURL = "https://purity-helper-api.onrender.com"
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
