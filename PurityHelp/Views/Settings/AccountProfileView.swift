//
//  AccountProfileView.swift
//  PurityHelp
//
//  Manage display name, accountability term, and account sign in/out.
//

import SwiftUI
import SwiftData

struct AccountProfileView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @AppStorage("accountabilityTerm") private var accountabilityTerm = "Brotherhood"
    @AppStorage("partnerName") private var partnerName = ""

    @State private var showAuth = false
    @State private var isLoggedIn = KeychainHelper.load(forKey: KeychainHelper.authTokenKey) != nil

    // Account Management States
    @State private var userEmail: String?
    @State private var loadingEmail = false
    @State private var showChangePassword = false

    // OTP flow
    @State private var otpSent = false
    @State private var otpCode = ""
    @State private var newPassword = ""
    @State private var isSendingCode = false
    @State private var isConfirming = false
    @State private var otpError: String?
    @State private var changePasswordSuccess = false

    var body: some View {
        NavigationStack {
            ZStack {
                PurityBackground().ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 24) {

                        // MARK: - Profile
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Your Profile")
                                .font(.headline)

                            TextField("Your name or nickname", text: $partnerName)
                                .textInputAutocapitalization(.words)
                                .padding()
                                .background(Color.white.opacity(0.1))
                                .clipShape(RoundedRectangle(cornerRadius: 12))

                            Text("This name is used across the app and on your shared journey page.")
                                .font(.caption)
                                .foregroundStyle(.secondary)

                            Divider().background(Color.white.opacity(0.1))

                            Text("Accountability Term")
                                .font(.subheadline)

                            Picker("Accountability Type", selection: $accountabilityTerm) {
                                Text("Brotherhood").tag("Brotherhood")
                                Text("Sisterhood").tag("Sisterhood")
                                Text("Walk Together").tag("Walk Together")
                            }
                            .pickerStyle(.segmented)
                        }
                        .padding()
                        .glassCard(cornerRadius: 16)

                        // MARK: - Account
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Account")
                                .font(.headline)

                            if isLoggedIn {
                                if let email = userEmail {
                                    Label(email, systemImage: "envelope")
                                        .font(.subheadline)
                                        .foregroundStyle(.secondary)
                                } else if loadingEmail {
                                    ProgressView()
                                }
                                
                                Button {
                                    showChangePassword = true
                                } label: {
                                    Label("Change Password", systemImage: "key")
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                }
                                .sheet(isPresented: $showChangePassword) {
                                    changePasswordSheet
                                }
                                
                                Divider().background(Color.white.opacity(0.1))

                                Button {
                                    KeychainHelper.delete(forKey: KeychainHelper.authTokenKey)
                                    isLoggedIn = false
                                    userEmail = nil
                                } label: {
                                    Text("Sign Out")
                                        .foregroundStyle(.red.opacity(0.85))
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

                                Text("Sign in to enable cross-device sync.")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .padding()
                        .glassCard(cornerRadius: 16)
                    }
                    .padding()
                }
            }
            .navigationTitle("Account")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
            .onAppear {
                if isLoggedIn && userEmail == nil {
                    fetchUserEmail()
                }
            }
            .onChange(of: isLoggedIn) { _, newValue in
                if newValue {
                    fetchUserEmail()
                } else {
                    userEmail = nil
                }
            }
        }
    }

    // MARK: - Change Password Sheet (OTP Flow)
    private var changePasswordSheet: some View {
        NavigationStack {
            Form {
                if changePasswordSuccess {
                    Section {
                        Label("Password changed successfully.", systemImage: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                    }
                    Section {
                        Button("Done") {
                            showChangePassword = false
                            changePasswordSuccess = false
                        }
                    }

                } else if !otpSent {
                    // Step 1: send code
                    Section {
                        Text("We'll email a 6-digit code to:")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        if let email = userEmail {
                            Text(email)
                                .font(.subheadline)
                                .fontWeight(.medium)
                        }
                    }
                    if let err = otpError {
                        Section {
                            Text(err).foregroundStyle(.red)
                        }
                    }
                    Section {
                        Button {
                            requestOTP()
                        } label: {
                            if isSendingCode {
                                ProgressView()
                            } else {
                                Text("Send Code")
                            }
                        }
                        .disabled(isSendingCode)
                    }

                } else {
                    // Step 2: enter code + new password
                    Section(header: Text("Check your email")) {
                        TextField("6-digit code", text: $otpCode)
                            .keyboardType(.numberPad)
                        SecureField("New Password (min 8 chars)", text: $newPassword)
                    }
                    if let err = otpError {
                        Section {
                            Text(err).foregroundStyle(.red)
                        }
                    }
                    Section {
                        Button {
                            confirmOTP()
                        } label: {
                            if isConfirming {
                                ProgressView()
                            } else {
                                Text("Change Password")
                            }
                        }
                        .disabled(isConfirming || otpCode.count != 6 || newPassword.count < 8)

                        Button("Resend Code") {
                            otpSent = false
                            otpCode = ""
                            otpError = nil
                        }
                        .foregroundStyle(.secondary)
                    }
                }
            }
            .navigationTitle("Change Password")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        showChangePassword = false
                        resetOTPState()
                    }
                }
            }
        }
    }

    // MARK: - API Calls
    private func fetchUserEmail() {
        guard let token = KeychainHelper.load(forKey: KeychainHelper.authTokenKey) else { return }
        guard let url = URL(string: CloudSyncService.baseEndpoint + "/auth/me") else { return }
        loadingEmail = true
        var request = URLRequest(url: url)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        URLSession.shared.dataTask(with: request) { data, response, _ in
            DispatchQueue.main.async {
                loadingEmail = false
                guard let code = (response as? HTTPURLResponse)?.statusCode, code == 200,
                      let data = data,
                      let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                      let email = json["email"] as? String else { return }
                self.userEmail = email
            }
        }.resume()
    }

    private func requestOTP() {
        guard let token = KeychainHelper.load(forKey: KeychainHelper.authTokenKey),
              let url = URL(string: CloudSyncService.baseEndpoint + "/auth/request-reset") else { return }
        isSendingCode = true
        otpError = nil
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        URLSession.shared.dataTask(with: request) { data, response, _ in
            DispatchQueue.main.async {
                isSendingCode = false
                let statusCode = (response as? HTTPURLResponse)?.statusCode ?? 0
                if statusCode >= 200 && statusCode < 300 {
                    otpSent = true
                } else {
                    let msg = (data.flatMap { try? JSONSerialization.jsonObject(with: $0) as? [String: Any] })?["error"] as? String
                    otpError = msg ?? "Failed to send code. Try again."
                }
            }
        }.resume()
    }

    private func confirmOTP() {
        guard let token = KeychainHelper.load(forKey: KeychainHelper.authTokenKey),
              let url = URL(string: CloudSyncService.baseEndpoint + "/auth/confirm-reset") else { return }
        isConfirming = true
        otpError = nil
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.httpBody = try? JSONSerialization.data(withJSONObject: ["code": otpCode, "newPassword": newPassword])
        URLSession.shared.dataTask(with: request) { data, response, _ in
            DispatchQueue.main.async {
                isConfirming = false
                let statusCode = (response as? HTTPURLResponse)?.statusCode ?? 0
                if statusCode >= 200 && statusCode < 300 {
                    changePasswordSuccess = true
                    resetOTPState()
                } else {
                    let msg = (data.flatMap { try? JSONSerialization.jsonObject(with: $0) as? [String: Any] })?["error"] as? String
                    otpError = msg ?? "Incorrect or expired code."
                }
            }
        }.resume()
    }

    private func resetOTPState() {
        otpSent = false
        otpCode = ""
        newPassword = ""
        otpError = nil
    }
}

#Preview {
    AccountProfileView()
}
