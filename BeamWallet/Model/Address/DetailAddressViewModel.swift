//
// DetailAddressViewModel.swift
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

class DetailAddressViewModel: AddressViewModel {

    public var isContact = false
    public var details = [GeneralInfo]()
    public var transactionViewModel:TransactionViewModel!
    public var transactions:[BMTransaction] {
        get{
            return transactionViewModel.transactions
        }
    }

    override init(address: BMAddress) {
        super.init(address: address)
        
        isContact = (AppModel.sharedManager().getContactFromId(address.walletId) != nil)

        transactionViewModel = TransactionViewModel(address: address)
        transactionViewModel.onDataChanged = { [weak self] in
            self?.onDataChanged?()
        }
        
        fillDetails()
    }
    
    override var address: BMAddress?{
        didSet{
            fillDetails()
        }
    }
    
    public func fillDetails() {
        details.removeAll()
        
        details.append(GeneralInfo(text: Localizable.shared.strings.addDots(value: Localizable.shared.strings.address), detail: self.address!.walletId, failed: false, canCopy:true, color: UIColor.white))
        
        if !isContact {
            details.append(GeneralInfo(text: Localizable.shared.strings.addDots(value: Localizable.shared.strings.exp_date), detail: self.address!.formattedDate(), failed: false, canCopy:false, color: UIColor.white))
        }
        
        if !self.address!.category.isEmpty {
            if let category = AppModel.sharedManager().findCategory(byId: self.address!.category) {
                details.append(GeneralInfo(text: Localizable.shared.strings.addDots(value: Localizable.shared.strings.category), detail: category.name, failed: false, canCopy:false, color: UIColor.init(hexString: category.color)))
            }
        }
        
        if !self.address!.label.isEmpty {
            details.append(GeneralInfo(text: Localizable.shared.strings.addDots(value: Localizable.shared.strings.name), detail: self.address!.label, failed: false, canCopy:false, color: UIColor.white))
        }
    }
    
    public func actionItems() -> [BMPopoverMenu.BMPopoverMenuItem] {
        var items = [BMPopoverMenu.BMPopoverMenuItem(name: Localizable.shared.strings.show_qr_code, icon: nil, action: .show_qr_code), BMPopoverMenu.BMPopoverMenuItem(name: (isContact ? Localizable.shared.strings.copy_contact : Localizable.shared.strings.copy_address), icon: nil, action:.copy_address), BMPopoverMenu.BMPopoverMenuItem(name: (isContact ? Localizable.shared.strings.edit_contact : Localizable.shared.strings.edit_address), icon: nil, action:.edit_address), BMPopoverMenu.BMPopoverMenuItem(name: (isContact ? Localizable.shared.strings.delete_contact : Localizable.shared.strings.delete_address), icon: nil, action:.delete_address)]
        
        
        if isContact {
            items.remove(at: 0)
        }
        
        return items
    }
}
