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
            details.append(GeneralInfo(text: Localizable.shared.strings.addDots(value: Localizable.shared.strings.my_send_address), detail: transaction.senderAddress, failed: false, canCopy:true, color: UIColor.white))
            details.append(GeneralInfo(text: Localizable.shared.strings.addDots(value: Localizable.shared.strings.my_rec_address), detail: transaction.receiverAddress, failed: false, canCopy:true, color: UIColor.white))
        }
        else if transaction.isIncome {
            details.append(GeneralInfo(text: Localizable.shared.strings.addDots(value: Localizable.shared.strings.contact), detail: transaction.senderAddress, failed: false, canCopy:true, color: UIColor.white))
            details.append(GeneralInfo(text: Localizable.shared.strings.addDots(value: Localizable.shared.strings.my_address), detail: transaction.receiverAddress, failed: false, canCopy:true, color: UIColor.white))
        }
        else{
            details.append(GeneralInfo(text: Localizable.shared.strings.addDots(value: Localizable.shared.strings.contact), detail: transaction.receiverAddress, failed: false, canCopy:true, color: UIColor.white))
            details.append(GeneralInfo(text: Localizable.shared.strings.addDots(value: Localizable.shared.strings.my_address), detail: transaction.senderAddress, failed: false, canCopy:true, color: UIColor.white))
        }
       
        details.append(GeneralInfo(text: Localizable.shared.strings.addDots(value: Localizable.shared.strings.transaction_fee), detail: String.currency(value: transaction.fee), failed: false, canCopy:true, color: UIColor.white))
        details.append(GeneralInfo(text: Localizable.shared.strings.addDots(value: Localizable.shared.strings.transaction_id), detail: transaction.id, failed: false, canCopy:true, color: UIColor.white))
       
        details.append(GeneralInfo(text: Localizable.shared.strings.addDots(value: Localizable.shared.strings.kernel_id), detail: transaction.isExpired() ? "0000000000000000000000000000000000000000000000000000000000000000" :  transaction.kernelId, failed: false, canCopy:true, color: UIColor.white))
        
        if transaction.isIncome {
            if let last = AppModel.sharedManager().getFirstTransactionId(forAddress: transaction.receiverAddress) {
                if last == transaction.id {
                    let comment = AppModel.sharedManager().getTransactionComment(transaction.receiverAddress)
                    if !comment.isEmpty {
                        transaction.comment = comment
                    }
                }
            }
        }
        
        if !transaction.comment.isEmpty {
            details.append(GeneralInfo(text: Localizable.shared.strings.addDots(value: Localizable.shared.strings.comment), detail: transaction.comment, failed: false, canCopy:true, color: UIColor.white))
        }
        if transaction.isFailed() {
            details.append(GeneralInfo(text: Localizable.shared.strings.addDots(value: Localizable.shared.strings.failure_reason), detail: transaction.failureReason, failed: true, canCopy:true, color: UIColor.white))
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
        items.append(BMPopoverMenu.BMPopoverMenuItem(name: Localizable.shared.strings.share_transaction, icon: nil, action: .share))

        if !transaction.isIncome {
            items.append(BMPopoverMenu.BMPopoverMenuItem(name: Localizable.shared.strings.rep, icon: nil, action: .repeat_transaction))
        }
        
        if transaction.canCancel {
            items.append(BMPopoverMenu.BMPopoverMenuItem(name: Localizable.shared.strings.cancel_transaction, icon: nil, action: .cancel_transaction))
        }
        
        if transaction.canDelete {
            items.append(BMPopoverMenu.BMPopoverMenuItem(name: Localizable.shared.strings.delete_transaction, icon: nil, action: .delete_transaction))
        }
        
        return items
    }
    
    public func share() {
        let shareView: TransactionShareView = UIView.fromNib()
        shareView.transaction = transaction
        shareView.layoutIfNeeded()
        
        if let top = UIApplication.getTopMostViewController() {
            if let image = shareView.snapshot(scale: false) {
                let activityItem: [AnyObject] = [image]
                let vc = UIActivityViewController(activityItems: activityItem, applicationActivities: [])
                vc.completionWithItemsHandler = {(activityType: UIActivity.ActivityType?, completed: Bool, returnedItems: [Any]?, error: Error?) in
                }
                
                vc.excludedActivityTypes = [UIActivity.ActivityType.assignToContact, UIActivity.ActivityType.print,UIActivity.ActivityType.openInIBooks]
                
                top.present(vc, animated: true)
            }
        }
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