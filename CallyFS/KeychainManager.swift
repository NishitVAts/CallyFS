//
//  KeychainManager.swift
//  CallyFS
//

import Foundation
import Security

class KeychainManager {
    static let shared = KeychainManager()
    
    private init() {}
    
    // MARK: - Generic Methods
    
    func save(key: String, data: Data) -> Bool {
        let query = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        ] as [String: Any]
        
        // Delete any existing item first
        delete(key: key)
        
        let status = SecItemAdd(query as CFDictionary, nil)
        return status == errSecSuccess
    }
    
    func read(key: String) -> Data? {
        let query = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ] as [String: Any]
        
        var dataTypeRef: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &dataTypeRef)
        
        if status == errSecSuccess {
            return dataTypeRef as? Data
        }
        
        return nil
    }
    
    func delete(key: String) -> Bool {
        let query = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key
        ] as [String: Any]
        
        let status = SecItemDelete(query as CFDictionary)
        return status == errSecSuccess || status == errSecItemNotFound
    }
    
    // MARK: - Convenience Methods for Strings
    
    func saveString(key: String, string: String) -> Bool {
        guard let data = string.data(using: .utf8) else { return false }
        return save(key: key, data: data)
    }
    
    func readString(key: String) -> String? {
        guard let data = read(key: key) else { return nil }
        return String(data: data, encoding: .utf8)
    }
    
    // MARK: - API Key Specific Methods
    
    private let apiKeyKey = "openrouter_api_key"
    
    func saveAPIKey(_ apiKey: String) -> Bool {
        return saveString(key: apiKeyKey, string: apiKey)
    }
    
    func getAPIKey() -> String? {
        return readString(key: apiKeyKey)
    }
    
    func deleteAPIKey() -> Bool {
        return delete(key: apiKeyKey)
    }
    
    func hasAPIKey() -> Bool {
        return getAPIKey() != nil
    }
}

// MARK: - API Key Manager Wrapper

class APIKeyManager {
    static let shared = APIKeyManager()
    
    private let keychain = KeychainManager.shared
    private let hasKeyFlagKey = "has_api_key_flag"
    
    private init() {}
    
    var hasAPIKey: Bool {
        get { UserDefaults.standard.bool(forKey: hasKeyFlagKey) }
        set { UserDefaults.standard.set(newValue, forKey: hasKeyFlagKey) }
    }
    
    func saveAPIKey(_ key: String) -> Bool {
        let success = keychain.saveAPIKey(key)
        if success {
            hasAPIKey = true
            print("✅ API key saved to Keychain")
        } else {
            print("❌ Failed to save API key to Keychain")
        }
        return success
    }
    
    func getAPIKey() -> String? {
        guard hasAPIKey else { return nil }
        let key = keychain.getAPIKey()
        if key == nil {
            print("⚠️ API key flag set but key not found in Keychain")
            hasAPIKey = false
        }
        return key
    }
    
    func deleteAPIKey() {
        let success = keychain.deleteAPIKey()
        hasAPIKey = false
        print(success ? "✅ API key deleted from Keychain" : "⚠️ Failed to delete API key from Keychain")
    }
    
    func validateAPIKey(_ key: String) -> Bool {
        // Basic validation for OpenRouter API keys
        let pattern = "^sk-or-v1-[a-zA-Z0-9]{48}$"
        let regex = try? NSRegularExpression(pattern: pattern)
        let range = NSRange(location: 0, length: key.utf16.count)
        return regex?.firstMatch(in: key, options: [], range: range) != nil
    }
}
