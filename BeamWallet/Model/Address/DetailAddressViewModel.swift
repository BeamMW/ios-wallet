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
    public var details = [BMMultiLineItem]()
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
        
        details.append(BMMultiLineItem(title: nil, detail:(self.address!.label.isEmpty ? Localizable.shared.strings.no_name : self.address!.label) , detailFont: BoldFont(size: 30), detailColor: UIColor.white))

        let idItem = BMMultiLineItem(title: Localizable.shared.strings.address.uppercased(), detail:self.address!.walletId , detailFont: RegularFont(size: 16), detailColor: UIColor.white)
        idItem.canCopy = true
        details.append(idItem)
        
        if self.address?.identity != nil && self.address?.identity?.isEmpty == false {
            let identityItem = BMMultiLineItem(title: Localizable.shared.strings.identity.uppercased(), detail:self.address!.identity , detailFont: RegularFont(size: 16), detailColor: UIColor.white)
            identityItem.canCopy = true
            identityItem.copiedText = Localizable.shared.strings.copied_to_clipboard
            details.append(identityItem)
        }
        
//        if !isContact {
//            details.append(BMMultiLineItem(title: (self.address!.isExpired() ? Localizable.shared.strings.expired : Localizable.shared.strings.exp_date), detail:self.address!.formattedDate() , detailFont: RegularFont(size: 16), detailColor: UIColor.white))
//        }
        
        if self.address?.categories.count ?? 0 > 0 {
            let title = (self.address?.categories.count ?? 0 <= 1 ? Localizable.shared.strings.tag : Localizable.shared.strings.categories)
            let categories = self.address?.categoriesName()
            if(categories?.length ?? 0 > 0){
                let item = BMMultiLineItem(title: title, detail:categories?.string , detailFont: RegularFont(size: 16), detailColor: UIColor.white)
                       item.detailAttributedString = categories
                details.append(item)
            }
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
