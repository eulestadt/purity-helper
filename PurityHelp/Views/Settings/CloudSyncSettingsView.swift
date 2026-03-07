//
//  CloudSyncSettingsView.swift
//  PurityHelp
//
//  Shared Walk settings: privacy controls & share link for your accountability partner.
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

    @AppStorage("shareExamens") private var shareExamens = false
    @AppStorage("shareUrges") private var shareUrges = true
    @AppStorage("shareRelapses") private var shareRelapses = false
    @State private var shareLink: String?
    @State private var isGeneratingLink = false

    private var streakRecord: StreakRecord? { streakRecords.first }

    var body: some View {
        ZStack {
            PurityBackground().ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 24) {
                    
                    // MARK: - Shared Walk Setup
                    VStack(alignment: .leading, spacing: 16) {
                        Toggle(isOn: $syncEnabled) {
                            Text("Enable Shared Walk")
                                .font(.headline)
                        }
                        .tint(.blue)
                        
                        Text("Invite someone you trust to walk this path with you. They will be able to view a secure summary of your journey.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
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
                            .onChange(of: shareExamens) { _, _ in
                                AutoSyncManager.shared.performBackgroundSync(modelContext: modelContext)
                            }
                            Text("When ON, your \(accountabilityTerm) can read the written reflections of your Daily Examens.")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            
                            Divider().background(Color.white.opacity(0.1))
                            
                            Toggle(isOn: $shareUrges) {
                                Text("Share Urge Log Details")
                            }
                            .tint(.blue)
                            .onChange(of: shareUrges) { _, _ in
                                AutoSyncManager.shared.performBackgroundSync(modelContext: modelContext)
                            }
                            Text("When ON, they can see exactly what triggers you faced and the tools you used to fight them off.")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            
                            Divider().background(Color.white.opacity(0.1))
                            
                            Toggle(isOn: $shareRelapses) {
                                Text("Share Relapse Reflections")
                            }
                            .tint(.blue)
                            .onChange(of: shareRelapses) { _, _ in
                                AutoSyncManager.shared.performBackgroundSync(modelContext: modelContext)
                            }
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
                    } // end if syncEnabled
                } // end VStack
                .padding()
            } // end ScrollView
        } // end ZStack
        .navigationTitle(accountabilityTerm)
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            if syncEnabled {
                generateShareLink()
            }
        }
    }

    // MARK: - Share Link Actions

    private func generateShareLink() {
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
        let base = CloudSyncService.baseEndpoint
        loading = true
        error = nil
        let path = isSignUp ? "/auth/signup" : "/auth/login"
        guard let url = URL(string: base + path) else {
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
                NotificationCenter.default.post(name: .userDidLogin, object: nil)
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
