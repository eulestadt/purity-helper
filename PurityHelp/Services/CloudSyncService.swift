//
//  CloudSyncService.swift
//  PurityHelp
//
//  Optional sync and share: POST /sync, GET /me, POST /share. Token in Keychain.
//

import Foundation

struct SharePayload: Codable {
    var pornographyDays: Int?
    var masturbationDays: Int?
    var pureThoughtsDays: Int?
    var urgeMomentsCount: Int?
    var hoursReclaimed: Int?
    var lastUpdated: String?
    var models: FullSyncPayload?
}

struct CloudSyncService {
    static let baseURLKey = "cloudSyncBaseURL"

    static var baseURL: String? {
        get { UserDefaults.standard.string(forKey: baseURLKey)?.trimmingCharacters(in: .whitespacesAndNewlines) }
        set { UserDefaults.standard.set(newValue, forKey: baseURLKey) }
    }

    static func buildPayload(
        pornographyDays: Int,
        masturbationDays: Int,
        pureThoughtsDays: Int,
        pureThoughtsEnabled: Bool,
        urgeCount: Int,
        hoursReclaimed: Int?,
        fullModels: FullSyncPayload? = nil
    ) -> [String: Any] {
        var p: [String: Any] = [
            "pornographyDays": pornographyDays,
            "masturbationDays": masturbationDays,
            "urgeMomentsCount": urgeCount
        ]
        if pureThoughtsEnabled { p["pureThoughtsDays"] = pureThoughtsDays }
        if let h = hoursReclaimed, h > 0 { p["hoursReclaimed"] = h }
        if let fullModels = fullModels,
           let encoded = try? JSONEncoder().encode(fullModels),
           let dict = try? JSONSerialization.jsonObject(with: encoded) as? [String: Any] {
            p["models"] = dict
        }
        return p
    }

    static func sync(
        payload: [String: Any],
        completion: @escaping (Result<Void, Error>) -> Void
    ) {
        guard let base = baseURL, !base.isEmpty, let url = URL(string: base.trimmingCharacters(in: .whitespacesAndNewlines) + "/sync") else {
            completion(.failure(NSError(domain: "CloudSync", code: -1, userInfo: [NSLocalizedDescriptionKey: "Base URL not set"])))
            return
        }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        var body = payload
        body["lastUpdated"] = ISO8601DateFormatter().string(from: Date())
        if let token = KeychainHelper.load(forKey: KeychainHelper.authTokenKey) {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        } else {
            var deviceId = KeychainHelper.load(forKey: KeychainHelper.deviceIdKey)
            if deviceId == nil {
                deviceId = UUID().uuidString
                KeychainHelper.save(deviceId!, forKey: KeychainHelper.deviceIdKey)
            }
            body["deviceId"] = deviceId
        }
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)

        URLSession.shared.dataTask(with: request) { _, response, error in
            if let error = error {
                DispatchQueue.main.async { completion(.failure(error)) }
                return
            }
            let code = (response as? HTTPURLResponse)?.statusCode ?? 0
            if code >= 200 && code < 300 {
                DispatchQueue.main.async { completion(.success(())) }
            } else {
                DispatchQueue.main.async { completion(.failure(NSError(domain: "CloudSync", code: code, userInfo: [NSLocalizedDescriptionKey: "Sync failed"]))) }
            }
        }.resume()
    }

    static func fetchMe(completion: @escaping (Result<SharePayload, Error>) -> Void) {
        guard let token = KeychainHelper.load(forKey: KeychainHelper.authTokenKey),
              let base = baseURL, !base.isEmpty,
              let url = URL(string: base.trimmingCharacters(in: .whitespacesAndNewlines) + "/me") else {
            completion(.failure(NSError(domain: "CloudSync", code: -1, userInfo: [NSLocalizedDescriptionKey: "Not logged in or base URL not set"])))
            return
        }
        var request = URLRequest(url: url)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                DispatchQueue.main.async { completion(.failure(error)) }
                return
            }
            let code = (response as? HTTPURLResponse)?.statusCode ?? 0
            guard code >= 200 && code < 300, let data = data else {
                DispatchQueue.main.async { completion(.failure(NSError(domain: "CloudSync", code: code, userInfo: [NSLocalizedDescriptionKey: "Fetch failed"]))) }
                return
            }
            do {
                let decoded = try JSONDecoder().decode(MeResponse.self, from: data)
                DispatchQueue.main.async { completion(.success(decoded.payload)) }
            } catch {
                DispatchQueue.main.async { completion(.failure(error)) }
            }
        }.resume()
    }

    private struct MeResponse: Codable {
        let payload: SharePayload
    }

    static func createShareLink(completion: @escaping (Result<String, Error>) -> Void) {
        guard let base = baseURL, !base.isEmpty else {
            completion(.failure(NSError(domain: "CloudSync", code: -1, userInfo: [NSLocalizedDescriptionKey: "Base URL not set"])))
            return
        }
        let urlString = base.trimmingCharacters(in: .whitespacesAndNewlines) + "/share"
        guard let url = URL(string: urlString) else {
            completion(.failure(NSError(domain: "CloudSync", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])))
            return
        }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        if let token = KeychainHelper.load(forKey: KeychainHelper.authTokenKey) {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        } else if let deviceId = KeychainHelper.load(forKey: KeychainHelper.deviceIdKey) {
            request.httpBody = try? JSONSerialization.data(withJSONObject: ["deviceId": deviceId])
        } else {
            completion(.failure(NSError(domain: "CloudSync", code: -1, userInfo: [NSLocalizedDescriptionKey: "Sync first to get a share link"])))
            return
        }

        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                DispatchQueue.main.async { completion(.failure(error)) }
                return
            }
            let code = (response as? HTTPURLResponse)?.statusCode ?? 0
            guard code >= 200 && code < 300, let data = data else {
                DispatchQueue.main.async { completion(.failure(NSError(domain: "CloudSync", code: code, userInfo: [NSLocalizedDescriptionKey: "Could not create link"]))) }
                return
            }
            struct ShareResponse: Codable {
                let token: String
                let link: String
            }
            if let decoded = try? JSONDecoder().decode(ShareResponse.self, from: data) {
                DispatchQueue.main.async { completion(.success(decoded.link)) }
            } else {
                DispatchQueue.main.async { completion(.failure(NSError(domain: "CloudSync", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid response"]))) }
            }
        }.resume()
    }

    static func fetchShareSummary(token: String, completion: @escaping (Result<SharePayload, Error>) -> Void) {
        guard let base = baseURL, !base.isEmpty else {
            completion(.failure(NSError(domain: "CloudSync", code: -1, userInfo: [NSLocalizedDescriptionKey: "Base URL not set"])))
            return
        }
        let urlString = base.trimmingCharacters(in: .whitespacesAndNewlines) + "/share/" + token
        guard let url = URL(string: urlString) else {
            completion(.failure(NSError(domain: "CloudSync", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])))
            return
        }
        var request = URLRequest(url: url)
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                DispatchQueue.main.async { completion(.failure(error)) }
                return
            }
            let code = (response as? HTTPURLResponse)?.statusCode ?? 0
            guard code >= 200 && code < 300, let data = data else {
                DispatchQueue.main.async { completion(.failure(NSError(domain: "CloudSync", code: code, userInfo: [NSLocalizedDescriptionKey: "Could not load summary"]))) }
                return
            }
            do {
                let decoded = try JSONDecoder().decode(SharePayload.self, from: data)
                DispatchQueue.main.async { completion(.success(decoded)) }
            } catch {
                DispatchQueue.main.async { completion(.failure(error)) }
            }
        }.resume()
    }
}
