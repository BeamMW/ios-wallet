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
    enum ReceiveOptions: Int {
        case wallet = 0
        case pool = 1
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
    
    public var transactionComment = String.empty()
    
    public var onAddressCreated: ((Error?) -> Void)?
    public var onDataChanged: (() -> Void)?
    public var onShared: (() -> Void)?
    
    public var maxPrivacy = false
    
    public var address: BMAddress!
    public var expire = ExpireOptions.parmanent {
        didSet {
            if address != nil {
                let hours = expire == .oneTime ? 24 : 0
                address.duration = hours == 24 ? 86400 : 0
                
                AppModel.sharedManager().setExpires(Int32(hours), toAddress: address.walletId)
            }
        }
    }
    public var receive = ReceiveOptions.wallet

    public var isShared = false
    
    public var amount: String?
    
    override init() {
        super.init()
    }
    
    public func createAddress() {
        address = AppModel.sharedManager().generateToken()
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
    
    
    public func onQRCode() {
        if let top = UIApplication.getTopMostViewController() {
            if amount == Localizable.shared.strings.zero {
                top.alert(title: Localizable.shared.strings.wrong_requested_amount_title, message: Localizable.shared.strings.wrong_requested_amount_text, handler: nil)
            }
            else {
                isShared = true
                
                let modalViewController = QRViewController(address: address, amount: amount, isToken: receive == .wallet)
                modalViewController.onShared = { [weak self] in
                    self?.onShared?()
                }
                modalViewController.modalPresentationStyle = .overFullScreen
                modalViewController.modalTransitionStyle = .crossDissolve
                top.present(modalViewController, animated: true, completion: nil)
            }
        }
    }
    
    public func onShare() {
        if let top = UIApplication.getTopMostViewController() {
            let share = (receive == .wallet ? address.token : address.walletId) ?? String.empty()
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
