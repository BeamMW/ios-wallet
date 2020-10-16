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

    public var details = [BMMultiLineItem]()
    public var utxos = [BMUTXO]()
    public var paymentProof:BMPaymentProof?

    public var detailsExpand = true
    public var utxoExpand = true

    
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

        details.append(BMMultiLineItem(title: Localizable.shared.strings.date.uppercased(), detail: transaction.formattedDate(), detailFont: RegularFont(size: 16), detailColor: UIColor.white))
        
        if transaction.isSelf {
            details.append(BMMultiLineItem(title: Localizable.shared.strings.my_send_address.uppercased(), detail: transaction.senderAddress, detailFont: RegularFont(size: 16), detailColor: UIColor.white, copy: true))

            details.append(BMMultiLineItem(title: Localizable.shared.strings.my_rec_address.uppercased(), detail: transaction.receiverAddress, detailFont: RegularFont(size: 16), detailColor: UIColor.white, copy: true))
        }
        else if transaction.isIncome {
            if transaction.isOffline || transaction.enumType == BMTransactionTypePullTransaction
                || transaction.enumType == BMTransactionTypePushTransaction {
                details.append(BMMultiLineItem(title: Localizable.shared.strings.contact.uppercased(), detail: Localizable.shared.strings.shielded_pool, detailFont: RegularFont(size: 16), detailColor: UIColor.white, copy: false))
            }
            else {
                details.append(BMMultiLineItem(title: Localizable.shared.strings.contact.uppercased(), detail: transaction.senderAddress, detailFont: RegularFont(size: 16), detailColor: UIColor.white, copy: true))
            }
            
            details.append(BMMultiLineItem(title: Localizable.shared.strings.my_address.uppercased(), detail: transaction.receiverAddress, detailFont: RegularFont(size: 16), detailColor: UIColor.white, copy: true))
        }
        else{
            details.append(BMMultiLineItem(title: Localizable.shared.strings.contact.uppercased(), detail: transaction.receiverAddress, detailFont: RegularFont(size: 16), detailColor: UIColor.white, copy: true))
            
            details.append(BMMultiLineItem(title: Localizable.shared.strings.my_address.uppercased(), detail: transaction.senderAddress, detailFont: RegularFont(size: 16), detailColor: UIColor.white, copy: true))
        }
        
        if transaction.realFee > 0 {
            details.append(BMMultiLineItem(title: Localizable.shared.strings.transaction_fee.uppercased(), detail: String(transaction.realFee) + " GROTH", detailFont: RegularFont(size: 16), detailColor: UIColor.white))
        }
        
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
            details.append(BMMultiLineItem(title: Localizable.shared.strings.comment.uppercased(), detail: transaction.comment, detailFont: RegularFont(size: 16), detailColor: UIColor.white))
        }
        
        details.append(BMMultiLineItem(title: Localizable.shared.strings.transaction_id.uppercased(), detail: transaction.id, detailFont: RegularFont(size: 16), detailColor: UIColor.white, copy: true))

        if !transaction.identity.isEmpty {
            details.append(BMMultiLineItem(title: Localizable.shared.strings.wallet_id.uppercased(), detail: transaction.identity, detailFont: RegularFont(size: 16), detailColor: UIColor.white, copy: true, copiedText: Localizable.shared.strings.copied_to_clipboard))
        }
        
        if !transaction.isExpired() && !transaction.isFailed() && !transaction.kernelId.contains("000000000") {
            details.append(BMMultiLineItem(title: Localizable.shared.strings.kernel_id.uppercased(), detail:  transaction.kernelId, detailFont: RegularFont(size: 16), detailColor: UIColor.white, copy: true))
        }
         
     
        if transaction.isFailed() {
            details.append(BMMultiLineItem(title: Localizable.shared.strings.failure_reason.uppercased(), detail: transaction.failureReason, detailFont: RegularFont(size: 16), detailColor: UIColor.main.red, copy: true))
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
        
        if transaction.canSaveContact() {
            items.append(BMPopoverMenu.BMPopoverMenuItem(name: Localizable.shared.strings.save_contact_title, icon: nil, action: .save_contact))
        }
        
        items.append(BMPopoverMenu.BMPopoverMenuItem(name: Localizable.shared.strings.share_details, icon: nil, action: .share))

        items.append(BMPopoverMenu.BMPopoverMenuItem(name: Localizable.shared.strings.copy_details, icon: nil, action: .copy))

        
        if !transaction.isIncome && !transaction.isUnlink() && !transaction.isOffline && (transaction.enumType != BMTransactionTypePullTransaction && transaction.enumType != BMTransactionTypePushTransaction) {
            items.append(BMPopoverMenu.BMPopoverMenuItem(name: Localizable.shared.strings.repeat_transaction, icon: nil, action: .repeat_transaction))
        }
        
        if transaction.canCancel {
            items.append(BMPopoverMenu.BMPopoverMenuItem(name: Localizable.shared.strings.cancel_transaction, icon: nil, action: .cancel_transaction))
        }
        
        if transaction.canDelete {
            items.append(BMPopoverMenu.BMPopoverMenuItem(name: Localizable.shared.strings.delete_transaction, icon: nil, action: .delete_transaction))
        }
        
        return items
    }
    
    public func copyDetails() {
        if let tr = self.transaction, let top = UIApplication.getTopMostViewController() {
            let activityItem: [String] = [tr.textDetails()]
            let vc = UIActivityViewController(activityItems: activityItem, applicationActivities: [])
            vc.completionWithItemsHandler = {(activityType: UIActivity.ActivityType?, completed: Bool, returnedItems: [Any]?, error: Error?) in
            }
            
            vc.excludedActivityTypes = [UIActivity.ActivityType.assignToContact, UIActivity.ActivityType.print,UIActivity.ActivityType.openInIBooks]
            
            top.present(vc, animated: true)
        }
    }
    
    public func share() {
        let shareView: TransactionShareView = UIView.fromNib()
        shareView.transaction = transaction
        shareView.layoutIfNeeded()
        shareView.resize()
        
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
    
    public func saveContact() {
        if let top = UIApplication.getTopMostViewController() {
            let transaction = self.transaction!
            var address:String? = nil
            
            if transaction.isIncome {
                address = transaction.senderAddress
            }
            else{
                address = transaction.receiverAddress
            }
            
            let vc = SaveContactViewController(address: address)
            top.pushViewController(vc: vc)
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
