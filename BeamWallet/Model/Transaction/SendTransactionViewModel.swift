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

    public var selectedSearchIndex = 0

    public var selectedContact:BMContact?

    public var contacts = [BMContact]()
    private var addresses = [BMAddress]()
    
    public var toAddress = String.empty() {
        didSet {
            toAddressError = nil
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
                amount = AppModel.sharedManager().allAmount(Double(fee) ?? 0)
            }
        }
    }
    
    public var sendAll = false {
        didSet{
            if sendAll {
                amount = AppModel.sharedManager().allAmount(Double(fee) ?? 0)
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
        AppModel.sharedManager().prepareSend(Double(amount) ?? 0, fee: Double(fee) ?? 0, to: toAddress, comment: comment, from: outgoindAdderss?.walletId, saveContact: saveContact)
        
        AppStoreReviewManager.incrementAppTransactions()
    }
    
    public func checkAmountError() -> String? {
        let canSend = AppModel.sharedManager().canSend((Double(amount) ?? 0), fee: (Double(fee) ?? 0), to: toAddress)
       
        if canSend != Localizable.shared.strings.incorrect_address && ((Double(amount) ?? 0)) > 0 {
            amountError = canSend
        }
        else{
            amountError = nil
        }
        
        return amountError
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
    
    public func searchForContacts() {
        if selectedSearchIndex == 0 {
            self.contacts.removeAll()
            
            if let contacts = AppModel.sharedManager().contacts as? [BMContact] {
                self.contacts.append(contentsOf: contacts)
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
        }
        else{
            self.contacts.removeAll()

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
                    self.contacts.append(contact)
                }
            }
            else{
                for address in self.addresses {
                    let contact = BMContact()
                    contact.name = address.label
                    contact.address = address
                    self.contacts.append(contact)
                }
            }
        }
    }
    
    public func buildConfirmItems() -> [ConfirmItem]{
        let total = AppModel.sharedManager().realTotal(Double(amount) ?? 0, fee: Double(fee) ?? 0)
        let totalString = String.currency(value: total) + Localizable.shared.strings.beam
        
        var items = [ConfirmItem]()
        items.append(ConfirmItem(title: Localizable.shared.strings.send_to, detail: toAddress, detailFont: RegularFont(size: 16), detailColor: UIColor.white))
        
        if outgoindAdderss != nil {
            items.append(ConfirmItem(title: Localizable.shared.strings.outgoing_address.uppercased(), detail: outgoindAdderss!.walletId, detailFont: RegularFont(size: 16), detailColor: UIColor.white))
        }
        
        items.append(ConfirmItem(title: Localizable.shared.strings.amount_to_send.uppercased(), detail: amount + Localizable.shared.strings.beam, detailFont: SemiboldFont(size: 16), detailColor: UIColor.main.heliotrope))
        items.append(ConfirmItem(title: Localizable.shared.strings.transaction_fee.uppercased(), detail: fee + Localizable.shared.strings.groth, detailFont: SemiboldFont(size: 16), detailColor: UIColor.main.heliotrope))
        items.append(ConfirmItem(title: Localizable.shared.strings.total_utxo.uppercased(), detail: totalString, detailFont: SemiboldFont(size: 16), detailColor: UIColor.white))
        items.append(ConfirmItem(title: Localizable.shared.strings.send_notice, detail: nil, detailFont: nil, detailColor: nil))
        
        return items
    }
    
    public func isNeedSaveContact() -> Bool {
        let isContactFound = (AppModel.sharedManager().getContactFromId(toAddress) != nil)
        let isMyAddress = AppModel.sharedManager().isMyAddress(toAddress)
        return (selectedContact == nil && !isContactFound && !isMyAddress)
    }
}
