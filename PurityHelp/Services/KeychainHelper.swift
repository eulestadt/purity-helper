//
//  KeychainHelper.swift
//  PurityHelp
//
//  Store auth token and device ID in Keychain (not UserDefaults).
//

import Foundation
import Security

enum KeychainHelper {
    private static let service = "com.purityhelp.app"

    static func save(_ value: String, forKey key: String) {
        guard let data = value.data(using: .utf8) else { return }
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
            kSecValueData as String: data
        ]
        SecItemDelete(query as CFDictionary)
        let status = SecItemAdd(query as CFDictionary, nil)
        
        // Fallback to UserDefaults if Keychain fails (common in Simulator without entitlements)
        if status != errSecSuccess {
            UserDefaults.standard.set(value, forKey: "fallback_\(key)")
        } else {
            UserDefaults.standard.removeObject(forKey: "fallback_\(key)")
        }
    }

    static func load(forKey key: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        if status == errSecSuccess, let data = result as? Data, let str = String(data: data, encoding: .utf8) {
            return str
        }
        
        // Fallback wrapper
        return UserDefaults.standard.string(forKey: "fallback_\(key)")
    }

    static func delete(forKey key: String) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key
        ]
        SecItemDelete(query as CFDictionary)
        UserDefaults.standard.removeObject(forKey: "fallback_\(key)")
    }

    static let authTokenKey = "authToken"
    static let deviceIdKey = "deviceId"
}
