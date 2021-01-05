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
    
    struct TokenValue {
        let name: String
        let value: String
        let info: String
    }
    
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
    
    public var values = [TokenValue]()
    
    public var address: BMAddress!
    public var expire = ExpireOptions.oneTime {
        didSet {
            if address != nil {
//                let hours = expire == .oneTime ? Settings.sharedManager().maxAddressDurationHours : 0
//                address.duration = UInt64(hours == Settings.sharedManager().maxAddressDurationHours ? Settings.sharedManager().maxAddressDurationSeconds : 0)
//
//                AppModel.sharedManager().setExpires(Int32(hours), toAddress: address.walletId)
                
                generateTokens()
            }
        }
    }
    public var transaction = TransactionOptions.regular {
        didSet {
            generateTokens()
        }
    }

    public var isShared = false
    
    public var amount: String? {
        didSet {
            generateTokens()
        }
    }
    
    override init() {
        super.init()
    }
    
    public func generateTokens() {
        let isOwn = AppModel.sharedManager().checkIsOwnNode()
        
        let bamount = Double(amount ?? "0") ?? 0
        let isPermanentAddress = (expire == ExpireOptions.parmanent)
        
        address.onlineToken = AppModel.sharedManager().generateRegularAddress(address.walletId, amount: bamount, isPermanentAddress: isPermanentAddress)
        
        if isOwn {
            AppModel.sharedManager().generateMaxPrivacyAddress(address.walletId, amount: bamount) { (token) in
                self.address.maxPrivacyToken = token;
            }
            address.offlineToken = AppModel.sharedManager().generateOfflineAddress(address.walletId, amount: bamount)
        }
                
        values.removeAll()

        if transaction == .privacy {
            if isOwn {
                values.append(TokenValue(name: Localizable.shared.strings.max_privacy_address.uppercased(), value: address.maxPrivacyToken ?? "", info: String.empty()))
            }
        }
        else {
            values.append(TokenValue(name: "", value: address.onlineToken ?? "", info: String.empty()))
            values.append(TokenValue(name: "\(Localizable.shared.strings.online_token.uppercased()) (\(Localizable.shared.strings.for_pool.lowercased()))", value: address.walletId, info: String.empty()))
            
            if isOwn {
                values.append(TokenValue(name: "\(Localizable.shared.strings.offline_token.uppercased()) (\(Localizable.shared.strings.for_wallets.lowercased()))", value: address.offlineToken ?? "", info: Localizable.shared.strings.support_10_payments))
            }
        } 
    }
    
    public func createAddress() {
        AppModel.sharedManager().generateNewWalletAddress({ (address, error) in
            if let result = address {
                self.address = result
                self.generateTokens()
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    self.address.duration = 0
                    AppModel.sharedManager().setExpires(Int32(0), toAddress: self.address.walletId)
                }
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
    
    
    public func onCategory() {
        if let top = UIApplication.getTopMostViewController() {
            if AppModel.sharedManager().categories.count == 0 {
                let vc = CategoryEditViewController(category: nil)
                vc.completion = { [weak self]
                    obj in
                    guard let strongSelf = self else { return }
                    
                    if let category = obj {
                        strongSelf.address?.categories = [String(category.id)]
                        
                        AppModel.sharedManager().setWalletCategories(strongSelf.address!.categories, toAddress: strongSelf.address!.walletId)
                        
                        self?.onDataChanged?()
                    }
                }
                top.pushViewController(vc: vc)
            }
            else {
                let vc = BMDataPickerViewController(type: .category, selectedValue: address?.categories as? [String])
                vc.completion = { [weak self]
                    obj in
                    
                    guard let strongSelf = self else { return }
                    
                    if let categories = (obj as? [String]) {
                        strongSelf.address?.categories = NSMutableArray(array: categories)
                    AppModel.sharedManager().setWalletCategories(strongSelf.address!.categories, toAddress: strongSelf.address!.walletId)
                        
                        self?.onDataChanged?()
                    }
                }
                top.pushViewController(vc: vc)
            }
        }
    }
    
    
    public func onShare(token: String) {
        self.showShareDialog(token)
    }
    
    private func showPopoverMenu(_ items:[BMPopoverMenu.BMPopoverMenuItem]) {
        BMPopoverMenu.show(menuArray: items, done: { selectedItem in
            if let item = selectedItem {
                switch item.action {
                case .share_online_token:
//                    if let token = self.address.token {
//
//                    }
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
