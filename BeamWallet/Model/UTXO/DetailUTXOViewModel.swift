//
// DetailUTXOViewModel.swift
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

class DetailUTXOViewModel: UTXOViewModel {
    
    public var details = [GeneralInfo]()
    public var history = [BMTransaction]()
    
    public var utxo:BMUTXO! {
        didSet{
            fillDetails()
        }
    }
    
    init(utxo: BMUTXO) {
        super.init()
        
        self.utxo = utxo
        
        self.history = AppModel.sharedManager().getTransactionsFrom(utxo) as! [BMTransaction]
        
        self.fillDetails()
        
        AppModel.sharedManager().addDelegate(self)
    }
    
    private func fillDetails() {
        details.removeAll()
        
        if let kernel = history.first?.kernelId {
            details.append(GeneralInfo(text: Localizable.shared.strings.addDots(value: Localizable.shared.strings.kernel_id), detail: kernel, failed: false, canCopy:true, color: UIColor.white))
        }
        
        details.append(GeneralInfo(text: Localizable.shared.strings.utxo_type, detail: utxo.typeString, failed: false, canCopy:false, color: UIColor.white))
        
        self.onDataChanged?()
    }
}

extension DetailUTXOViewModel {
    
    func onReceivedTransactions(_ transactions: [BMTransaction]) {
        DispatchQueue.main.async {
            self.history = AppModel.sharedManager().getTransactionsFrom(self.utxo) as! [BMTransaction]
            self.onDataChanged?()
        }
    }
    
    override func onReceivedUTXOs(_ utxos: [BMUTXO]) {
        DispatchQueue.main.async {
            if let utxo = utxos.first(where: { $0.id == self.utxo.id }) {
                self.utxo = utxo
            }
        }
    }
}
