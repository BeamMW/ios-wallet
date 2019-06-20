//
// DetailTransactionViewModel.swift
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

class DetailTransactionViewModel: TransactionViewModel {

    public var details = [GeneralInfo]()
    public var utxos = [BMUTXO]()
    public var paymentProof:BMPaymentProof?
    
    override var transaction: BMTransaction?{
        didSet{
            fillDetails()
        }
    }
    
    override init(transaction: BMTransaction) {
        super.init(transaction: transaction)
        
        fillDetails()
    }
    
    public func fillDetails() {
        
        let transaction = self.transaction!
        
        details.removeAll()

        if transaction.isSelf {
            details.append(GeneralInfo(text: LocalizableStrings.my_send_address, detail: transaction.senderAddress, failed: false, canCopy:true, color: UIColor.white))
            details.append(GeneralInfo(text: LocalizableStrings.my_rec_address, detail: transaction.receiverAddress, failed: false, canCopy:true, color: UIColor.white))
        }
        else if transaction.isIncome {
            details.append(GeneralInfo(text: LocalizableStrings.contact2, detail: transaction.senderAddress, failed: false, canCopy:true, color: UIColor.white))
            details.append(GeneralInfo(text: LocalizableStrings.my_address, detail: transaction.receiverAddress, failed: false, canCopy:true, color: UIColor.white))
        }
        else{
            details.append(GeneralInfo(text: LocalizableStrings.contact2, detail: transaction.receiverAddress, failed: false, canCopy:true, color: UIColor.white))
            details.append(GeneralInfo(text: LocalizableStrings.my_address, detail: transaction.senderAddress, failed: false, canCopy:true, color: UIColor.white))
        }
       
        details.append(GeneralInfo(text: LocalizableStrings.transaction_fee, detail: String.currency(value: transaction.fee), failed: false, canCopy:true, color: UIColor.white))
        details.append(GeneralInfo(text: LocalizableStrings.transaction_id, detail: transaction.id, failed: false, canCopy:true, color: UIColor.white))
        details.append(GeneralInfo(text: LocalizableStrings.kernel_id, detail: transaction.kernelId, failed: false, canCopy:true, color: UIColor.white))
        if !transaction.comment.isEmpty {
            details.append(GeneralInfo(text: LocalizableStrings.comment, detail: transaction.comment, failed: false, canCopy:true, color: UIColor.white))
        }
        if transaction.isFailed() {
            details.append(GeneralInfo(text: LocalizableStrings.failure_reason, detail: transaction.failureReason, failed: true, canCopy:true, color: UIColor.white))
        }
        
        if let utxos = AppModel.sharedManager().getUTXOSFrom(transaction) as? [BMUTXO] {
            self.utxos = utxos
        }
        
        if paymentProof == nil && transaction.hasPaymentProof()  {
            AppModel.sharedManager().getPaymentProof(transaction)
        }
    }
    
    public func actionItems() -> [BMPopoverMenu.BMPopoverMenuItem] {
        let transaction = self.transaction!

        var items = [BMPopoverMenu.BMPopoverMenuItem]()
        
        if transaction.canCancel {
            items.append(BMPopoverMenu.BMPopoverMenuItem(name: LocalizableStrings.cancel_transaction, icon: nil, action: .cancel_transaction))
        }
        
        if transaction.canDelete {
            items.append(BMPopoverMenu.BMPopoverMenuItem(name: LocalizableStrings.delete_transaction, icon: nil, action: .delete_transaction))
        }
        
        if !transaction.isIncome {
            items.append(BMPopoverMenu.BMPopoverMenuItem(name: LocalizableStrings.rep, icon: nil, action: .repeat_transaction))
        }
        
        return items
    }
}

extension DetailTransactionViewModel {
    func onReceive(_ proof: BMPaymentProof) {
        DispatchQueue.main.async {
            if proof.txID == self.transaction?.id {
                self.paymentProof = proof
                self.onDataChanged?()
            }
        }
    }
}
