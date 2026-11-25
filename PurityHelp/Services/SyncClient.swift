//
//  SyncClient.swift
//

import Foundation

struct SyncFailure: LocalizedError {
    var message: String
    var status: Int
    var expected: Int64?
    var errorDescription: String? { message }
}

enum SyncClient {
    static func post(base: String, path: String, token: String, body: [String: Any]) async throws -> [String: Any] {
        guard let url = endpoint(base, path) else { throw SyncFailure(message: "The server address is not a URL.", status: 0) }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        if !token.isEmpty { request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization") }
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        let (data, response) = try await URLSession.shared.data(for: request)
        return try decode(data, response)
    }

    static func endpoint(_ base: String, _ path: String) -> URL? {
        var root = base.trimmingCharacters(in: .whitespacesAndNewlines)
        while root.hasSuffix("/") { root.removeLast() }
        return URL(string: root + path)
    }

    private static func decode(_ data: Data, _ response: URLResponse) throws -> [String: Any] {
        let status = (response as? HTTPURLResponse)?.statusCode ?? 0
        let json = (try? JSONSerialization.jsonObject(with: data)) as? [String: Any] ?? [:]
        guard (200...299).contains(status) else {
            let message = json["error"] as? String ?? "The server returned \(status)."
            let expected = (json["expected"] as? NSNumber)?.int64Value
            throw SyncFailure(message: message, status: status, expected: expected)
        }
        return json
    }
}
