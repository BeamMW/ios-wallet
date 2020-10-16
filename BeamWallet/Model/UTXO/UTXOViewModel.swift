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
        case available = 0
        case progress = 1
        case spent = 2
        case unavailable = 3
        case maturing = 4
        case outgoing = 5
        case incoming = 6
    }
    
    public var selectedState: UTXOSelectedState = .available {
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
    }
    
    deinit {
        AppModel.sharedManager().removeDelegate(self)
    }
    
    private func filterUTXOS() {
        
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
            
            strongSelf.utxos = allUtxos
            
            switch strongSelf.selectedState {
            case .available:
                strongSelf.utxos = strongSelf.utxos.filter { $0.status == BMUTXOAvailable}
            case .spent:
                strongSelf.utxos = strongSelf.utxos.filter { $0.status == BMUTXOSpent}
            case .unavailable:
                strongSelf.utxos = strongSelf.utxos.filter { $0.status == BMUTXOUnavailable}
            case .progress:
                strongSelf.utxos = strongSelf.utxos.filter { $0.status == 3 || $0.status == 4 || $0.status == 2}
            case .incoming:
                strongSelf.utxos = strongSelf.utxos.filter { $0.status == BMUTXOIncoming}
            case .outgoing:
                strongSelf.utxos = strongSelf.utxos.filter { $0.status == BMUTXOOutgoing}
            case .maturing:
                strongSelf.utxos = strongSelf.utxos.filter { $0.status == BMUTXOMaturing}
            }
            
            var sortByDate = false
            
            for utxo in strongSelf.utxos {
                let history = AppModel.sharedManager().getTransactionsFrom(utxo) as! [BMTransaction]
                if history.count > 0 {
                    utxo.transaction = history.last
                    utxo.transactionDate = utxo.transaction?.createdTime ?? 0
                    sortByDate = true
                }
            }
            
            if sortByDate {
                strongSelf.utxos = strongSelf.utxos.sorted(by: { $0.transactionDate > $1.transactionDate })
            }
            else{
                strongSelf.utxos = strongSelf.utxos.sorted(by: { $0.id < $1.id })
            }
            
            strongSelf.onDataChanged?()
        }
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
