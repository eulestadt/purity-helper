//
//  PartnersView.swift
//  PurityHelp
//
//  Accountability partners: add via link, view read-only progress summary.
//

import SwiftUI

struct SavedPartner: Identifiable, Codable {
    var id: String { token }
    let token: String
    var name: String?
}

struct PartnerSummaryItem: Identifiable {
    let id: String
    let partner: SavedPartner
    let payload: SharePayload
}

struct PartnersView: View {
    @AppStorage("savedPartners") private var partnersData: Data = Data()
    @State private var partners: [SavedPartner] = []
    @State private var showAddPartner = false
    @State private var pasteURL = ""
    @State private var addError: String?
    @State private var selectedSummary: PartnerSummaryItem?
    @State private var loadingToken: String?

    var body: some View {
        List {
            Section {
                ForEach(partners) { p in
                    Button {
                        fetchSummary(p)
                    } label: {
                        HStack {
                            Text(p.name ?? "Partner")
                                .foregroundStyle(.primary)
                            Spacer()
                            if loadingToken == p.token {
                                ProgressView()
                            }
                        }
                    }
                    .disabled(loadingToken != nil)
                }
                .onDelete(perform: deletePartners)
            } header: {
                Text("People whose progress you follow")
            }

            Section {
                Button("Add partner") {
                    showAddPartner = true
                    pasteURL = ""
                    addError = nil
                }
            }
        }
        .navigationTitle("Partners")
        .onAppear {
            loadPartners()
        }
        .sheet(isPresented: $showAddPartner) {
            addPartnerSheet
        }
        .sheet(item: $selectedSummary) { item in
            NavigationStack {
                PartnerSummaryView(payload: item.payload, partnerName: item.partner.name)
                    .toolbar {
                        ToolbarItem(placement: .confirmationAction) {
                            Button("Done") { selectedSummary = nil }
                        }
                    }
            }
        }
    }

    private var addPartnerSheet: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Paste link for your partner", text: $pasteURL)
                        .textInputAutocapitalization(.never)
                        .keyboardType(.URL)
                } footer: {
                    Text("Paste the link they shared with you. You can open it in the app or in a browser.")
                }
                if let err = addError {
                    Section {
                        Text(err)
                            .foregroundStyle(.red)
                    }
                }
            }
            .navigationTitle("Add partner")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(action: { showAddPartner = false }) {
                        Image(systemName: "xmark").font(.headline).padding(6).background(Color(uiColor: .tertiarySystemFill), in: Circle())
                            
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        addPartnerFromURL()
                    }
                    .disabled(pasteURL.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }

    private func addPartnerFromURL() {
        let trimmed = pasteURL.trimmingCharacters(in: .whitespaces)
        guard let token = extractShareToken(from: trimmed) else {
            addError = "Could not find a valid share link. Paste the full link (e.g. https://.../share/...)."
            return
        }
        if partners.contains(where: { $0.token == token }) {
            addError = "This partner is already added."
            return
        }
        partners.append(SavedPartner(token: token, name: nil))
        savePartners()
        showAddPartner = false
    }

    private func extractShareToken(from urlString: String) -> String? {
        if urlString.contains("/share/") {
            let parts = urlString.split(separator: "/")
            if let idx = parts.firstIndex(of: "share"), idx + 1 < parts.count {
                let token = String(parts[idx + 1])
                if token.count >= 30, token.contains("-") { return token }
            }
        }
        if urlString.allSatisfy({ $0.isHexDigit || $0 == "-" }) && urlString.contains("-") {
            return urlString
        }
        return nil
    }

    private func fetchSummary(_ partner: SavedPartner) {
        loadingToken = partner.token
        CloudSyncService.fetchShareSummary(token: partner.token) { result in
            loadingToken = nil
            switch result {
            case .success(let payload):
                selectedSummary = PartnerSummaryItem(id: partner.token, partner: partner, payload: payload)
            case .failure:
                break
            }
        }
    }

    private func loadPartners() {
        if let decoded = try? JSONDecoder().decode([SavedPartner].self, from: partnersData) {
            partners = decoded
        } else {
            partners = []
        }
    }

    private func savePartners() {
        partnersData = (try? JSONEncoder().encode(partners)) ?? Data()
    }

    private func deletePartners(at offsets: IndexSet) {
        partners.remove(atOffsets: offsets)
        savePartners()
    }
}

struct PartnerSummaryView: View {
    let payload: SharePayload
    let partnerName: String?

    var body: some View {
        List {
            Section("Days of purity") {
                LabeledContent("Pornography", value: "\(payload.pornographyDays ?? 0) days")
                LabeledContent("Masturbation", value: "\(payload.masturbationDays ?? 0) days")
                if let pt = payload.pureThoughtsDays {
                    LabeledContent("Guarding thoughts", value: "\(pt) days")
                }
            }
            Section("Urge moments") {
                Text("\(payload.urgeMomentsCount ?? 0) logged")
            }
            if let h = payload.hoursReclaimed, h > 0 {
                Section("Hours reclaimed") {
                    Text("\(h) hours")
                }
            }
            if let updated = payload.lastUpdated {
                Section {
                    Text("Last updated: \(updated)")
                        .font(.caption)
                        
                }
            }
        }
        .navigationTitle(partnerName ?? "Progress summary")
    }
}

#Preview {
    NavigationStack {
        PartnersView()
    }
}
