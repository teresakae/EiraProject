import Foundation
import CryptoKit
import Security

enum DeviceKeyStore {
    private static func query(_ account: String) -> [String: Any] {
        [kSecClass as String: kSecClassGenericPassword,
         kSecAttrService as String: "org.eira.app.private-records",
         kSecAttrAccount as String: account,
         kSecAttrSynchronizable as String: false]
    }

    static func save(_ key: SymmetricKey, account: String) throws {
        var bytes = key.withUnsafeBytes { Data($0) }
        defer { bytes.resetBytes(in: 0..<bytes.count) }
        let attributes: [String: Any] = [
            kSecValueData as String: bytes,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        ]
        var status = SecItemUpdate(query(account) as CFDictionary, attributes as CFDictionary)
        if status == errSecItemNotFound {
            status = SecItemAdd(query(account).merging(attributes) { _, new in new } as CFDictionary, nil)
        }
        guard status == errSecSuccess else { throw StoreError.keychain(status) }
    }

    static func load(account: String) throws -> SymmetricKey {
        var request = query(account)
        request[kSecReturnData as String] = true
        request[kSecMatchLimit as String] = kSecMatchLimitOne
        var result: CFTypeRef?
        let status = SecItemCopyMatching(request as CFDictionary, &result)
        guard status == errSecSuccess else { throw StoreError.keychain(status) }
        guard var bytes = result as? Data, bytes.count == 32 else { throw StoreError.encryption }
        defer { bytes.resetBytes(in: 0..<bytes.count) }
        return SymmetricKey(data: bytes)
    }

    static func delete(account: String) throws {
        let status = SecItemDelete(query(account) as CFDictionary)
        guard status == errSecSuccess || status == errSecItemNotFound else { throw StoreError.keychain(status) }
    }
}
