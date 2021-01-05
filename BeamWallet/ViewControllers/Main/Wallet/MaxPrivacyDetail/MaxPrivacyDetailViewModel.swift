//
// MaxPrivacyDetailViewModel.swift
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

class MaxPrivacyDetailViewModel: NSObject {
    
    enum UTXOFilterType: Int {
        case time_ear = 0
        case time_latest = 1
        case amount_small = 2
        case amount_large = 3
    }
    
    public var filterType: UTXOFilterType = .time_ear {
        didSet{
            self.filterUTXOS()
        }
    }
    
    public var onDataChanged : (() -> Void)?
    public var onStatusChanged : (() -> Void)?
    
    public var utxos = [BMUTXO]()
    

    override init() {
        super.init()
        
        AppModel.sharedManager().addDelegate(self)
        
        filterUTXOS()
    }
    
    deinit {
        AppModel.sharedManager().removeDelegate(self)
    }
    
    func filterUTXOS() {
        
        DispatchQueue.main.async {
            [weak self] in
            
            guard let strongSelf = self else { return }
            
            var allUtxos = [BMUTXO]()
            if let utxos = AppModel.sharedManager().utxos {
                allUtxos.append(contentsOf: utxos as! [BMUTXO])
            }
            
            if let utxos = AppModel.sharedManager().shildedUtxos {
                allUtxos.append(contentsOf: utxos as! [BMUTXO])
            }
            
            let utxos = allUtxos.filter { $0.status == BMUTXOMaturing && $0.isShilded}

            for utxo in strongSelf.utxos {
                utxo.hoursLeft = AppModel.sharedManager().getMaturityHoursLeft(utxo)
                utxo.time = AppModel.sharedManager().getMaturityHours(utxo)
            }
            
            switch(strongSelf.filterType) {
            case .time_ear:
                strongSelf.utxos = utxos.sorted(by: { $0.time < $1.time })
            case .time_latest:
                strongSelf.utxos = utxos.sorted(by: { $0.time > $1.time })
            case .amount_small:
                strongSelf.utxos = utxos.sorted(by: { $0.amount < $1.amount })
            case .amount_large:
                strongSelf.utxos = utxos.sorted(by: { $0.amount > $1.amount })
            }
            
                        
            strongSelf.onDataChanged?()
        }
    }
}


extension MaxPrivacyDetailViewModel: WalletModelDelegate {
    
    func onReceivedUTXOs(_ utxos: [BMUTXO]) {
        DispatchQueue.main.async {
            self.filterUTXOS()
        }
    }
    
    func onWalletStatusChange(_ status: BMWalletStatus) {
        DispatchQueue.main.async {
            self.onStatusChanged?()
        }
    }
}
