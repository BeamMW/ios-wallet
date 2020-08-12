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
    public var expire = ExpireOptions.oneTime {
        didSet {
            if address != nil {
                let hours = expire == .oneTime ? Settings.sharedManager().maxAddressDurationHours : 0
                address.duration = UInt64(hours == Settings.sharedManager().maxAddressDurationHours ? Settings.sharedManager().maxAddressDurationSeconds : 0)
                
                AppModel.sharedManager().setExpires(Int32(hours), toAddress: address.walletId)
                
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
    
    private func generateTokens() {
        address.token = AppModel.sharedManager().token(transaction == .privacy, nonInteractive: false, isPermanentAddress: (expire == ExpireOptions.parmanent), amount: Double(amount ?? "0") ?? 0, walleetId: address.walletId, identity: address.identity ?? "", ownId: Int64(address.ownerId))
        address.offlineToken = AppModel.sharedManager().token(transaction == .privacy, nonInteractive: true, isPermanentAddress: (expire == ExpireOptions.parmanent), amount: Double(amount ?? "0") ?? 0, walleetId: address.walletId, identity: address.identity ?? "", ownId: Int64(address.ownerId))
    }
    
    public func createAddress() {
        address = AppModel.sharedManager().generateAddress()
        generateTokens()
        
        self.onAddressCreated?(nil)
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
    
    
    public func onShare() {
        if transaction == .regular && expire == .oneTime, let token = address.token {
            self.showShareDialog(token)
        }
        else if (transaction == .privacy && expire == .oneTime) || (transaction == .privacy && expire == .parmanent) {
            let items = [BMPopoverMenu.BMPopoverMenuItem(name: "\(Localizable.shared.strings.online_token) (\(Localizable.shared.strings.for_wallet.lowercased())", icon: nil, action: BMPopoverMenu.BMPopoverMenuItemAction.share_online_token), BMPopoverMenu.BMPopoverMenuItem(name: "\(Localizable.shared.strings.offline_token) (\(Localizable.shared.strings.for_wallet.lowercased()))", icon: nil, action: BMPopoverMenu.BMPopoverMenuItemAction.share_offline_token)]
            self.showPopoverMenu(items)
        }
        else if transaction == .regular && expire == .parmanent {
            let items = [BMPopoverMenu.BMPopoverMenuItem(name: "\(Localizable.shared.strings.online_token) (\(Localizable.shared.strings.for_wallet.lowercased())", icon: nil, action: BMPopoverMenu.BMPopoverMenuItemAction.share_online_token), BMPopoverMenu.BMPopoverMenuItem(name: "\(Localizable.shared.strings.online_token) (\(Localizable.shared.strings.for_pool.lowercased()))", icon: nil, action: BMPopoverMenu.BMPopoverMenuItemAction.share_pool_token)]
            self.showPopoverMenu(items)
        }
    }
    
    private func showPopoverMenu(_ items:[BMPopoverMenu.BMPopoverMenuItem]) {
        BMPopoverMenu.show(menuArray: items, done: { selectedItem in
            if let item = selectedItem {
                switch item.action {
                case .share_online_token:
                    if let token = self.address.token {
                        self.showShareDialog(token)
                    }
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
                        ShowCopied()
                    }
                    
                    self?.onShared?()
                }
            }
            vc.excludedActivityTypes = [UIActivity.ActivityType.assignToContact, UIActivity.ActivityType.print, UIActivity.ActivityType.openInIBooks]
            top.present(vc, animated: true)
        }
    }
}
