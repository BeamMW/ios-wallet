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

class SendTransactionViewModel: NSObject, WalletModelDelegate {

    private var isFocused = false
    public var copyAddress:String?

    public var amountError:String?
    public var toAddressError:String?
    public var newVersionError:String?

    public var comment = String.empty()
    public var shieldedInputsFee:UInt64 = 0
    
    public var outgoindAdderss:BMAddress?
    public var pickedOutgoingAddress:BMAddress?
    public var startedAddress:BMAddress?

    public var saveContact = true

    public var selectedContact:BMContact?

    private var addresses = [BMAddress]()
    public var isToken = false
    public var addressType = BMAddressTypeUnknown
    
    public var unlinkOnly = false {
        didSet {
            amountError = nil
            sendAll = false
        }
    }
    
    public var maxPrivacy = false {
        didSet {
            if(maxPrivacy) {
                if(AppModel.sharedManager().isToken(toAddress)) {
                    let params = AppModel.sharedManager().getTransactionParameters(toAddress)
                    if(AppModel.sharedManager().isMyAddress(params.address)) {
                        toAddressError = Localizable.shared.strings.cant_sent_max_to_my_address
                    }
                }
            }
            else if (toAddressError == Localizable.shared.strings.cant_sent_max_to_my_address) {
                toAddressError = nil
            }
            
            calculateFee()
        }
    }
    
    public func calculateFee() {
        let isShielded = (addressType == BMAddressTypeShielded || addressType == BMAddressTypeOfflinePublic ||
                            addressType == BMAddressTypeMaxPrivacy)
        
        AppModel.sharedManager().calculateFee(Double(amount) ?? 0, fee: (Double(fee) ?? 0), isShielded: isShielded) { (result, changed, shieldedInputsFee) in
            DispatchQueue.main.async {
                self.shieldedInputsFee = shieldedInputsFee
                let current = UInt64(self.fee) ?? 0
                if result > current {
                    self.fee = String(result)
                    self.minFee = self.fee
                    self.onFeeChanged?()
                }
                else if result != current {
                    self.fee = String(result)
                    self.minFee = self.fee
                    self.onFeeChanged?()
                }
            }
        }
    }
    
    public var requestedMaxPrivacy = false
    public var requestedOffline = false
    public var isPermanentAddress = false
    public var maxPrivacyDisabled = false
    public var offlineTokensCount = -1
    public var isMyAddress = false
    
    public var onDataChanged: (() -> Void)?
    public var onFeeChanged: (() -> Void)?

    func onMaxPrivacyTokensLeft(_ tokens: Int32) {
        DispatchQueue.main.async {
            self.offlineTokensCount = Int(tokens)
            self.onDataChanged?()
        }
    }
    
    public var onCalculateChanged : ((Double) -> Void)?

    public var sbbsAddress = String.empty()
    public var toAddress = String.empty() {
        didSet {
            toAddressError = nil
            isPermanentAddress = false
            maxPrivacyDisabled = false;
            offlineTokensCount = -1
            isMyAddress = false
            
            if(AppModel.sharedManager().isToken(toAddress)) {
                isToken = true
                
                let params = AppModel.sharedManager().getTransactionParameters(toAddress)
                
                sbbsAddress = params.address
                addressType = Int(params.getAddressType())
                maxPrivacy = params.isMaxPrivacy
                requestedMaxPrivacy = params.isMaxPrivacy
                requestedOffline = params.isOffline
                isPermanentAddress = params.isPermanentAddress
                
                if(params.amount > 0) {
                   amount = String.currency(value: params.amount)
                }
                                
                isMyAddress = AppModel.sharedManager().isMyAddress(params.address)
                
                if(isMyAddress && maxPrivacy) {
                    toAddressError = "Can not sent offline transaction to own address"
                }
               
                newVersionError = params.verionError
                
                calculateFee()
                checkAmountError()
            }
            else if(AppModel.sharedManager().isValidAddress(toAddress)) {
                sbbsAddress = toAddress
                addressType = BMAddressTypeUnknown
                newVersionError = nil

                isToken = false

                maxPrivacyDisabled = true;
                requestedMaxPrivacy = false;
                maxPrivacy = false
                calculateFee()
            }
            else {
                sbbsAddress = String.empty()
                addressType = BMAddressTypeUnknown

                isToken = false
                
                newVersionError = nil
            }
        }
    }
    
    public var amount = String.empty() {
        didSet {
            amountError = nil
            if !sendAll {
                calculateFee()
            }
        }
    }
    
