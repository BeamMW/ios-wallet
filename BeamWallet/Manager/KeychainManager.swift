//
// KeychainManager.swift
// BeamWallet
//
// Copyright 2018 Beam Development
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
    private static let readLock = NSLock()

    public static func removeSeed() -> Bool {
      return delete(seedKey)
    }
    
    public static func addSeed(seed:String) -> Bool {
        _ = delete(seedKey)
        
        let password = seed.data(using: String.Encoding.utf8)!
        let query: [String: Any] = [kSecClass as String: kSecClassGenericPassword,
                                    kSecValueData as String: password,
                                    kSecAttrAccount as String : seedKey]
        
        let status = SecItemAdd(query as CFDictionary, nil)
       
        return status == errSecSuccess
    }
    
    public static func addPassword(password:String) -> Bool {
        _ = delete(passKey)
        
        let password = password.data(using: String.Encoding.utf8)!
        let query: [String: Any] = [kSecClass as String: kSecClassGenericPassword,
                                    kSecValueData as String: password,
                                    kSecAttrAccount as String : passKey]
        
        let status = SecItemAdd(query as CFDictionary, nil)
       
        return status == errSecSuccess
    }
    
    public static func getPassword() -> String? {
        if let data = getData(passKey) {
            
            if let currentString = String(data: data, encoding: .utf8) {
                return currentString
            }
        }
        
        return nil
    }
    
    public static func getSeed() -> String? {
        if let data = getData(seedKey) {
            
            if let currentString = String(data: data, encoding: .utf8) {
                return currentString
            }
        }
        
        return nil
    }
    
    private static func delete(_ key: String) -> Bool {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String : key
        ]
        
        let lastResultCode = SecItemDelete(query as CFDictionary)
        
        return lastResultCode == noErr
    }
    
    private static func getData(_ key: String) -> Data? {
        readLock.lock()
        defer { readLock.unlock() }
                
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String : key,
            kSecReturnData as String  : kCFBooleanTrue as Any,
            kSecMatchLimit as String  : kSecMatchLimitOne
        ]
        
        
        var result: AnyObject?
        
        let lastResultCode = withUnsafeMutablePointer(to: &result) {
            SecItemCopyMatching(query as CFDictionary, UnsafeMutablePointer($0))
        }
        
        if lastResultCode == noErr { return result as? Data }
        
        return nil
    }
}
