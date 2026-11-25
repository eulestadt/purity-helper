//
//  AppStore.swift
//  Local journal plus the event-sync client.
//

import Foundation
import SwiftData

struct PendingMutation {
    var id: Int64
    var name: String
    var args: [String: Any]
}

@MainActor
@Observable
final class AppStore {
    private let context: ModelContext
    private var meta: SyncMeta?
    private var serverModels: [String: ServerDoc] = [:]
    private var server: [String: DocRecord] = [:]
    private var pending: [PendingMutation] = []

    var docs: [String: DocRecord] = [:]
    var baseURL: String = ""
    var email: String = ""
    var status: String = "On this device"
    var busy = false
    var shareLink: String = ""

    var token: String { KeychainHelper.load(forKey: KeychainHelper.authTokenKey) ?? "" }
    var isSignedIn: Bool { !token.isEmpty }

    init(context: ModelContext) {
        self.context = context
        load()
    }

    var derived: DerivedDay {
        DayDomain.derive(documents: Array(docs.values), today: DayDomain.todayString())
    }

    func put(key: String, value: [String: Any]) {
        enqueue(name: "put", args: ["key": key, "value": value])
    }

    func delete(key: String) {
        enqueue(name: "del", args: ["key": key])
    }

    func logEvent(_ fields: [String: Any]) {
        var value = fields
        let now = Date()
        value["day"] = DayDomain.todayString(now)
        value["at"] = ISO8601DateFormatter().string(from: now)
        let calendar = Calendar.current
        value["hour"] = calendar.component(.hour, from: now)
        value["weekday"] = calendar.component(.weekday, from: now) - 1
        put(key: "event/\(UUID().uuidString.lowercased())", value: value)
    }

    func updateProfile(_ change: (inout [String: Any]) -> Void) {
        var profile = docs["profile"]?.value ?? [:]
        change(&profile)
        put(key: "profile", value: profile)
    }

    func setBaseURL(_ value: String) {
        baseURL = value.trimmingCharacters(in: .whitespacesAndNewlines)
        meta?.baseURL = baseURL
        try? context.save()
    }

    func login(email: String, password: String, create: Bool) async {
        busy = true
        defer { busy = false }
        do {
            let path = create ? "/auth/signup" : "/auth/login"
            let json = try await SyncClient.post(base: baseURL, path: path, token: "", body: [
                "email": email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased(),
                "password": password
            ])
            guard let received = json["token"] as? String else {
                status = "The server did not return a token."
                return
            }
            KeychainHelper.save(received, forKey: KeychainHelper.authTokenKey)
            self.email = (json["email"] as? String) ?? email
            meta?.email = self.email
            try? context.save()
            await syncNow()
        } catch {
            status = error.localizedDescription
        }
    }

    func logout() {
        KeychainHelper.delete(forKey: KeychainHelper.authTokenKey)
        shareLink = ""
        status = "Signed out. This phone still holds the journal."
    }

    func syncNow() async {
        guard SyncClient.endpoint(baseURL, "/health") != nil else {
            status = "Add the Railway address in Settings."
            return
        }
        guard isSignedIn else {
            status = "Sign in to sync this journal."
            return
        }
        busy = true
        defer { busy = false }
        do {
            try await pull()
            if !pending.isEmpty {
                try await push()
                try await pull()
            }
            ensureProfile()
            if !pending.isEmpty {
                try await push()
                try await pull()
            }
            status = pending.isEmpty ? "Synced" : "Saved on this phone"
        } catch {
            if docs["profile"] == nil { ensureProfile() }
            status = error.localizedDescription
        }
    }

    func refreshShareLink(regenerate: Bool = false) async {
        guard isSignedIn else { return }
        do {
            let json = try await SyncClient.post(base: baseURL, path: "/share", token: token, body: ["regenerate": regenerate])
            shareLink = json["link"] as? String ?? ""
        } catch {
            status = error.localizedDescription
        }
    }