    public var minFee = ""
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
                calculateFee()
            }
        }
    }
    
    var transaction: BMTransaction?{
        didSet{
            if let repeatTransaction = transaction{
                toAddress = repeatTransaction.receiverAddress
                if repeatTransaction.realAmount > 0 {
                    amount = String.currency(value: repeatTransaction.realAmount).replacingOccurrences(of: " BEAM", with: "")
                    comment = repeatTransaction.comment ?? ""
                }

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
        
        AppModel.sharedManager().addDelegate(self)
        
        fee = String(AppModel.sharedManager().getDefaultFeeInGroth())
        
        generateOutgoindAddress()
    }
    
    deinit {
        AppModel.sharedManager().removeDelegate(self)
    }
    
    public func send() {
        var sendedFee = Double(fee) ?? 0
        if shieldedInputsFee > 0 {
            sendedFee = sendedFee - Double(shieldedInputsFee)
        }
        
        AppModel.sharedManager().prepareSend(Double(amount) ?? 0, fee: sendedFee, to: toAddress, comment: comment, from: outgoindAdderss?.walletId, saveContact: saveContact, maxPrivacy: maxPrivacy)
        
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
        var isError = (!valid || expired || canSend != nil)
       
        let isMyAddress = AppModel.sharedManager().isMyAddress(toAddress)
        
        if(isMyAddress && maxPrivacy) {
            isError = true
        }
        
        if isError {
            amountError = nil
            toAddressError = nil
            
            if(isMyAddress && maxPrivacy) {
                toAddressError = "Can not sent offline transaction to own address"
            }
            else if !valid {
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
        var items = [BMMultiLineItem]()

        let to = "\(toAddress.prefix(6))...\(toAddress.suffix(6))"
        
        let contact = AppModel.sharedManager().findAddress(byID: sbbsAddress)
        
        let nameName = contact?.label
        let categories = contact?.categoriesName()
        
        if nameName != nil || categories != nil {
            if nameName?.isEmpty == true && categories?.string.isEmpty == true {
                items.append(BMMultiLineItem(title: Localizable.shared.strings.send_to, detail: to, detailFont: RegularFont(size: 16), detailColor: UIColor.white))
            }
            else {
                let detail = NSMutableAttributedString(string: "\(to)\nspace\n\(nameName ?? "")")
                let rangeName = (detail.string as NSString).range(of: String(nameName ?? ""))
                let spaceRange = (detail.string as NSString).range(of: String("space"))
                
                detail.addAttribute(NSAttributedString.Key.font, value: RegularFont(size: 16), range: rangeName)
                detail.addAttribute(NSAttributedString.Key.foregroundColor, value: Settings.sharedManager().isDarkMode ? UIColor.main.steel : UIColor.main.steelGrey, range: rangeName)
                
                detail.addAttribute(NSAttributedString.Key.font, value: LightFont(size: 5), range: spaceRange)
                detail.addAttribute(NSAttributedString.Key.foregroundColor, value: UIColor.clear, range: spaceRange)
                
                if categories != nil && categories?.string.isEmpty == false {
                    detail.append(NSAttributedString(string: " "))
                    detail.append(categories!)
                }
                
                let toItem = BMMultiLineItem(title: Localizable.shared.strings.send_to, detail: to, detailFont: RegularFont(size: 16), detailColor: UIColor.white)
                toItem.detailAttributedString = detail
                items.append(toItem)
            }
        }
        else {
            items.append(BMMultiLineItem(title: Localizable.shared.strings.send_to, detail: to, detailFont: RegularFont(size: 16), detailColor: UIColor.white))
        }
        
                
        if outgoindAdderss != nil {
            let fromName = outgoindAdderss?.label
            let fromCategories = outgoindAdderss?.categoriesName()
            let out = "\(outgoindAdderss!.walletId.prefix(6))...\(outgoindAdderss!.walletId.suffix(6))"

            if fromName != nil || fromCategories != nil {
                if fromName?.isEmpty == true && fromCategories?.string.isEmpty == true {
                    items.append(BMMultiLineItem(title: Localizable.shared.strings.outgoing_address.uppercased(), detail: out, detailFont: RegularFont(size: 16), detailColor: UIColor.white))
                }
                else {
                    let detail = NSMutableAttributedString(string: "\(out)\nspace\n\(fromName ?? "")")
                    let rangeName = (detail.string as NSString).range(of: String(fromName ?? ""))
                    let spaceRange = (detail.string as NSString).range(of: String("space"))
                    
                    detail.addAttribute(NSAttributedString.Key.font, value: RegularFont(size: 16), range: rangeName)
                    detail.addAttribute(NSAttributedString.Key.foregroundColor, value: Settings.sharedManager().isDarkMode ? UIColor.main.steel : UIColor.main.steelGrey, range: rangeName)
                    
                    detail.addAttribute(NSAttributedString.Key.font, value: LightFont(size: 5), range: spaceRange)
                    detail.addAttribute(NSAttributedString.Key.foregroundColor, value: UIColor.clear, range: spaceRange)
                    
                    if fromCategories != nil && fromCategories?.string.isEmpty == false {
                        detail.append(NSAttributedString(string: " "))
                        detail.append(fromCategories!)
                    }
                    
                    let toItem = BMMultiLineItem(title: Localizable.shared.strings.outgoing_address.uppercased(), detail: out, detailFont: RegularFont(size: 16), detailColor: UIColor.white)
                    toItem.detailAttributedString = detail
                    items.append(toItem)
                }
            }
            else {
                items.append(BMMultiLineItem(title: Localizable.shared.strings.outgoing_address.uppercased(), detail: out, detailFont: RegularFont(size: 16), detailColor: UIColor.white))
            }
        }

        if addressType == BMAddressTypeMaxPrivacy {
            items.append(BMMultiLineItem(title: Localizable.shared.strings.address_type.uppercased(), detail: Localizable.shared.strings.max_privacy_address, detailFont: RegularFont(size: 16), detailColor: UIColor.white, copy: false))
        }
        else if addressType == BMAddressTypeRegular {
            items.append(BMMultiLineItem(title: Localizable.shared.strings.address_type.uppercased(), detail: Localizable.shared.strings.regular, detailFont: RegularFont(size: 16), detailColor: UIColor.white, copy: false))
        }
        else if addressType == BMAddressTypeOfflinePublic {
            items.append(BMMultiLineItem(title: Localizable.shared.strings.address_type.uppercased(), detail: Localizable.shared.strings.public_offline_address, detailFont: RegularFont(size: 16), detailColor: UIColor.white, copy: false))
        }
        else if addressType == BMAddressTypeRegularPermanent {
            items.append(BMMultiLineItem(title: Localizable.shared.strings.address_type.uppercased(), detail: "\(Localizable.shared.strings.regular). \(Localizable.shared.strings.permanent)", detailFont: RegularFont(size: 16), detailColor: UIColor.white, copy: false))
        }
        else if addressType == BMAddressTypeShielded {
            items.append(BMMultiLineItem(title: Localizable.shared.strings.address_type.uppercased(), detail: Localizable.shared.strings.offline, detailFont: RegularFont(size: 16), detailColor: UIColor.white, copy: false))
        }
        else {
            items.append(BMMultiLineItem(title: Localizable.shared.strings.address_type.uppercased(), detail: Localizable.shared.strings.regular, detailFont: RegularFont(size: 16), detailColor: UIColor.white, copy: false))
        }
        
        if !Settings.sharedManager().isHideAmounts {
            let amountDetail = amountString(amount: amount)
            let amountItem = BMMultiLineItem(title: Localizable.shared.strings.amount_to_send.uppercased(), detail: amountDetail.string, detailFont: SemiboldFont(size: 16), detailColor: UIColor.main.heliotrope)
            amountItem.detailAttributedString = amountDetail
            items.append(amountItem)
            
            let totalFeeDetail = amountString(amount: fee, isFee: true)
            let feeItem = BMMultiLineItem(title: Localizable.shared.strings.transaction_fee.uppercased(), detail: totalFeeDetail.string, detailFont: SemiboldFont(size: 16), detailColor: UIColor.white)
            feeItem.detailAttributedString = totalFeeDetail
            items.append(feeItem)
            
            let total = AppModel.sharedManager().realTotal(Double(amount) ?? 0, fee: Double(fee) ?? 0)
            let totalString = String.currency(value: total)
            let totalDetail = amountString(amount: totalString.replacingOccurrences(of: " BEAM", with: ""))
            let totalItem = BMMultiLineItem(title: Localizable.shared.strings.total_utxo.uppercased(), detail: totalDetail.string, detailFont: SemiboldFont(size: 16), detailColor: UIColor.white)
            totalItem.detailAttributedString = totalDetail
            items.append(totalItem)            
        }
        
     
//        if !maxPrivacy {
//            items.append(BMMultiLineItem(title: Localizable.shared.strings.send_notice, detail: nil, detailFont: nil, detailColor: nil))
//        }
        
        return items
    }
    
    public func isNeedSaveContact() -> Bool {
        var address = toAddress
        if (AppModel.sharedManager().isToken(address)) {
            let params = AppModel.sharedManager().getTransactionParameters(address)
            address = params.address
        }
        
        let isContactFound = (AppModel.sharedManager().getContactFromId(address) != nil)
        let isMyAddress = AppModel.sharedManager().isMyAddress(address)
        return (selectedContact == nil && !isContactFound && !isMyAddress)
    }
    
    public func calculateChange() {
        let isShielded = (addressType == BMAddressTypeShielded || addressType == BMAddressTypeOfflinePublic ||
            addressType == BMAddressTypeMaxPrivacy)
        
        AppModel.sharedManager().calculateFee2((Double(amount) ?? 0), fee: (Double(fee) ?? 0), isShielded: isShielded) { (fee, change, shieldedInputsFee) in
            self.onCalculateChanged?(change)
        }
        
        if AppModel.sharedManager().isToken(toAddress) {
            _ = AppModel.sharedManager().getTransactionParameters(toAddress)
        }
    }
    
    public func canUnlink() -> Bool {
        return AppModel.sharedManager().walletStatus?.realShielded != 0
    }
    
    public func amountString(amount: String, isFee: Bool = false) -> NSMutableAttributedString {
        let amountString = isFee ? (amount + Localizable.shared.strings.groth + "\n") : (amount + Localizable.shared.strings.beam + "\n")
        let secondString = isFee ? AppModel.sharedManager().exchangeValueFee((Double(amount) ?? 0)) : AppModel.sharedManager().exchangeValue(Double(amount) ?? 0)
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
        return attributedTitle
    }
}
