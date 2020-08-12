//
// SendTransactionViewModel.swift
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

class SendTransactionViewModel: NSObject {

    private var isFocused = false
    public var copyAddress:String?

    public var amountError:String?
    public var toAddressError:String?

    public var comment = String.empty()
    
    public var outgoindAdderss:BMAddress?
    public var pickedOutgoingAddress:BMAddress?
    public var startedAddress:BMAddress?

    public var saveContact = true

    public var selectedContact:BMContact?

    private var addresses = [BMAddress]()
    
    public var unlinkOnly = false {
        didSet {
            amountError = nil
            sendAll = false
        }
    }
    
    public var maxPrivacy = false {
        didSet {
            if(maxPrivacy) {
                fee = String(AppModel.sharedManager().getMinMaxPrivacyFeeInGroth())
            }
            else {
                fee = String(AppModel.sharedManager().getDefaultFeeInGroth())
            }
        }
    }
    
    public var requestedMaxPrivacy = false
    public var requestedOffline = false
    public var isPermanentAddress = false
    public var maxPrivacyDisabled = false

    public var toAddress = String.empty() {
        didSet {
            toAddressError = nil
            isPermanentAddress = false
            maxPrivacyDisabled = false;

            if(AppModel.sharedManager().isToken(toAddress)) {
                let params = AppModel.sharedManager().getTransactionParameters(toAddress)
                maxPrivacy = params.isMaxPrivacy
                requestedMaxPrivacy = params.isMaxPrivacy
                requestedOffline = params.isOffline
                isPermanentAddress = params.isPermanentAddress
                
                if(params.amount > 0) {
                   amount = String.currency(value: params.amount)
                }
                
                if(maxPrivacy) {
                    fee = String(AppModel.sharedManager().getMinMaxPrivacyFeeInGroth())
                }
                else {
                    fee = String(AppModel.sharedManager().getDefaultFeeInGroth())
                }
                
                checkAmountError()
            }
            else if(AppModel.sharedManager().isValidAddress(toAddress)) {
                maxPrivacyDisabled = true;
                requestedMaxPrivacy = false;
                maxPrivacy = false
                fee = String(AppModel.sharedManager().getDefaultFeeInGroth())
            }
        }
    }
    
    public var amount = String.empty() {
        didSet {
            amountError = nil
        }
    }
    
    public var fee = String(0) {
        didSet{
            if sendAll {
                if unlinkOnly {
                    amount = AppModel.sharedManager().allUnlinkAmount(Double(fee) ?? 0)
                }
                else {
                    amount = AppModel.sharedManager().allAmount(Double(fee) ?? 0)
                }
            }
        }
    }
    
    public var sendAll = false {
        didSet{
            if sendAll {
                if unlinkOnly {
                    amount = AppModel.sharedManager().allUnlinkAmount(Double(fee) ?? 0)
                }
                else {
                    amount = AppModel.sharedManager().allAmount(Double(fee) ?? 0)
                }
            }
        }
    }
    
    var transaction: BMTransaction?{
        didSet{
            if let repeatTransaction = transaction{
                toAddress = repeatTransaction.receiverAddress
                amount = String.currency(value: repeatTransaction.realAmount)
                fee = String(repeatTransaction.realFee)
                comment = repeatTransaction.comment
            }
        }
    }
    
    var isNeedFocus:Bool {
        get {
            if !isFocused && transaction == nil {
                isFocused = true
                
                if let address = UIPasteboard.general.string {
                    if AppModel.sharedManager().isValidAddress(address)
                    {
                        copyAddress = address
                        
                        return true
                    }
                }
            }
            
            return false
        }
    }
    

    override init() {
        super.init()
        
        fee = String(AppModel.sharedManager().getDefaultFeeInGroth())
        
        generateOutgoindAddress()
    }
    
    public func send() {
        AppModel.sharedManager().prepareSend(Double(amount) ?? 0, fee: Double(fee) ?? 0, to: toAddress, comment: comment, from: outgoindAdderss?.walletId, saveContact: saveContact, maxPrivacy: maxPrivacy)
        
        AppStoreReviewManager.incrementAppTransactions()
    }
    
    public func checkAmountError() {
        if unlinkOnly {
            let canSend = AppModel.sharedManager().canSendOnlyUnlink((Double(amount) ?? 0), fee: (Double(fee) ?? 0), to: toAddress)
            
            if canSend != Localizable.shared.strings.incorrect_address && ((Double(amount) ?? 0)) > 0 {
                amountError = canSend
            }
            else{
                amountError = nil
            }
        }
        else {
            let canSend = AppModel.sharedManager().canSend((Double(amount) ?? 0), fee: (Double(fee) ?? 0), to: toAddress)
            
            if canSend != Localizable.shared.strings.incorrect_address && ((Double(amount) ?? 0)) > 0 {
                amountError = canSend
            }
            else{
                amountError = nil
            }
        }
    }
    
