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

    public var outgoindAdderss:BMAddress?
    public var saveContact = true

    private var isFocused = false
    public var copyAddress:String?

    public var amountError:String?
    public var toAddressError:String?
    public var newVersionError:String?

    public var comment = String.empty()
    public var shieldedInputsFee:UInt64 = 0
    
    public var selectedContact:BMContact? {
        didSet{
            self.onContactChanged?(true)
        }
    }

    public var tokensLeft = 0
    private var addresses = [BMAddress]()
    public var isToken = false
   
    public var isSendOffline = false {
        didSet {
            calculateFee()
        }
    }
    public var addressType = BMAddressTypeUnknown {
        didSet {
            isSendOffline = false
            self.onAddressTypeChanged?(true)
        }
    }
    
    public var isNeedDisplaySegmentCell:Bool {
        get {
            return addressType == BMAddressTypeShielded && isToken
        }
    }
    
    public var maxPrivacy:Bool = false
    
    public var selectedAssetId = 0
    public var selectedCurrencyString: String {
        get {
            return AssetsManager.shared().getAsset(Int32(selectedAssetId))?.unitName ?? ""
        }
    }
    
    public var secondAmount:String {
        get {
            return ExchangeManager.shared().exchangeValueAsset(Double(inputAmount) ?? 0, assetID: UInt64(selectedAssetId))
        }
    }
    
    public func calculateFee() {
        let isShielded = (addressType == BMAddressTypeShielded || addressType == BMAddressTypeOfflinePublic ||
                            addressType == BMAddressTypeMaxPrivacy || isSendOffline)
        
        AppModel.sharedManager().calculateFee(Double(amount) ?? 0, assetId: Int32(selectedAssetId), fee: (Double(fee) ?? 0), isShielded: isShielded) { (result, changed, shieldedInputsFee) in
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
    public var isMyAddress = false
    
    public var onDataChanged: (() -> Void)?
    public var onFeeChanged: (() -> Void)?
    
    public var onCalculateChanged : ((Double) -> Void)?
    public var onContactChanged : ((Bool) -> Void)?
    public var onAddressTypeChanged : ((Bool) -> Void)?
    public var onTokensCountChanged : ((Int) -> Void)?

    public var saveContactName = String.empty()
    public var sbbsAddress = String.empty()
    public var toAddress = String.empty() {
        didSet {
            toAddressError = nil
            isPermanentAddress = false
            isMyAddress = false
            
            if(AppModel.sharedManager().isToken(toAddress)) {
                isToken = true
                
                let params = AppModel.sharedManager().getTransactionParameters(toAddress)
                
                selectedAssetId = Int(params.assetId)
                sbbsAddress = params.address
                addressType = Int(params.newAddressType)
                maxPrivacy = params.isMaxPrivacy
                requestedMaxPrivacy = params.isMaxPrivacy
                requestedOffline = params.isOffline
                isPermanentAddress = params.isPermanentAddress
                
                if(params.amount > 0) {
                    amount = String.currency(value: params.amount).replacingOccurrences(of: " BEAM", with: "")
                }
                                
                isMyAddress = AppModel.sharedManager().isMyAddress(params.address)
                
                newVersionError = params.verionError
                
                calculateFee()
                checkAmountError()
            }
            else if(AppModel.sharedManager().isValidAddress(toAddress)) {
                sbbsAddress = toAddress
                addressType = BMAddressTypeRegular
                newVersionError = nil

                isToken = false

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
    
    public var inputAmount = String.empty() {
        didSet {
            amountError = nil
            if !sendAll {
                calculateFee()
            }
        }
    }
    public var amount: String {
        set {
            inputAmount = newValue
        }
        get {
            return getAmount
        }
    }
    
    public var getAmount: String {
        return inputAmount
    }
    
    public var minFee = ""
    public var fee = String(0) {
        didSet{
            if sendAll {
                amount = AppModel.sharedManager().allAmount(Double(fee) ?? 0, assetId: Int32(selectedAssetId))
            }
        }
    }
    
    public var sendAll = false {
        didSet{
            if sendAll {
                amount = AppModel.sharedManager().allAmount(Double(fee) ?? 0, assetId: Int32(selectedAssetId))
                calculateFee()
            }
        }
    }
    
    var transaction: BMTransaction?{
        didSet{
            if let repeatTransaction = transaction {
                if repeatTransaction.token.isEmpty {
                    toAddress = repeatTransaction.receiverAddress
                }
                else {
                    toAddress = repeatTransaction.token
                }
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
    
    private func generateOutgoindAddress() {
        AppModel.sharedManager().generateNewWalletAddress { (address, error) in
            if let result = address {
                DispatchQueue.main.async {
                    self.outgoindAdderss = result
                }
            }
        }
    }
    
    public func revertOutgoingAddress() {
        if let address = outgoindAdderss {
            AppModel.sharedManager().deleteAddress(address.walletId)
        }
    }
    
    public func send() {
        var sendedFee = Double(fee) ?? 0
        if shieldedInputsFee > 0 {
            sendedFee = sendedFee - Double(shieldedInputsFee)
        }
        
        AppModel.sharedManager().prepareSend(Double(amount) ?? 0, fee: sendedFee, assetId: Int32(selectedAssetId), to: toAddress, comment: comment, from: outgoindAdderss?.walletId, saveContact: saveContact, isOffline: isSendOffline)

       // AppModel.sharedManager().prepareSend(Double(amount) ?? 0, fee: sendedFee, to: toAddress, comment: comment, contactName: saveContactName, maxPrivacy: maxPrivacy)

        AppStoreReviewManager.incrementAppTransactions()
    }
    
    public func checkAmountError() {
        let canSend = AppModel.sharedManager().canSend((Double(amount) ?? 0), assetId: Int32(selectedAssetId), fee: (Double(fee) ?? 0), to: toAddress)
        
        if canSend != Localizable.shared.strings.incorrect_address && ((Double(amount) ?? 0)) > 0 {
            amountError = canSend
        }
        else{
            amountError = nil
        }
    }
    
    public func checkFeeError() {
        if sendAll {
            if let a = Double(amount), let f = Double(fee) {
                if a == 0 && f > 0  {
                    amount = AppModel.sharedManager().allAmount(0, assetId: Int32(selectedAssetId))
                    amountError = AppModel.sharedManager().feeError(f)
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
        let canSend = AppModel.sharedManager().canSend((Double(amount) ?? 0), assetId: Int32(selectedAssetId), fee: (Double(fee) ?? 0), to: toAddress)
        
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
        
        var contact = AppModel.sharedManager().findAddress(byID: sbbsAddress)
        if contact == nil {
            contact = AppModel.sharedManager().findAddress(byID: toAddress)
        }
        let nameName = contact?.label
        
        if nameName != nil  {
            if nameName?.isEmpty == true  {
                items.append(BMMultiLineItem(title: Localizable.shared.strings.send_to, detail: to, detailFont: RegularFont(size: 16), detailColor: UIColor.white))
            }
            else {
                let detail = NSMutableAttributedString(string: "\(nameName ?? "")\nspace\n\(to)")
                let rangeName = (detail.string as NSString).range(of: String(nameName ?? ""))
                let spaceRange = (detail.string as NSString).range(of: String("space"))
                let rangeAddress = (detail.string as NSString).range(of: String(to))

                detail.addAttribute(NSAttributedString.Key.font, value: RegularFont(size: 16), range: rangeName)
                detail.addAttribute(NSAttributedString.Key.foregroundColor, value: UIColor.white, range: rangeName)
                detail.addAttribute(NSAttributedString.Key.foregroundColor, value: Settings.sharedManager().isDarkMode ? UIColor.main.steel : UIColor.main.steelGrey, range: rangeAddress)

                detail.addAttribute(NSAttributedString.Key.font, value: LightFont(size: 5), range: spaceRange)
                detail.addAttribute(NSAttributedString.Key.foregroundColor, value: UIColor.clear, range: spaceRange)
                                
                let toItem = BMMultiLineItem(title: Localizable.shared.strings.send_to, detail: to, detailFont: RegularFont(size: 16), detailColor: UIColor.white)
                toItem.detailAttributedString = detail
                items.append(toItem)
            }
        }
        else {
            items.append(BMMultiLineItem(title: Localizable.shared.strings.send_to, detail: to, detailFont: RegularFont(size: 16), detailColor: UIColor.white))
        }
        
                
        if outgoindAdderss != nil {
            let out = "\(outgoindAdderss!.walletId.prefix(6))...\(outgoindAdderss!.walletId.suffix(6))"
            items.append(BMMultiLineItem(title: Localizable.shared.strings.outgoing_address.uppercased(), detail: out, detailFont: RegularFont(size: 16), detailColor: UIColor.white))
        }

        if addressType == BMAddressTypeMaxPrivacy {
            items.append(BMMultiLineItem(title: Localizable.shared.strings.transaction_type.uppercased(), detail: Localizable.shared.strings.max_privacy.localized, detailFont: RegularFont(size: 16), detailColor: UIColor.white, copy: false))
        }
        else if addressType == BMAddressTypeOfflinePublic {
            items.append(BMMultiLineItem(title: Localizable.shared.strings.transaction_type.uppercased(), detail: Localizable.shared.strings.public_offline.localized, detailFont: RegularFont(size: 16), detailColor: UIColor.white, copy: false))
        }
        else {
            items.append(BMMultiLineItem(title: Localizable.shared.strings.transaction_type.uppercased(), detail: self.isSendOffline ? Localizable.shared.strings.offline.localized : Localizable.shared.strings.regular.localized, detailFont: RegularFont(size: 16), detailColor: UIColor.white, copy: false))
        }

        
        if !Settings.sharedManager().isHideAmounts {
            let amountDetail = amountString(amount: amount, isFee: false, assetId: self.selectedAssetId)
            let amountItem = BMMultiLineItem(title: Localizable.shared.strings.amount_to_send.uppercased(), detail: amountDetail.string, detailFont: SemiboldFont(size: 16), detailColor: UIColor.main.heliotrope)
            amountItem.detailAttributedString = amountDetail
            items.append(amountItem)
            
            let total = AppModel.sharedManager().realTotal(0.0, fee: Double(fee) ?? 0.0, assetId: 0)
            let totalFeeDetail = amountString(amount: String(total), isFee: true, assetId: 0, color: .white)
            let feeItem = BMMultiLineItem(title: Localizable.shared.strings.transaction_fee.uppercased(), detail: totalFeeDetail.string, detailFont: SemiboldFont(size: 16), detailColor: UIColor.white)
            feeItem.detailAttributedString = totalFeeDetail
            items.append(feeItem)
        }
        
        
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
    
//    private func isNeedSaveContact() -> Bool {
//        return (saveContactName.isEmpty)
//    }
    
    public func calculateChange() {
        let isShielded = (addressType == BMAddressTypeShielded || addressType == BMAddressTypeOfflinePublic ||
            addressType == BMAddressTypeMaxPrivacy || isSendOffline)
        
        AppModel.sharedManager().calculateFee((Double(amount) ?? 0), assetId: Int32(selectedAssetId), fee: (Double(fee) ?? 0), isShielded: isShielded) { (fee, change, shieldedInputsFee) in
            self.onCalculateChanged?(change)
        }
    }
    
    func onMaxPrivacyTokensLeft(_ tokens: Int32) {
        DispatchQueue.main.async {
            self.tokensLeft = Int(tokens)
            self.onTokensCountChanged?(self.tokensLeft)
        }
    }
    
    public func amountString(amount: String, isFee:Bool, assetId:Int, color: UIColor? = nil, doubleAmount:Double = 0.0) -> NSMutableAttributedString {
        let assetName = (AssetsManager.shared().getAsset(Int32(assetId))?.unitName ?? "") + " "
        
        let amountString =  isFee ? ((amount + Localizable.shared.strings.beam + "\n")) : ((amount + " " + assetName + "\n"))
        var secondString = isFee ? ExchangeManager.shared().exchangeValueAsset(Double(amount) ?? 0, assetID: UInt64(0)) :
            ExchangeManager.shared().exchangeValueAsset(Double(amount) ?? 0, assetID: UInt64(self.selectedAssetId))
        if doubleAmount > 0.0 {
            secondString = isFee ? ExchangeManager.shared().exchangeValue(withZero: doubleAmount) :  ExchangeManager.shared().exchangeValueAsset(doubleAmount, assetID: UInt64(self.selectedAssetId))
        }
        let attributedString = amountString + "space\n" + secondString
        
        let attributedTitle = NSMutableAttributedString(string: attributedString)
        let rangeAmount = (attributedString as NSString).range(of: String(amountString))
        let rangeSecond = (attributedString as NSString).range(of: String(secondString))
        let spaceRange = (attributedString as NSString).range(of: String("space"))
        
        attributedTitle.addAttribute(NSAttributedString.Key.font, value: SemiboldFont(size: 16) , range: rangeAmount)
        if let color = color {
            attributedTitle.addAttribute(NSAttributedString.Key.foregroundColor, value: color, range: rangeAmount)
        }
        else {
            attributedTitle.addAttribute(NSAttributedString.Key.foregroundColor, value: UIColor.main.heliotrope , range: rangeAmount)
        }
        
        attributedTitle.addAttribute(NSAttributedString.Key.font, value: LightFont(size: 5), range: spaceRange)
        attributedTitle.addAttribute(NSAttributedString.Key.foregroundColor, value: UIColor.clear, range: spaceRange)
        
        attributedTitle.addAttribute(NSAttributedString.Key.font, value: RegularFont(size: 14), range: rangeSecond)
        attributedTitle.addAttribute(NSAttributedString.Key.foregroundColor, value: Settings.sharedManager().isDarkMode ? UIColor.main.steel : UIColor.main.steelGrey, range: rangeSecond)
        return attributedTitle
    }
}
