//
// EditAddressViewModel.swift
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


import UIKit

class EditAddressViewModel: DetailAddressViewModel {

    public var newAddress:BMAddress!
    public let hours_24: UInt64 = 86400

    override init(address: BMAddress) {
        super.init(address: address)
        
        self.newAddress = BMAddress()
        self.newAddress.walletId = address.walletId
        self.newAddress.label = address.label
        self.newAddress.category = address.category
        self.newAddress.createTime = address.createTime
        self.newAddress.duration = address.duration
        self.newAddress.ownerId = address.ownerId
        self.newAddress.isNowExpired = false
        self.newAddress.isNowActive = false
        self.newAddress.isNowActiveDuration = hours_24
    }
    
    public func checkIsChanges() -> Bool {
        if newAddress.label != address?.label {
            return true
        }
        else if newAddress.isNowExpired != address?.isNowExpired {
            return true
        }
        else if newAddress.isNowActive != address?.isNowActive {
            return true
        }
        else if newAddress.duration != address?.duration {
            return true
        }
        else if newAddress.category != address?.category {
            return true
        }
       
        return false
    }
    
    public func pickExpire() {
        if let top = UIApplication.getTopMostViewController() {
            var duration = Int(self.newAddress!.duration)
            
            if self.newAddress.isNowActive {
                duration = Int(self.newAddress.isNowActiveDuration)
            }
            
            let vc = AddressExpiresPickerViewController(duration: duration)
            vc.completion = {
                obj in
                
                self.newAddress.isChangedDate = true
                
                if obj == 24 {
                    self.newAddress.isNowActive = true
                    self.newAddress.isNowActiveDuration = self.hours_24
                    
                    if self.newAddress.isExpired() == false {
                        self.newAddress.isNowExpired = false
                    }
                }
                else {
                    if self.newAddress.isNowActive {
                        self.newAddress.isNowActiveDuration = 0
                    }
                    else{
                        self.newAddress.duration = 0
                    }
                    
                    if self.newAddress.isExpired() == false {
                        self.newAddress.isNowExpired = false
                    }
                }
                
                self.onDataChanged?()
            }
            
            top.pushViewController(vc: vc)
        }
    }
    
    public func pickCategory() {
        if let top = UIApplication.getTopMostViewController() {
            if AppModel.sharedManager().categories.count == 0 {
                let vc = CategoryEditViewController(category: nil)
                vc.completion = { [weak self]
                    obj in
                    if let cat = obj {
                        self?.newAddress.category = String(cat.id)
                        self?.onDataChanged?()
                    }
                }
                top.pushViewController(vc: vc)
            }
            else{
                let vc = CategoryPickerViewController(category: self.newAddress.category == Localizables.shared.strings.zero ? BMCategory.none() : AppModel.sharedManager().findCategory(byId: self.newAddress.category))
                vc.completion = { [weak self]
                    obj in
                    if let cat = obj {
                        self?.newAddress.category = String(cat.id)
                        self?.onDataChanged?()
                    }
                }
                top.pushViewController(vc: vc)
            }
        }
    }
    
    public func saveChages() {
        AppModel.sharedManager().edit(newAddress)
    }
}