    private func load() {
        let metas = (try? context.fetch(FetchDescriptor<SyncMeta>())) ?? []
        if let existing = metas.first {
            meta = existing
            for extra in metas.dropFirst() { context.delete(extra) }
        } else {
            let created = SyncMeta(clientId: UUID().uuidString.lowercased().replacingOccurrences(of: "-", with: ""))
            context.insert(created)
            meta = created
        }
        baseURL = meta?.baseURL ?? ""
        email = meta?.email ?? ""

        let rows = (try? context.fetch(FetchDescriptor<ServerDoc>())) ?? []
        serverModels = [:]
        server = [:]
        for row in rows {
            if serverModels[row.key] != nil {
                context.delete(row)
                continue
            }
            serverModels[row.key] = row
            server[row.key] = record(from: row)
        }

        let outbox = ((try? context.fetch(FetchDescriptor<OutboxItem>())) ?? []).sorted { $0.mutationId < $1.mutationId }
        pending = outbox.compactMap { item in
            guard let data = item.argsJSON.data(using: .utf8),
                  let args = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else { return nil }
            return PendingMutation(id: item.mutationId, name: item.name, args: args)
        }
        let storedNext = meta?.nextMutationId ?? 1
        let pendingNext = (pending.map(\.id).max() ?? 0) + 1
        meta?.nextMutationId = max(storedNext, pendingNext)
        rebuild()
        if token.isEmpty {
            ensureProfile()
        }
        try? context.save()
    }

    private func ensureProfile() {
        if docs["profile"] == nil {
            put(key: "profile", value: [
                "journeyStart": DayDomain.todayString(),
                "hoursPerDay": 1,
                "mission": "",
                "shareRings": true,
                "shareStreaks": true,
                "shareMission": false,
                "shareRelapses": false,
                "shareUrges": false,
                "shareExamens": false
            ])
            return
        }
        if DayDomain.string(docs["profile"]?.value["journeyStart"]) == nil {
            updateProfile { profile in
                profile["journeyStart"] = DayDomain.todayString()
            }
        }
    }

    private func enqueue(name: String, args: [String: Any]) {
        guard let meta else { return }
        guard let data = try? JSONSerialization.data(withJSONObject: args),
              let json = String(data: data, encoding: .utf8) else {
            status = "Could not save that entry."
            return
        }
        let id = meta.nextMutationId
        meta.nextMutationId = id + 1
        let item = OutboxItem(mutationId: id, name: name, argsJSON: json)
        context.insert(item)
        pending.append(PendingMutation(id: id, name: name, args: args))
        apply(PendingMutation(id: id, name: name, args: args), to: &docs)
        try? context.save()
        status = isSignedIn ? "Saved. Will sync." : "Saved on this phone"
    }

    private func rebuild() {
        docs = server
        for mutation in pending {
            apply(mutation, to: &docs)
        }
    }

    private func apply(_ mutation: PendingMutation, to target: inout [String: DocRecord]) {
        let key = mutation.args["key"] as? String ?? ""
        guard !key.isEmpty else { return }
        if mutation.name == "del" {
            target[key] = DocRecord(key: key, value: [:], deleted: true)
        } else if let value = mutation.args["value"] as? [String: Any] {
            target[key] = DocRecord(key: key, value: value, deleted: false)
        }
    }

