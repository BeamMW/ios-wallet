//
// BuyBeamOrderViewModel.swift
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

class BuyBeamOrderViewModel: NSObject {

    private var timer:Timer?

    public var onOrderStatusChange : ((CryptoWolfService.TransactionInfo?) -> Void)?
    public var currency:String!
    
    override init() {
        super.init()
    }
    
    deinit {
        timer?.invalidate()
        timer = nil
    }
    
    @objc public func stopUpdates() {
        timer?.invalidate()
        timer = nil
    }
    
    @objc public func updateOrderStatus() {
        if let orderAddress = CryptoWolfManager.sharedManager.order?.address {
            CryptoWolfService.sharedManager.getTransactionInfo(address:orderAddress, currency: currency) {[weak self] (response, error) in
                
                guard let strongSelf = self else { return }
                
                strongSelf.timer?.invalidate()
                strongSelf.timer = nil
                strongSelf.timer = Timer.scheduledTimer(timeInterval: TimeInterval(5), target: strongSelf, selector: #selector(strongSelf.updateOrderStatus), userInfo: nil, repeats: false)
                
                strongSelf.onOrderStatusChange?(response)
            }
        }
    }
}