    public func checkFeeError() {
        if sendAll {
            if let a = Double(amount), let f = Double(fee) {
                if a == 0 && f > 0  {
                    if unlinkOnly {
                        amount = AppModel.sharedManager().allUnlinkAmount(0)
                        amountError = AppModel.sharedManager().feeError(f)
                    }
                    else {
                        amount = AppModel.sharedManager().allAmount(0)
                        amountError = AppModel.sharedManager().feeError(f)
                    }
                }
                else if a == 0 {
                    amountError = Localizable.shared.strings.amount_zero
                }
            }
        }
    }
    
    public func canSend() -> Bool {
        let valid = AppModel.sharedManager().isValidAddress(toAddress)
        let expired = AppModel.sharedManager().isExpiredAddress(toAddress)
        let canSend = AppModel.sharedManager().canSend((Double(amount) ?? 0), fee: (Double(fee) ?? 0), to: toAddress)
        let isError = (!valid || expired || canSend != nil)
        
        if isError {
            amountError = nil
            toAddressError = nil
            
            if !valid {
                toAddressError = Localizable.shared.strings.incorrect_address
            }
            else if expired {
                toAddressError = Localizable.shared.strings.address_is_expired
            }
            
            if amount.isEmpty {
                amountError = Localizable.shared.strings.amount_empty
            }
            else if canSend != Localizable.shared.strings.incorrect_address {
                amountError = canSend
            }
        }
        
        return !isError
    }
    
    private func generateOutgoindAddress() {
        AppModel.sharedManager().generateNewWalletAddress { (address, error) in
            if let result = address {
                DispatchQueue.main.async {
                    self.outgoindAdderss = result
                    self.startedAddress = BMAddress.fromAddress(result)
                }
            }
        }
    }
    
    public func revertOutgoingAddress() {
        if let pickedAddress = self.pickedOutgoingAddress {
            if pickedAddress.walletId == startedAddress?.walletId {
                AppModel.sharedManager().deleteAddress(startedAddress?.walletId)
            }
            else if pickedAddress.label != outgoindAdderss?.label || pickedAddress.categories != outgoindAdderss?.categories || pickedAddress.duration != outgoindAdderss?.duration {
                
                if pickedAddress.duration != outgoindAdderss?.duration {
                    if pickedAddress.duration > 0 {
                        pickedAddress.isChangedDate = true
                    }
                }
                
                AppModel.sharedManager().edit(pickedAddress)
            }
            
            if pickedAddress.walletId != startedAddress?.walletId {
                AppModel.sharedManager().deleteAddress(startedAddress?.walletId)
            }
        }
        else if let address = outgoindAdderss {
            AppModel.sharedManager().deleteAddress(address.walletId)
        }
    }
    
    public func searchForContacts(searchIndex:Int) -> [BMContact] {
        if searchIndex == 0 {
            var contacts = [BMContact]()
            
            if let _contacts = AppModel.sharedManager().contacts as? [BMContact] {
                contacts.append(contentsOf: _contacts)
            }
            
            if !toAddress.isEmpty {
                let filterdObjects = contacts.filter {
                    $0.name.lowercased().contains(toAddress.lowercased()) ||
                        $0.address.label.lowercased().contains(toAddress.lowercased()) ||
                        $0.address.categoriesName().string.lowercased().contains(toAddress.lowercased()) ||
                        $0.address.walletId.lowercased().starts(with: toAddress.lowercased())
                }
                contacts.removeAll()
                contacts.append(contentsOf: filterdObjects)
            }
            
            return contacts
        }
        else{
            var contacts = [BMContact]()

            if let addresses = AppModel.sharedManager().walletAddresses {
                self.addresses = addresses as! [BMAddress]
            }
            
            self.addresses = self.addresses.filter { $0.isExpired() == false && $0.walletId != self.outgoindAdderss?.walletId}
            
            if !toAddress.isEmpty {
                let filterdObjects = self.addresses.filter {
                        $0.label.lowercased().contains(toAddress.lowercased()) ||
                        $0.categoriesName().string.lowercased().contains(toAddress.lowercased()) ||
                        $0.walletId.lowercased().starts(with: toAddress.lowercased())
                }
                
                for address in filterdObjects {
                    let contact = BMContact()
                    contact.name = address.label
                    contact.address = address
                    contacts.append(contact)
                }
            }
            else{
                for address in self.addresses {
                    let contact = BMContact()
                    contact.name = address.label
                    contact.address = address
                    contacts.append(contact)
                }
            }
            
            return contacts
        }
    }
    
