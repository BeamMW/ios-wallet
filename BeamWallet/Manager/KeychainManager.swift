//
// KeychainManager.swift
// BeamWallet
//
// Copyright 2026 Beam Development
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//

import Foundation
import LocalAuthentication

struct Credentials {
    var password: String
}

enum KeychainError: Error {
    case noPassword
    case unexpectedPasswordData
    case unhandledError(status: OSStatus)
}

class KeychainManager {
    private static let passKey = "wallet"
    private static let seedKey = "seed"
    private static let lock = NSLock()

    public static func addSeed(seed: String) -> Bool {
        return write(key: seedKey, value: seed, requireBiometry: false)
    }

    /// Stores the wallet password in the keychain when biometric unlock is on,
    /// guarded by a `.biometryCurrentSet` access-control so reading the entry
    /// requires fresh biometric authentication. When the toggle is off, any
    /// existing entry is removed so the toggle is the single source of truth.
    public static func addPassword(password: String) -> Bool {
        if !Settings.sharedManager().isEnableBiometric {
            _ = delete(passKey)
            return true
        }
        return write(key: passKey, value: password, requireBiometry: true)
    }

    public static func getPassword() -> String? {
        return getPassword(context: nil)
    }

    /// Reads the password. If `context` is supplied and already authenticated,
    /// the OS skips the biometric prompt; otherwise SecItemCopyMatching shows
    /// its own prompt because of the `.biometryCurrentSet` ACL on the entry.
    public static func getPassword(context: LAContext?) -> String? {
        guard let data = getData(passKey, context: context) else { return nil }
        return String(data: data, encoding: .utf8)
    }

    public static func getSeed() -> String? {
        guard let data = getData(seedKey, context: nil) else { return nil }
        return String(data: data, encoding: .utf8)
    }

    @discardableResult
    public static func deletePassword() -> Bool {
        return delete(passKey)
    }

    @discardableResult
    public static func deleteSeed() -> Bool {
        return delete(seedKey)
    }

    // MARK: - Private

    private static func write(key: String, value: String, requireBiometry: Bool) -> Bool {
        lock.lock()
        defer { lock.unlock() }

        _ = deleteLocked(key)

        guard let data = value.data(using: .utf8) else { return false }

        var query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecValueData as String: data,
        ]

        if requireBiometry {
            guard let access = SecAccessControlCreateWithFlags(
                nil,
                kSecAttrAccessibleWhenPasscodeSetThisDeviceOnly,
                .biometryCurrentSet,
                nil) else {
                // Refuse to store a password unprotected on a device that can't
                // produce a biometry ACL (no biometry / no passcode).
                return false
            }
            query[kSecAttrAccessControl as String] = access
        } else {
            query[kSecAttrAccessible as String] = kSecAttrAccessibleWhenPasscodeSetThisDeviceOnly
        }

        let status = SecItemAdd(query as CFDictionary, nil)
        return status == errSecSuccess
    }

    @discardableResult
    private static func delete(_ key: String) -> Bool {
        lock.lock()
        defer { lock.unlock() }
        return deleteLocked(key)
    }

    private static func deleteLocked(_ key: String) -> Bool {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
        ]
        let status = SecItemDelete(query as CFDictionary)
        return status == errSecSuccess || status == errSecItemNotFound
    }

    private static func getData(_ key: String, context: LAContext?) -> Data? {
        lock.lock()
        defer { lock.unlock() }

        var query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecReturnData as String: kCFBooleanTrue as Any,
            kSecMatchLimit as String: kSecMatchLimitOne,
        ]
        if let context = context {
            query[kSecUseAuthenticationContext as String] = context
        }

        var result: AnyObject?
        let status = withUnsafeMutablePointer(to: &result) {
            SecItemCopyMatching(query as CFDictionary, UnsafeMutablePointer($0))
        }
        guard status == errSecSuccess else { return nil }
        return result as? Data
    }
}
