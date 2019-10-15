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
    private let statusKey = "statusKey"
    private let faucetAddressIdKey = "faucetAddressId"

    enum Status: Int {
        case None = 0
        case Start = 1
        case Received = 2
        case Completed = 3
        case Closed = 4
    }
    
    static var shared = OnboardManager()
    
    override init() {
        super.init()
                
        if getStatus() == Status.Closed {
            UserDefaults.standard.set(Status.Start.rawValue, forKey: statusKey)
            UserDefaults.standard.synchronize()
        }
    }
    
    public var isSkipSeed = false
    
    public func saveSeed(seed:String) {
        if isSkipSeed {
            _ = KeychainManager.removeSeed()
        }
        else{
            _ = KeychainManager.addSeed(seed: seed)
        }
           
        UserDefaults.standard.set(Status.Start.rawValue, forKey: statusKey)
        UserDefaults.standard.synchronize()
    }
    
    public func getSeed() -> String? {
        return KeychainManager.getSeed()
    }
    
    public func getStatus() -> Status {
        let value = UserDefaults.standard.integer(forKey: statusKey)
        return Status(rawValue: value) ?? Status.None
    }
    
    public func canReceiveFaucet() -> Bool {
        let status = getStatus()
        return status == Status.Start
    }
    
    public func canShowSeed() -> Bool {
        return getSeed() != nil
    }
    
    public func makeSecure()  {
        _ = KeychainManager.removeSeed()
    }
    
    public func receiveFaucet(completion:@escaping ((BMAddress?,Error?) -> Void)){
        AppModel.sharedManager().generateNewWalletAddress {[weak self] (address, error) in
            guard let strongSelf = self else { return }

            if let result = address {
                DispatchQueue.main.async {
                    let address = BMAddress.fromAddress(result)
                    address.label = "Beam community faucet"
    
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                        AppModel.sharedManager().setWalletComment(address.label, toAddress: address.walletId)
                    }
                                        
                    UserDefaults.standard.setValue(address.walletId, forKey: strongSelf.faucetAddressIdKey)
                    UserDefaults.standard.synchronize()
                    
                    completion(address,nil)
                }
            }
            else if (error) != nil {
                DispatchQueue.main.async {
                    completion(nil,error)
                }
            }
        }
    }
    
    public func closeFaucet() {
        UserDefaults.standard.set(Status.Closed.rawValue, forKey: statusKey)
        UserDefaults.standard.synchronize()
    }
    
    public func receivedFaucet(transactions:[BMTransaction]) -> Bool {
        let walletId = UserDefaults.standard.string(forKey: self.faucetAddressIdKey)
        
        for tr in transactions {
            if tr.receiverAddress == walletId {
                UserDefaults.standard.set(Status.Received.rawValue, forKey: statusKey)
                UserDefaults.standard.synchronize()
                
                return true
            }
        }
        
        return false
    }
}