    public func buildBMMultiLineItems() -> [BMMultiLineItem]{
        let total = AppModel.sharedManager().realTotal(Double(amount) ?? 0, fee: Double(fee) ?? 0)
        let totalString = String.currency(value: total) + Localizable.shared.strings.beam
        
        let to = "\(toAddress.prefix(6))...\(toAddress.suffix(6))"
        var items = [BMMultiLineItem]()
        items.append(BMMultiLineItem(title: Localizable.shared.strings.send_to, detail: to, detailFont: RegularFont(size: 16), detailColor: UIColor.white))
        
        if outgoindAdderss != nil {
            let out = outgoindAdderss!.walletId //"\(outgoindAdderss!.walletId.prefix(6))...\(outgoindAdderss!.walletId.suffix(6))"
            items.append(BMMultiLineItem(title: Localizable.shared.strings.outgoing_address.uppercased(), detail: out, detailFont: RegularFont(size: 16), detailColor: UIColor.white))
        }
        
        if maxPrivacy && !requestedOffline {
            items.append(BMMultiLineItem(title: Localizable.shared.strings.transaction_type.uppercased(), detail: Localizable.shared.strings.max_privacy_title, detailFont: RegularFont(size: 16), detailColor: UIColor.white))
        }
        else if maxPrivacy && requestedOffline {
            items.append(BMMultiLineItem(title: Localizable.shared.strings.transaction_type.uppercased(), detail: "\(Localizable.shared.strings.max_privacy_title),\(Localizable.shared.strings.offline.lowercased())", detailFont: RegularFont(size: 16), detailColor: UIColor.white))
        }
        
        let amountString = amount + Localizable.shared.strings.beam + "\n"
        let secondString = AppModel.sharedManager().exchangeValue(Double(amount) ?? 0)
        let attributedString = amountString + "space\n" + secondString

        let attributedTitle = NSMutableAttributedString(string: attributedString)
        let rangeAmount = (attributedString as NSString).range(of: String(amountString))
        let rangeSecond = (attributedString as NSString).range(of: String(secondString))
        let spaceRange = (attributedString as NSString).range(of: String("space"))

        attributedTitle.addAttribute(NSAttributedString.Key.font, value: SemiboldFont(size: 16) , range: rangeAmount)
        attributedTitle.addAttribute(NSAttributedString.Key.foregroundColor, value: UIColor.main.heliotrope , range: rangeAmount)
        
        attributedTitle.addAttribute(NSAttributedString.Key.font, value: LightFont(size: 5), range: spaceRange)
        attributedTitle.addAttribute(NSAttributedString.Key.foregroundColor, value: UIColor.clear, range: spaceRange)
        
        attributedTitle.addAttribute(NSAttributedString.Key.font, value: RegularFont(size: 14), range: rangeSecond)
        attributedTitle.addAttribute(NSAttributedString.Key.foregroundColor, value: Settings.sharedManager().isDarkMode ? UIColor.main.steel : UIColor.main.steelGrey, range: rangeSecond)

        let amountItem = BMMultiLineItem(title: Localizable.shared.strings.amount_to_send.uppercased(), detail: attributedString, detailFont: SemiboldFont(size: 16), detailColor: UIColor.main.heliotrope)
        amountItem.detailAttributedString = attributedTitle
        items.append(amountItem)
              
        items.append(BMMultiLineItem(title: Localizable.shared.strings.transaction_fee.uppercased(), detail: fee + Localizable.shared.strings.groth, detailFont: SemiboldFont(size: 16), detailColor: UIColor.main.heliotrope))
        items.append(BMMultiLineItem(title: Localizable.shared.strings.total_utxo.uppercased(), detail: totalString, detailFont: SemiboldFont(size: 16), detailColor: UIColor.white))
        items.append(BMMultiLineItem(title: Localizable.shared.strings.send_notice, detail: nil, detailFont: nil, detailColor: nil))
        
        return items
    }
    
    public func isNeedSaveContact() -> Bool {
        let isContactFound = (AppModel.sharedManager().getContactFromId(toAddress) != nil)
        let isMyAddress = AppModel.sharedManager().isMyAddress(toAddress)
        return (selectedContact == nil && !isContactFound && !isMyAddress)
    }
    
    public func calculateChange() {
        AppModel.sharedManager().calculateChange(Double(amount) ?? 0, fee:  Double(fee) ?? 0)
    }
    
    public func canUnlink() -> Bool {
        return AppModel.sharedManager().walletStatus?.realShielded != 0
    }
}
