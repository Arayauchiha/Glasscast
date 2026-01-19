//
//  KeychainHelper.swift
//  Glasscast
//
//  Created by Aryan Singh on 20/01/26.
//

import Foundation

enum KeychainHelper {

    /// Stores a string value in the Keychain for a given key.
    ///
    /// - Parameters:
    ///   - value: The string value to store.
    ///   - key: The unique key to associate with the value.
    /// - Returns: `true` if the value was successfully added, `false` otherwise.
    ///
    /// Notes:
    /// - Any existing value for the same key will be deleted before adding the new one.
    /// - Uses UTF-8 encoding to convert the string into `Data`.
    @discardableResult
    public static func set(_ value: String, forKey key: String) -> Bool {
        guard let data = value.data(using: .utf8) else { return false }

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecValueData as String: data
        ]

        // Delete any existing item for this key
        SecItemDelete(query as CFDictionary)

        // Add the new item
        return SecItemAdd(query as CFDictionary, nil) == errSecSuccess
    }

    /// Retrieves a string value from the Keychain for a given key.
    ///
    /// - Parameter key: The key associated with the stored value.
    /// - Returns: The string value if it exists, otherwise `nil`.
    ///
    /// Notes:
    /// - Returns `nil` if the key does not exist or if the data cannot be converted to a string.
    @discardableResult
    public static func get(_ key: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        var dataTypeRef: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &dataTypeRef)

        if status == errSecSuccess, let data = dataTypeRef as? Data {
            return String(data: data, encoding: .utf8)
        }
        return nil
    }

    /// Removes a value from the Keychain for a given key.
    ///
    /// - Parameter key: The key associated with the value to remove.
    /// - Returns: `true` if the item was successfully removed, `false` otherwise.
    @discardableResult
    public static func remove(_ key: String) -> Bool {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key
        ]
        return SecItemDelete(query as CFDictionary) == errSecSuccess
    }
}
