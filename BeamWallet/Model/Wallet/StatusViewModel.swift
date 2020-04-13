//
// StatusViewModel.swift
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

class StatusViewModel: NSObject {
    
    enum CellTypes: Int {
        case buttons = 0
        case available = 1
        case progress = 2
        case faucet = 3
        case verefication = 4
    }
    
    enum SelectedState: Int {
        case available = 0
        case maturing = 1
    }
    
    public var onDataChanged : (() -> Void)?
    public var onRatesChange : (() -> Void)?
    public var onVerificationCompleted : (() -> Void)?
    public var selectedState = SelectedState.available
    public var cells = [CellTypes]()
    
    override init() {
        super.init()
        
        self.cells = getCells()

        AppModel.sharedManager().addDelegate(self)
    }
    
    deinit {
        AppModel.sharedManager().removeDelegate(self)
    }
    
    public func isAvaiableMautring() -> Bool {
        if AppModel.sharedManager().walletStatus?.maturing ?? 0 > 0 {
            return true
        }
        
        return false
    }
    
    public func isAvaiableBalance() -> Bool {
        if AppModel.sharedManager().walletStatus?.available ?? 0 > 0 {
            return true
        }
        
        return false
    }
    
    public func onReceive() {
        if AppModel.sharedManager().isWalletRunning() {
            let vc = ReceiveViewController()
            UIApplication.getTopMostViewController()?.pushViewController(vc: vc)
        }
        else{
            UIApplication.getTopMostViewController()?.alert(message: Localizable.shared.strings.no_internet)
        }
      
    }
    
    public func onSend() {
        if AppModel.sharedManager().isWalletRunning() {
            let vc = SendViewController()
            UIApplication.getTopMostViewController()?.pushViewController(vc: vc)
        }
        else{
            UIApplication.getTopMostViewController()?.alert(message: Localizable.shared.strings.no_internet)
        }
    }
    
    private func getCells() -> [CellTypes] {
        var result = [CellTypes]()
        
        result.append(.buttons)
        
        let canReceive = OnboardManager.shared.canReceiveFaucet()

        let isInProgress = AppModel.sharedManager().walletStatus?.hasInProgressBalance() ?? false

        if canReceive {
            result.append(.faucet)
        }
        
        let canMakeSecure = OnboardManager.shared.canMakeSecure()

        if canMakeSecure {
            result.append(.verefication)
        }
        
        result.append(.available)
        
        if isInProgress {
            result.append(.progress)
        }
           
        return result
    }
}

extension StatusViewModel: WalletModelDelegate {
    
    func onWalletCompleteVerefication() {
        DispatchQueue.main.async {
             self.cells = self.getCells()
             self.onVerificationCompleted?()
         }
    }
    
    func onWalletStatusChange(_ status: BMWalletStatus) {
        DispatchQueue.main.async {
            self.cells = self.getCells()
            self.onDataChanged?()
        }
    }
    
    func onExchangeRatesChange() {
        DispatchQueue.main.async {
            self.onRatesChange?()
        }
    }
}
