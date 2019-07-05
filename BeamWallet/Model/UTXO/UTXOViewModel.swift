//
// UTXOViewModel.swift
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

class UTXOViewModel: NSObject {
    
    enum UTXOSelectedState: Int {
        case all = 0
        case available = 1
        case spent = 2
        case unavailable = 3
        case progress = 4
    }
    
    public var selectedState: UTXOSelectedState = .all {
        didSet{
            self.filterUTXOS()
        }
    }

    public var onDataChanged : (() -> Void)?
    public var onStatusChanged : (() -> Void)?

    public var utxos = [BMUTXO]()

    override init() {
        super.init()
    }
    
    init(selected:UTXOSelectedState) {
        super.init()
        
        self.selectedState = selected
        
        self.filterUTXOS()
        
        AppModel.sharedManager().addDelegate(self)
    }
    
    deinit {
        AppModel.sharedManager().removeDelegate(self)
    }
    
    private func filterUTXOS() {
        switch selectedState {
        case .all:
            if let utox = AppModel.sharedManager().utxos {
                self.utxos = utox as! [BMUTXO]
            }
        case .available:
            if let utxos = AppModel.sharedManager().utxos {
                self.utxos = utxos as! [BMUTXO]
                self.utxos = self.utxos.filter { $0.status == BMUTXOAvailable}
            }
        case .spent:
            if let utxos = AppModel.sharedManager().utxos {
                self.utxos = utxos as! [BMUTXO]
                self.utxos = self.utxos.filter { $0.status == BMUTXOSpent}
            }
        case .unavailable:
            if let utxos = AppModel.sharedManager().utxos {
                self.utxos = utxos as! [BMUTXO]
                self.utxos = self.utxos.filter { $0.status == BMUTXOUnavailable}
            }
        case .progress:
            if let utxos = AppModel.sharedManager().utxos {
                self.utxos = utxos as! [BMUTXO]
                self.utxos = self.utxos.filter { $0.status == BMUTXOIncoming || $0.status == BMUTXOOutgoing}
            }
        }
        self.utxos = self.utxos.sorted(by: { $0.id < $1.id })
        
        self.onDataChanged?()
    }
}

extension UTXOViewModel: WalletModelDelegate {
    
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
