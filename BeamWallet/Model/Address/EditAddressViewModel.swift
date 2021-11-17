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
        self.newAddress._id = address._id
        self.newAddress.walletId = address.walletId
        self.newAddress.label = address.label
        self.newAddress.createTime = address.createTime
        self.newAddress.duration = address.duration
        self.newAddress.ownerId = address.ownerId
        self.newAddress.address = address.address
        self.newAddress.isNowExpired = false
        self.newAddress.isNowActive = false
        self.newAddress.isNowActiveDuration = self.hours_24
        self.newAddress.displayAddress = address.displayAddress
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

        
        return false
    }
    
    
    public func saveChages() {
        self.address?.isNowExpired = self.newAddress.isNowExpired
        self.address?.isNowActive = self.newAddress.isNowActive
        self.address?.isNowActiveDuration = self.newAddress.isNowActiveDuration
        self.address?.label = self.newAddress.label
        self.address?.duration = self.newAddress.duration

        if let address = self.address {
            AppModel.sharedManager().edit(address)
        }
    }
}
