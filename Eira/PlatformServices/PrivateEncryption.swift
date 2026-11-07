import Foundation
import CryptoKit
import CommonCrypto
import Security

enum PrivateEncryption {
    static let rounds: UInt32 = 600_000

    struct Envelope: Codable, Sendable {
        let version: Int
        let salt: Data
        let rounds: UInt32
        let wrappedKey: Data
        var ciphertext: Data
    }

    static func passwordKey(_ passphrase: String, salt: Data) throws -> SymmetricKey {
        var password = Array(passphrase.utf8)
        var derived = [UInt8](repeating: 0, count: 32)
        defer {
            _ = password.withUnsafeMutableBytes { $0.initializeMemory(as: UInt8.self, repeating: 0) }
            _ = derived.withUnsafeMutableBytes { $0.initializeMemory(as: UInt8.self, repeating: 0) }
        }
        let status = password.withUnsafeBytes { passwordBytes in
            salt.withUnsafeBytes { saltBytes in
                CCKeyDerivationPBKDF(CCPBKDFAlgorithm(kCCPBKDF2),
                    passwordBytes.baseAddress?.assumingMemoryBound(to: Int8.self), password.count,
                    saltBytes.baseAddress?.assumingMemoryBound(to: UInt8.self), salt.count,
                    CCPseudoRandomAlgorithm(kCCPRFHmacAlgSHA256), rounds, &derived, derived.count)
            }
        }
        guard status == kCCSuccess else { throw StoreError.encryption }
        return SymmetricKey(data: derived)
    }

    static func salt() throws -> Data {
        var bytes = [UInt8](repeating: 0, count: 32)
        guard SecRandomCopyBytes(kSecRandomDefault, bytes.count, &bytes) == errSecSuccess else {
            throw StoreError.encryption
        }
        return Data(bytes)
    }

    static func seal(_ data: Data, key: SymmetricKey) throws -> Data {
        guard let combined = try AES.GCM.seal(data, using: key).combined else { throw StoreError.encryption }
        return combined
    }

    static func open(_ data: Data, key: SymmetricKey) throws -> Data {
        try AES.GCM.open(AES.GCM.SealedBox(combined: data), using: key)
    }
}
