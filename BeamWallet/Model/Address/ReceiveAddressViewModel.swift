//
// ReceiveAddressViewModel.swift
// BeamWallet
//
// Copyright 2026 Beam Development
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

    enum ReceiveTokenType: Int {
        case sbbs = 0
        case regular = 1
        case maxPrivacy = 2
        case offline = 3
        case publicOffline = 4

        var localizedName: String {
            switch self {
            case .sbbs: return Localizable.shared.strings.sbbs_address
            case .regular: return Localizable.shared.strings.regular_address
            case .maxPrivacy: return Localizable.shared.strings.max_privacy_address
            case .offline: return Localizable.shared.strings.offline_address
            case .publicOffline: return Localizable.shared.strings.public_offline_address
            }
        }

        var supportsVouchers: Bool {
            switch self {
            case .regular, .offline: return true
            default: return false
            }
        }

        var supportsOnlineReceive: Bool {
            switch self {
            case .sbbs, .regular, .offline: return true
            default: return false
            }
        }

        var defaultVouchers: Int {
            switch self {
            case .offline: return 10
            default: return 1
            }
        }
    }

    static let maxVouchersCount = 30

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
    public var onAddressUpdate: ((Error?) -> Void)?

    public var address: BMAddress!
    public var selectedTokenType: ReceiveTokenType = .regular {
        didSet {
            if isSavedAddress {
                isShared = true
            }
            suppressVouchersRegen = true
            vouchersCount = selectedTokenType.defaultVouchers
            suppressVouchersRegen = false
        }
    }

    public var transaction: TransactionOptions {
        return selectedTokenType == .maxPrivacy ? .privacy : .regular
    }

    private var suppressVouchersRegen = false

    public var vouchersCount: Int = ReceiveTokenType.regular.defaultVouchers {
        didSet {
            if !suppressVouchersRegen && selectedTokenType.supportsVouchers {
                generateTokens()
            }
        }
    }

    public var currentToken: String {
        let isOwn = AppModel.sharedManager().checkIsOwnNode()
        if !isOwn { return address?.address ?? address?.walletId ?? "" }
        switch selectedTokenType {
        case .sbbs: return address?.sbbsToken ?? ""
        case .regular: return address?.address ?? address?.walletId ?? ""
        case .maxPrivacy: return address?.maxPrivacyToken ?? ""
        case .offline: return address?.offlineToken ?? ""
        case .publicOffline: return address?.publicOfflineToken ?? ""
        }
    }

    public var isSavedAddress = false
    public var isShared = true
    
//    public var isShared = false {
//        didSet {
//            if isSavedAddress && isShared {
//                if transaction == .privacy {
//                    AppModel.sharedManager().saveToken(self.address._id, token: self.address.maxPrivacyToken ?? "")
//                }
//                else {
//                    let isOwn = AppModel.sharedManager().checkIsOwnNode()
//                    if isOwn {
//                        if self.address.offlineToken != nil {
//                            AppModel.sharedManager().saveToken(self.address._id, token: self.address.offlineToken ?? "")
//                        }
//                    }
//                }
//            }
//            else  if isShared {
//                if transaction == .privacy {
//                    AppModel.sharedManager().saveToken(self.address._id, token: self.address.maxPrivacyToken ?? "")
//                }
//                else {
//                    let isOwn = AppModel.sharedManager().checkIsOwnNode()
//                    if isOwn {
//                        if self.address.offlineToken != nil {
//                            AppModel.sharedManager().saveToken(self.address._id, token: self.address.offlineToken ?? "")
//                        }
//                    }
//                    else {
//                        AppModel.sharedManager().saveToken(self.address._id, token: self.address.address ?? "")
//                    }
//                }
//            }
//        }
//    }
    
    public var amount: String? {
        didSet {
            generateTokens()


            let amount = Double(self.amount ?? "0") ?? 0
            let second = ExchangeManager.shared().exchangeValueAsset(amount, assetID: UInt64(self.selectedAssetId))
            secondAmount = second
        }
    }
    
    
    public var secondAmount: String?
    public var selectedAssetId = 0 {
        didSet {
            generateTokens()
        }
    }
    public var selectedCurrencyString: String {
        return AssetsManager.shared().getAsset(Int32(selectedAssetId))?.unitName ?? ""
    }
    
    override init() {
        super.init()
        
        let amount = Double(self.amount ?? "0") ?? 0
        let second = ExchangeManager.shared().exchangeValueAsset(amount, assetID: UInt64(self.selectedAssetId))
        secondAmount = second
    }
    
    public func generateTokens() {
        let isOwn = AppModel.sharedManager().checkIsOwnNode()

        let bamount = Double(amount ?? "0") ?? 0

        let walletId = address._id
        let assetId = Int32(selectedAssetId)

        if !isOwn {
            let token = AppModel.sharedManager().generateRegularAddress(walletId, assetId: assetId, amount: bamount, isPermanentAddress: false)
            address.address = token
            DispatchQueue.main.async {
                self.onAddressUpdate?(nil)
            }
            return
        }

        switch selectedTokenType {
        case .sbbs:
            AppModel.sharedManager().generateSBBSAddress(walletId, assetId: assetId, amount: bamount) { token in
                DispatchQueue.main.async {
                    self.address.sbbsToken = token
                    self.onAddressUpdate?(nil)
                }
            }
        case .regular:
            AppModel.sharedManager().generateOfflineAddress(walletId, assetId: assetId, amount: bamount, offlineCount: UInt32(vouchersCount)) { token in
                DispatchQueue.main.async {
                    self.address.address = token
                    self.onAddressUpdate?(nil)
                }
            }
        case .maxPrivacy:
            AppModel.sharedManager().generateMaxPrivacyAddress(walletId, assetId: assetId, amount: bamount) { token in
                DispatchQueue.main.async {
                    self.address.maxPrivacyToken = token
                    self.onAddressUpdate?(nil)
                }
            }
        case .offline:
            AppModel.sharedManager().generateOfflineAddress(walletId, assetId: assetId, amount: bamount, offlineCount: UInt32(vouchersCount)) { token in
                DispatchQueue.main.async {
                    let isFirst = (self.address.offlineToken == nil)
                    self.address.offlineToken = token
                    if isFirst {
                        self.onAddressCreated?(nil)
                    } else {
                        self.onAddressUpdate?(nil)
                    }
                }
            }
        case .publicOffline:
            AppModel.sharedManager().generatePublicOfflineAddress(walletId, assetId: assetId, amount: bamount) { token in
                DispatchQueue.main.async {
                    self.address.publicOfflineToken = token
                    self.onAddressUpdate?(nil)
                }
            }
        }
    }
    
    public func createAddress() {
        let isOwn = AppModel.sharedManager().checkIsOwnNode()
        let bamount = Double(amount ?? "0") ?? 0
        AppModel.sharedManager().generateNewWalletAddress(withBlockAndAmount: Int32(selectedAssetId), amount: bamount) { address, error in
            if let result = address {
                self.address = result
                if isOwn {
                    self.generateTokens()
                }
            }
            DispatchQueue.main.async {
                self.onAddressCreated?(error)
            }
        }
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
//        if !isShared {
//            return .new
//        }
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
                case .share_pool_token:
                    self.showShareDialog(self.address.walletId)
                default:
                    return
                }
            }
        }, cancel: {})
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
