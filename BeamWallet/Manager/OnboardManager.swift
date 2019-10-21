//
// RestoreManager.swift
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

import UIKit

class OnboardManager: NSObject {
    public static let minAmountToSecure: Double = 100.0
    
    private let faucetKey = "faucetKey"
    private let isSkipedSeedKey = "isSkipedSeedKey"
    
    static var shared = OnboardManager()
    
    public var isCloseSecure = false
    public var isCloseFaucet = false
    
    public func reset() {
        isCloseSecure = false
        isCloseFaucet = false
        
        UserDefaults.standard.removeObject(forKey: faucetKey)
        UserDefaults.standard.set(false, forKey: isSkipedSeedKey)
        UserDefaults.standard.synchronize()
    }
    
    // MARK: Faucet
    
    public func canReceiveFaucet() -> Bool {
        if !EnableNewFeatures {
            return false
        }
        let isInProgress = AppModel.sharedManager().walletStatus?.hasInProgressBalance() ?? false
        let isBalanceZero = (AppModel.sharedManager().walletStatus?.available ?? 0) == 0
        return !isInProgress && isBalanceZero && !isCloseFaucet
    }
    
    public func receiveFaucet(completion: @escaping ((URL?, Error?) -> Void)) {
        let address = AppModel.sharedManager().findAddress(byName: "Beam community faucet")
        
        if address == nil || address?.isExpired() ?? true {
            AppModel.sharedManager().generateNewWalletAddress { [weak self] address, error in
                if let result = address {
                    DispatchQueue.main.async {
                        let address = BMAddress.fromAddress(result)
                        address.label = "Beam community faucet"
                        
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                            AppModel.sharedManager().setWalletComment(address.label, toAddress: address.walletId)
                        }
                        
                        completion(self?.faucetURLForAddress(address: result), nil)
                    }
                }
                else if error != nil {
                    DispatchQueue.main.async {
                        completion(nil, error)
                    }
                }
            }
        }
        else {
            completion(faucetURLForAddress(address: address!), nil)
        }
    }
    
    private func faucetURLForAddress(address: BMAddress) -> URL {
        if Settings.sharedManager().target == Testnet {
            return URL(string: "https://faucet.beamprivacy.community/?address=\(address.walletId)&type=testnet")!
        }
        else if Settings.sharedManager().target == Masternet {
            return URL(string: "https://faucet.beamprivacy.community/?address=\(address.walletId)&type=masternet")!
        }
        else {
            return URL(string: "https://faucet.beamprivacy.community/?address=\(address.walletId)&type=mainnet")!
        }
    }
    
    // MARK: Seed
    
    public func onSkipSeed(isSkiped: Bool) {
        UserDefaults.standard.set(isSkiped, forKey: isSkipedSeedKey)
        UserDefaults.standard.synchronize()
    }
    
    public func saveSeed(seed: String) {
        _ = KeychainManager.addSeed(seed: seed)
    }
    
    public func getSeed() -> String? {
        if !EnableNewFeatures {
            return nil
        }
        return KeychainManager.getSeed()
    }
    
    public func isSkipedSeed() -> Bool {
        if !EnableNewFeatures {
            return false
        }
        return UserDefaults.standard.bool(forKey: isSkipedSeedKey)
    }
    
    public func makeSecure() {
        UserDefaults.standard.set(false, forKey: isSkipedSeedKey)
        UserDefaults.standard.synchronize()
        
        AppModel.sharedManager().completeWalletVerification()
    }
    
    public func canMakeSecure() -> Bool {
        if !EnableNewFeatures {
            return false
        }
        else if let available = AppModel.sharedManager().walletStatus?.realAmount {
            if available >= OnboardManager.minAmountToSecure, isSkipedSeed(), !isCloseSecure {
                return true
            }
        }
        
        return false
    }
}
