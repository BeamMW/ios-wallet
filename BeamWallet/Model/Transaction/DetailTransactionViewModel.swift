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

    public var details = [Any]()
    public var proofDetail = [BMMultiLineItem]()

    public var paymentProof:BMPaymentProof?
    public var isPaymentProof = false

    
    override var transaction: BMTransaction?{
        didSet{
            fillDetails()
        }
    }
    
    override init(transaction: BMTransaction) {
        super.init(transaction: transaction)
        
        fillDetails()
    }
    
    init(transaction: BMTransaction, isPaymentProof:Bool) {
        super.init(transaction: transaction)
        
        self.isPaymentProof = isPaymentProof
        
        fillDetails()
    }
    
    public func fillDetails() {
        
        let transaction = self.transaction!
        
        details.removeAll()

        if !isPaymentProof {
            details.append(BMMultiLineItem(title: Localizable.shared.strings.date.uppercased(), detail: transaction.formattedDate(), detailFont: RegularFont(size: 16), detailColor: UIColor.white))
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
        
  
        if isPaymentProof {
            let isToken = AppModel.sharedManager().isToken(transaction.receiverAddress)
            
            if isToken {
                details.append(BMMultiLineItem(title: Localizable.shared.strings.sender_wallet_signature.uppercased(), detail: transaction.senderIdentity, detailFont: RegularFont(size: 16), detailColor: UIColor.white, copy: true, showCopyButton: true))
                details.append(BMMultiLineItem(title: Localizable.shared.strings.receiver_wallet_signature.uppercased(), detail: transaction.receiverIdentity, detailFont: RegularFont(size: 16), detailColor: UIColor.white, copy: true, showCopyButton: true))
            }            
        }
        else if (transaction.isPublicOffline || transaction.isMaxPrivacy || transaction.isShielded) && transaction.isIncome && !transaction.isDapps  {
            
            if transaction.isIncome {
                details.append(BMMultiLineItem(title: Localizable.shared.strings.receiving_address.uppercased(), detail: transaction.receiverAddress, detailFont: RegularFont(size: 16), detailColor: UIColor.white, copy: true, showCopyButton: true))
            }
            else {
                details.append(BMMultiLineItem(title: Localizable.shared.strings.receiving_address.uppercased(), detail: transaction.token, detailFont: RegularFont(size: 16), detailColor: UIColor.white, copy: true, showCopyButton: true))
            }
            
            details.append(BMMultiLineItem(title: Localizable.shared.strings.address_type.uppercased(), detail: transaction.getAddressType(), detailFont: RegularFont(size: 16), detailColor: UIColor.white, copy: false))
        }
        else if(!transaction.isDapps) {
            if !transaction.senderAddress.isEmpty {
                details.append(BMMultiLineItem(title: Localizable.shared.strings.sending_address.uppercased(), detail: transaction.senderAddress, detailFont: RegularFont(size: 16), detailColor: UIColor.white, copy: true, showCopyButton: true))
            }
            
            if transaction.isIncome {
                details.append(BMMultiLineItem(title: Localizable.shared.strings.receiving_address.uppercased(), detail: transaction.receiverAddress, detailFont: RegularFont(size: 16), detailColor: UIColor.white, copy: true, showCopyButton: true))
            }
            else {
                details.append(BMMultiLineItem(title: Localizable.shared.strings.receiving_address.uppercased(), detail: transaction.token, detailFont: RegularFont(size: 16), detailColor: UIColor.white, copy: true, showCopyButton: true))
            }
            
            details.append(BMMultiLineItem(title: Localizable.shared.strings.address_type.uppercased(), detail: transaction.getAddressType(), detailFont: RegularFont(size: 16), detailColor: UIColor.white, copy: false))
        }
        
        if let progress = transaction.minConfirmationsProgress, progress != "unknown" {
            let first = progress.components(separatedBy: "/").first
            let last = progress.components(separatedBy: "/").last

            var detailProgress = Localizable.shared.strings.confirming + " (\(progress))"
            
            if first == last {
                detailProgress = Localizable.shared.strings.confirmed + " (\(progress))"
            }
            
            details.append(BMMultiLineItem(title: Localizable.shared.strings.confirmation_status.uppercased(), detail: detailProgress, detailFont: RegularFont(size: 16), detailColor: UIColor.white, copy: false))
        }
        
        var amount = String.currency(value: transaction.realAmount, name: transaction.asset?.unitName ?? "")

        if transaction.isIncome {
            amount = "+" + amount
        }
        else {
            amount = "-" + amount
        }
        
        let current = Settings.sharedManager().currencyName()
        let notAvailable = Localizable.shared.strings.rate_transaction_not_available.lowercased()
        var rateString = String(format: notAvailable, current)
        
        if transaction.isMultiAssets() {
            if let assets = transaction.multiAssets as? [BMAsset] {
                rateString = String(format: notAvailable, current)
                var index = 0
                for asset in assets {
                    if transaction.realRate > 0 {
                        rateString = Localizable.shared.strings.rate_transaction.lowercased()
                        
                        let second = ExchangeManager.shared().exchangeValueAsset(withCurrency: Int64(transaction.realRate), amount: transaction.realAmount, assetID: UInt64(asset.assetId))
                        
                        if transaction.isIncome {
                            rateString = "+\(second) " + "(" + rateString + ")"
                        }
                        else {
                            rateString = "-\(second) " + "(" + rateString + ")"
                        }
                    }
                    
                    amount = String.currency(value: asset.realAmount, name: asset.unitName).replacingOccurrences(of: "(", with: "").replacingOccurrences(of: ")", with: "")
                    
                    if asset.realAmount > 0 {
                        amount = "+" + amount
                    }
                    else {
                        amount = "-" + amount
                    }
                    
                    if !asset.isBeam() {
                        rateString = ""
                    }
                    
                    var item = BMThreeLineItem(title: index == 90 ? Localizable.shared.strings.amount.uppercased() : "", detail: amount, subDetail: rateString , titleColor: .white, detailColor: asset.realAmount > 0 ? UIColor.main.brightSkyBlue : UIColor.main.heliotrope, subDetailColor: .white, titleFont: .boldSystemFont(ofSize: 15), detailFont: .systemFont(ofSize: 15), subDetailFont: .systemFont(ofSize: 15), hasArrow: false)
                    item.customObject = asset
                    details.append(item)

                    index += 1
                }
            }
        } else {
            if transaction.realRate > 0 {
                rateString = Localizable.shared.strings.rate_transaction.lowercased()
                
                let second = ExchangeManager.shared().exchangeValueAsset(withCurrency: Int64(transaction.realRate), amount: transaction.realAmount, assetID: UInt64(transaction.assetId))
                
                if transaction.isIncome {
                    rateString = "+\(second) " + "(" + rateString + ")"
                }
                else {
                    rateString = "-\(second) " + "(" + rateString + ")"
                }
            }
            else {
                rateString = "(" + rateString + ")"
            }
            
            details.append(BMThreeLineItem(title: Localizable.shared.strings.amount.uppercased(), detail: amount, subDetail: rateString , titleColor: .white, detailColor: transaction.isIncome ? UIColor.main.brightSkyBlue : UIColor.main.heliotrope, subDetailColor: .white, titleFont: .boldSystemFont(ofSize: 15), detailFont: .systemFont(ofSize: 15), subDetailFont: .systemFont(ofSize: 15), hasArrow: false))
        }
                
        if transaction.realFee > 0 && !isPaymentProof {
            let fee = String.currency(value: transaction.fee, name: "BEAM")
            details.append(BMThreeLineItem(title: Localizable.shared.strings.fee.uppercased(), detail: fee, subDetail: "", titleColor: .white, detailColor: .white, subDetailColor: .white, titleFont: .boldSystemFont(ofSize: 15), detailFont: .systemFont(ofSize: 15), subDetailFont: .systemFont(ofSize: 15), hasArrow: false))
        }
        
        if transaction.isDapps {
            details.append(BMMultiLineItem(title: Localizable.shared.strings.dapp_anme.uppercased(), detail: transaction.source(), detailFont: RegularFont(size: 16), detailColor: UIColor.white, copy: true))
            
            if let shader = transaction.contractCids {
                details.append(BMMultiLineItem(title: Localizable.shared.strings.app_shader_id.uppercased(), detail: shader, detailFont: RegularFont(size: 16), detailColor: UIColor.white, copy: true))
            }
        }
                
        if !transaction.comment.isEmpty && !isPaymentProof {
            details.append(BMMultiLineItem(title: Localizable.shared.strings.desc.uppercased(), detail: transaction.comment, detailFont: RegularFont(size: 16), detailColor: UIColor.white))
        }
        
        if !isPaymentProof {
            details.append(BMMultiLineItem(title: Localizable.shared.strings.transaction_id.uppercased(), detail: transaction.id, detailFont: RegularFont(size: 16), detailColor: UIColor.white, copy: true, showCopyButton: true))
        }

        
        if !transaction.isExpired() && !transaction.isFailed() && !transaction.kernelId.contains("000000000") {
            details.append(BMMultiLineItem(title: Localizable.shared.strings.kernel_id.uppercased(), detail:  transaction.kernelId, detailFont: RegularFont(size: 16), detailColor: UIColor.white, copy: true))
        }
         
     
        if transaction.isFailed() && !isPaymentProof {
            details.append(BMMultiLineItem(title: Localizable.shared.strings.failure_reason.uppercased(), detail: transaction.failureReason, detailFont: RegularFont(size: 16), detailColor: UIColor.main.red, copy: true))
        }
        
        
        if paymentProof == nil && transaction.hasPaymentProof() && isPaymentProof  {
            AppModel.sharedManager().getPaymentProof(transaction)
        }
    }
    
    public func actionItems() -> [BMPopoverMenu.BMPopoverMenuItem] {
        let transaction = self.transaction!

        var items = [BMPopoverMenu.BMPopoverMenuItem]()
        
        if transaction.canSaveContact() {
            items.append(BMPopoverMenu.BMPopoverMenuItem(name: Localizable.shared.strings.save_contact_title, icon: nil, action: .save_contact))
        }
        
        if !transaction.isMultiAssets() {
            items.append(BMPopoverMenu.BMPopoverMenuItem(name: Localizable.shared.strings.share_details, icon: nil, action: .share))
        }

        items.append(BMPopoverMenu.BMPopoverMenuItem(name: Localizable.shared.strings.copy_details, icon: nil, action: .copy))

        
        if !transaction.isIncome && !transaction.isShielded && !transaction.isDapps {
            items.append(BMPopoverMenu.BMPopoverMenuItem(name: Localizable.shared.strings.repeat_transaction, icon: nil, action: .repeat_transaction))
        }
        
        if transaction.canCancel && !transaction.isDapps {
            items.append(BMPopoverMenu.BMPopoverMenuItem(name: Localizable.shared.strings.cancel_transaction, icon: nil, action: .cancel_transaction))
        }
        
        if transaction.isDapps {
            items.append(BMPopoverMenu.BMPopoverMenuItem(name: Localizable.shared.strings.open_dapp, icon: nil, action: .open_dapp))
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
    
    public func openDapp() {
        if let apps = AppModel.sharedManager().apps as? [BMApp] {
            if let find = apps.first(where: { a in
                a.name == self.transaction?.appName
            }) {
                if let top = UIApplication.getTopMostViewController() {
                    AppModel.sharedManager().startApp(top, app: find)
                }
            }
            else {
                UIApplication.getTopMostViewController()?.alert(title: Localizable.shared.strings.dapp_not_found_title, message: Localizable.shared.strings.dapp_not_found_text, handler: { _ in
                    
                })
            }
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
                
                let proofDetail = BMMultiLineItem(title: Localizable.shared.strings.code.uppercased(), detail: proof.code, detailFont: RegularFont(size: 16), detailColor: UIColor.white, copy: true, showCopyButton: true)

                
                self.paymentProof = proof
                self.proofDetail = [proofDetail]
                
                self.onDataChanged?()
            }
        }
    }
}
