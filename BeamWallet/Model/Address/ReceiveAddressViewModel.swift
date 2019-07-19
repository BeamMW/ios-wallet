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
    
    enum ReceiveAddressViewModelSaveState: Int {
        case none = 0
        case new = 1
        case edit = 2
    }
    
    public var transactionComment = String.empty()
    
    public var onAddressCreated : ((Error?) -> Void)?
    public var onDataChanged : (() -> Void)?
    public var onShared : (() -> Void)?

    public var address:BMAddress!
    public var startedAddress:BMAddress!
    public var pickedAddress:BMAddress?
    
    public var isShared = false
    
    public var amount:String?

    override init() {
        super.init()
    }
    
    public func createAddress() {
        AppModel.sharedManager().generateNewWalletAddress { (address, error) in
            if let result = address {
                DispatchQueue.main.async {
                    self.address = result
                    self.startedAddress = BMAddress.fromAddress(result)
                    self.onAddressCreated?(error)
                }
            }
            else if (error) != nil {
                DispatchQueue.main.async {
                    self.onAddressCreated?(error)
                }
            }
        }
    }
    
    public func revertChanges() {
        var deleted = false
        
        if pickedAddress != nil {
            if !isShared {
                if pickedAddress?.walletId == startedAddress?.walletId {
                    deleted = true
                    AppModel.sharedManager().deleteAddress(startedAddress?.walletId)
                }
                else if pickedAddress?.label != address?.label || pickedAddress?.categories != address?.categories {
                    AppModel.sharedManager().edit(pickedAddress!)
                }
            }
            
            if pickedAddress?.walletId != startedAddress?.walletId {
                deleted = true
                AppModel.sharedManager().deleteAddress(startedAddress?.walletId)
            }
        }
        else if !isShared
        {
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
        if pickedAddress != nil {
            if !isShared {
                if pickedAddress?.walletId == startedAddress?.walletId {
                    return .new
                }
                else if pickedAddress?.label != address?.label || pickedAddress?.categories != address?.categories {
                    return .edit
                }
            }
        }
        else if !isShared
        {
            return .new
        }
        
        return .none
    }
    
    public func onExpire() {
        if let top = UIApplication.getTopMostViewController() {
            let vc = AddressExpiresPickerViewController(duration: Int(self.address!.duration))
            vc.completion = { [weak self]
                obj in
                
                self?.address?.duration = obj == 24 ? 86400 : 0
                
                AppModel.sharedManager().setExpires(Int32(obj), toAddress: self?.address?.walletId ?? String.empty())
                
                self?.onDataChanged?()
            }
            top.pushViewController(vc: vc)
        }
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
            else{
                let vc  = CategoryPickerViewController(categories: self.address?.categories as? [String])
                vc.completion = { [weak self]
                    obj in
                    guard let strongSelf = self else { return }

                    if let categories = obj {
                        strongSelf.address?.categories = NSMutableArray(array: categories)
                        
                        AppModel.sharedManager().setWalletCategories(strongSelf.address!.categories, toAddress: strongSelf.address!.walletId)
                        
                        self?.onDataChanged?()
                    }
                }
                top.pushViewController(vc: vc)
            }
        }
    }
    
    public func onChangeAddress() {
        if let top = UIApplication.getTopMostViewController() {
            let vc = ReceiveListViewController()
            vc.completion = {[weak self]
                obj in
                
                self?.isShared = false
                
                self?.pickedAddress = BMAddress()
                self?.pickedAddress?.label = obj.label
                self?.pickedAddress?.categories = obj.categories
                self?.pickedAddress?.walletId = obj.walletId
                
                self?.transactionComment = String.empty()
                
                self?.address = obj
                
                self?.onDataChanged?()
            }
            vc.excepted = self.startedAddress
            vc.currenltyPicked = self.address
            top.pushViewController(vc: vc)
        }
    }
    
    public func onQRCode() {
        
        if let top = UIApplication.getTopMostViewController() {
            if amount == Localizable.shared.strings.zero {
                top.alert(title: Localizable.shared.strings.wrong_requested_amount_title, message: Localizable.shared.strings.wrong_requested_amount_text, handler: nil)
            }
            else{
                isShared = true
                
                let modalViewController = QRViewController(address: address, amount: amount)
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
            let vc = UIActivityViewController(activityItems: [address.walletId], applicationActivities: [])
            vc.completionWithItemsHandler = {[weak self] (activityType: UIActivity.ActivityType?, completed: Bool, returnedItems: [Any]?, error: Error?) in
                if completed {
                    self?.isShared = true
                    
                    if activityType == UIActivity.ActivityType.copyToPasteboard {
                        ShowCopied()
                    }
                    
                    self?.onShared?()
                }
            }
            vc.excludedActivityTypes = [UIActivity.ActivityType.assignToContact, UIActivity.ActivityType.print,UIActivity.ActivityType.openInIBooks]
            top.present(vc, animated: true)
        }
    }
}
