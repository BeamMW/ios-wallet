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
    public var newAddress: BMAddress!
    public let hours_24: UInt64 = UInt64(Settings.sharedManager().maxAddressDurationSeconds)
    
    override init(address: BMAddress) {
        super.init(address: address)
        
        self.newAddress = BMAddress()
        self.newAddress.walletId = address.walletId
        self.newAddress.label = address.label
        self.newAddress.categories = address.categories
        self.newAddress.createTime = address.createTime
        self.newAddress.duration = address.duration
        self.newAddress.ownerId = address.ownerId
        self.newAddress.address = address.address
        self.newAddress.isNowExpired = false
        self.newAddress.isNowActive = false
        self.newAddress.isNowActiveDuration = self.hours_24
    }
    
    public func checkIsChanges() -> Bool {
        if self.newAddress.label != address?.label {
            return true
        }
        else if self.newAddress.isNowExpired != address?.isNowExpired {
            return true
        }
        else if self.newAddress.isNowActive != address?.isNowActive {
            return true
        }
        else if self.newAddress.duration != address?.duration {
            return true
        }
        else if self.newAddress.categories != address?.categories {
            return true
        }
        
        return false
    }
    
    public func pickExpire() {
        if let top = UIApplication.getTopMostViewController() {
            let vc = BMDataPickerViewController(type: .address_expire, selectedValue: self.newAddress.durationInHours())
            vc.completion = {
                obj in
                
                let selected = obj as! Int32
                
                self.newAddress.isChangedDate = true
                
                if selected == Settings.sharedManager().maxAddressDurationHours {
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
                    else {
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
                        self?.newAddress.categories = [String(cat.id)]
                        self?.onDataChanged?()
                    }
                }
                top.pushViewController(vc: vc)
            }
            else {
                let vc = BMDataPickerViewController(type: .category, selectedValue: self.newAddress?.categories as? [String])
                vc.completion = { [weak self]
                    obj in
            
                    if let categories = (obj as? [String]) {
                        self?.newAddress.categories = NSMutableArray(array: categories)
                        self?.onDataChanged?()
                    }
                    
                }
                top.pushViewController(vc: vc)
            }
        }
    }
    
    public func saveChages() {
        AppModel.sharedManager().edit(self.newAddress)
    }
}