    private func pull() async throws {
        guard let meta else { return }
        let json = try await SyncClient.post(base: baseURL, path: "/sync/pull", token: token, body: [
            "clientId": meta.clientId,
            "cookie": NSNumber(value: meta.cookie)
        ])
        let ids = json["lastMutationIDs"] as? [String: Any] ?? [:]
        let acked = (ids[meta.clientId] as? NSNumber)?.int64Value ?? 0
        if acked > 0 {
            pending.removeAll { $0.id <= acked }
            let outbox = (try? context.fetch(FetchDescriptor<OutboxItem>())) ?? []
            for item in outbox where item.mutationId <= acked { context.delete(item) }
        }
        let patch = json["patch"] as? [[String: Any]] ?? []
        for op in patch {
            guard let key = op["key"] as? String else { continue }
            if op["op"] as? String == "del" {
                server[key] = DocRecord(key: key, value: [:], deleted: true)
                upsertServer(key: key, payload: "null", deleted: true)
            } else if let value = op["value"] as? [String: Any],
                      let data = try? JSONSerialization.data(withJSONObject: value),
                      let payload = String(data: data, encoding: .utf8) {
                server[key] = DocRecord(key: key, value: value, deleted: false)
                upsertServer(key: key, payload: payload, deleted: false)
            }
        }
        meta.cookie = (json["cookie"] as? NSNumber)?.int64Value ?? meta.cookie
        let highest = (pending.map(\.id).max() ?? 0) + 1
        if meta.nextMutationId < highest { meta.nextMutationId = highest }
        if meta.nextMutationId <= acked { meta.nextMutationId = acked + 1 }
        reconcileProfile()
        rebuild()
        try context.save()
    }

    /// A phone that started offline has a factory profile mutation. Replay it
    /// onto the server profile so an empty mission does not wipe a real one.
    private func reconcileProfile() {
        guard let serverRecord = server["profile"], !serverRecord.deleted else { return }
        let indexes = pending.indices.filter {
            pending[$0].name == "put" && (pending[$0].args["key"] as? String) == "profile"
        }
        guard !indexes.isEmpty else { return }
        var merged = serverRecord.value
        for index in indexes {
            guard let value = pending[index].args["value"] as? [String: Any] else { continue }
            for (key, field) in value where !isFactoryProfile(key, field) {
                merged[key] = field
            }
        }
        if DayDomain.string(merged["journeyStart"]) == nil {
            merged["journeyStart"] = DayDomain.todayString()
        }
        let outbox = (try? context.fetch(FetchDescriptor<OutboxItem>())) ?? []
        for index in indexes {
            pending[index].args["value"] = merged
            if let row = outbox.first(where: { $0.mutationId == pending[index].id }),
               let data = try? JSONSerialization.data(withJSONObject: pending[index].args),
               let json = String(data: data, encoding: .utf8) {
                row.argsJSON = json
            }
        }
    }

    private func isFactoryProfile(_ key: String, _ field: Any) -> Bool {
        switch key {
        case "journeyStart":
            return true
        case "mission":
            return ((field as? String) ?? "").isEmpty
        case "hoursPerDay":
            return DayDomain.double(field) == 1
        case "shareRings", "shareStreaks":
            return DayDomain.bool(field, default: true)
        case "shareMission", "shareRelapses", "shareUrges", "shareExamens":
            return !DayDomain.bool(field, default: false)
        default:
            return false
        }
    }

    private func push() async throws {
        guard let meta else { return }
        let mutations: [[String: Any]] = pending.map { mutation in
            ["id": NSNumber(value: mutation.id), "name": mutation.name, "args": mutation.args]
        }
        _ = try await SyncClient.post(base: baseURL, path: "/sync/push", token: token, body: [
            "clientId": meta.clientId,
            "mutations": mutations
        ])
    }

    private func upsertServer(key: String, payload: String, deleted: Bool) {
        if let model = serverModels[key] {
            model.payload = payload
            model.deleted = deleted
        } else {
            let model = ServerDoc(key: key, payload: payload, deleted: deleted)
            context.insert(model)
            serverModels[key] = model
        }
    }

    private func record(from row: ServerDoc) -> DocRecord {
        let value = row.payload.data(using: .utf8).flatMap { data in
            try? JSONSerialization.jsonObject(with: data) as? [String: Any]
        } ?? [:]
        return DocRecord(key: row.key, value: value, deleted: row.deleted)
    }
}
