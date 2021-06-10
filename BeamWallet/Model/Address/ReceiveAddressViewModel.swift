//
// ReceiveAddressViewModel.swift
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

class ReceiveAddressViewModel: NSObject {
    
    enum TransactionOptions: Int {
        case regular = 0
        case privacy = 1
    }
    
    enum ExpireOptions: Int {
        case oneTime = 0
        case parmanent = 1
    }
    
    enum ReceiveAddressViewModelSaveState: Int {
        case none = 0
        case new = 1
        case edit = 2
    }
    
    public var needReloadButtons = false

    public var transactionComment = String.empty()
    
    public var onAddressCreated: ((Error?) -> Void)?
    public var onDataChanged: (() -> Void)?
    public var onShared: (() -> Void)?
        
    public var address: BMAddress!
    public var transaction = TransactionOptions.regular

    public var isShared = false
    
    public var amount: String? {
        didSet {
            generateTokens()
            
            let amount = Double(self.amount ?? "0") ?? 0
            let second = ExchangeManager.shared().exchangeValue(withZero: amount)
            secondAmount = second
        }
    }
    
    public var secondAmount: String?
    
    override init() {
        super.init()
        
        let amount = Double(self.amount ?? "0") ?? 0
        let second = ExchangeManager.shared().exchangeValue(withZero: amount)
        secondAmount = second
    }
    
    public func generateTokens() {
        let isOwn = AppModel.sharedManager().checkIsOwnNode()
        
        let bamount = Double(amount ?? "0") ?? 0
        
        if isOwn {
            AppModel.sharedManager().generateMaxPrivacyAddress(address.walletId, amount: bamount) { (token) in
                self.address.maxPrivacyToken = token;
            }
        }

        address.offlineToken = AppModel.sharedManager().generateOfflineAddress(address.walletId, amount: bamount)
    }
    
    public func createAddress() {
        AppModel.sharedManager().generateNewWalletAddress({ (address, error) in
            if let result = address {
                self.address = result
                self.generateTokens()
            }
            self.onAddressCreated?(error)
        })
    }
    
    public func revertChanges() {
        var deleted = false
        
        if !isShared {
            deleted = true
            AppModel.sharedManager().deleteAddress(address?.walletId)
        }
        
        if !deleted {
            if let add = address {
                AppModel.sharedManager().setTransactionComment(add.walletId, comment: transactionComment)
            }
        }
    }
    
    public func isNeedAskToSave() -> ReceiveAddressViewModelSaveState {
        if !isShared {
            return .new
        }
        return .none
    }
    
    public func searchForContacts() -> [BMContact] {
        var contacts = [BMContact]()
        
        guard var addresses = AppModel.sharedManager().walletAddresses as? [BMAddress] else {
            return contacts
        }
        
        let searchText = self.address.label
        
        addresses = addresses.filter { $0.isExpired() == false && $0.walletId != self.address.walletId}
        
        if !searchText.isEmpty {
            let filterdObjects = addresses.filter {
                $0.label.lowercased().contains(searchText.lowercased())
            }
            
            for address in filterdObjects {
                let contact = BMContact()
                contact.name = address.label
                contact.address = address
                contacts.append(contact)
            }
        }
        
        return contacts
    }
    
    public func onShare(token: String) {
        self.showShareDialog(token)
    }
    
    private func showPopoverMenu(_ items:[BMPopoverMenu.BMPopoverMenuItem]) {
        BMPopoverMenu.show(menuArray: items, done: { selectedItem in
            if let item = selectedItem {
                switch item.action {
                case .share_online_token:
                    break
                case .share_offline_token:
                    if let token = self.address.offlineToken {
                        self.showShareDialog(token)
                    }
                    break
                case .share_pool_token:
                    self.showShareDialog(self.address.walletId)
                    break
                default:
                    return
                }
            }
        }) {}
    }
    
    private func showShareDialog(_ token:String) {
        if let top = UIApplication.getTopMostViewController() {
            let share = token
            let vc = UIActivityViewController(activityItems: [share], applicationActivities: [])
            vc.completionWithItemsHandler = { [weak self] (activityType: UIActivity.ActivityType?, completed: Bool, _: [Any]?, _: Error?) in
                if completed {
                    self?.isShared = true
                    
                    if activityType == UIActivity.ActivityType.copyToPasteboard {
                        ShowCopied(text: Localizable.shared.strings.address_copied)
                    }
                    
                    self?.onShared?()
                }
            }
            vc.excludedActivityTypes = [UIActivity.ActivityType.assignToContact, UIActivity.ActivityType.print, UIActivity.ActivityType.openInIBooks]
            top.present(vc, animated: true)
        }
    }
}
