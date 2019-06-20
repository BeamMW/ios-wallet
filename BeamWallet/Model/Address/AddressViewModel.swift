//
// AddressViewModel.swift
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

class AddressViewModel: NSObject {
    enum AddressesSelectedState: Int {
        case active = 0
        case expired = 1
        case contacts = 2
    }
    
    public var onDataChanged : (() -> Void)?
    public var onDataDeleted : ((IndexPath?, BMAddress) -> Void)?

    public var addresses = [BMAddress]()
    public var contacts = [BMContact]()
    public var selectedState: AddressesSelectedState = .active {
        didSet{
            self.filterAddresses()
        }
    }
    
    public var address:BMAddress?
    
    public var category:BMCategory?

    override init() {
        super.init()
    }
    
    init(selected:AddressesSelectedState) {
        super.init()
        
        self.selectedState = selected
        
        self.filterAddresses()
        
        AppModel.sharedManager().addDelegate(self)
    }
    
    init(address:BMAddress) {
        super.init()
        
        self.address = address
        
        AppModel.sharedManager().addDelegate(self)
    }
    
    init(category:BMCategory?) {
        super.init()
        
        self.category = category
        
        if let cat = category {
            addresses = AppModel.sharedManager().getAddressFrom(cat) as! [BMAddress]
        }
        
        AppModel.sharedManager().addDelegate(self)
    }
    
    deinit {
        AppModel.sharedManager().removeDelegate(self)
    }
        
    public func filterAddresses() {
        switch selectedState {
        case .active:
            if let addresses = AppModel.sharedManager().walletAddresses {
                self.addresses = addresses as! [BMAddress]
            }
            self.addresses = self.addresses.filter { $0.isExpired() == false}
        case .expired:
            if let addresses = AppModel.sharedManager().walletAddresses {
                self.addresses = addresses as! [BMAddress]
            }
            self.addresses = self.addresses.filter { $0.isExpired() == true}
        case .contacts:
            self.contacts = AppModel.sharedManager().contacts as! [BMContact]
        }
        
        self.onDataChanged?()
    }
    
    public func onDeleteAddress(address:BMAddress, indexPath:IndexPath?) {
        let transactions = (AppModel.sharedManager().getTransactionsFrom(address) as! [BMTransaction])
        
        if transactions.count > 0  {
            self.showDeleteAddressAndTransactions(indexPath: indexPath)
        }
        else{
            if let path = indexPath {
                if self.selectedState == .contacts {
                    self.contacts.remove(at: path.row)
                }
                else{
                    self.addresses.remove(at: path.row)
                }
            }
            self.onDataDeleted?(indexPath, address)
        }
    }
    
    public func showDeleteAddressAndTransactions(indexPath:IndexPath?) {
        var address:BMAddress!
        
        if let path = indexPath {
            address = (selectedState == .contacts ? contacts[path.row].address : addresses[path.row])
        }
        else{
            address = self.address
        }
        
        let items = [BMPopoverMenu.BMPopoverMenuItem(name: (selectedState == .contacts ? LocalizableStrings.delete_contact_transaction : LocalizableStrings.delete_address_transaction), icon: nil, action: .delete_address_transactions), BMPopoverMenu.BMPopoverMenuItem(name: (selectedState == .contacts ? LocalizableStrings.delete_contact_only : LocalizableStrings.delete_address_only), icon: nil, action:.delete_address)]
        
        BMPopoverMenu.show(menuArray: items, done: { (selectedItem) in
            if let item = selectedItem {
                switch (item.action) {
                case .delete_address:
                    if let path = indexPath {
                        if self.selectedState == .contacts {
                            self.contacts.remove(at: path.row)
                        }
                        else{
                            self.addresses.remove(at: path.row)
                        }
                    }
                    address.isNeedRemoveTransactions = false
                    self.onDataDeleted?(indexPath,address)
                case .delete_address_transactions :
                    if let path = indexPath {
                        if self.selectedState == .contacts {
                            self.contacts.remove(at: path.row)
                        }
                        else{
                            self.addresses.remove(at: path.row)
                        }
                    }
                    address.isNeedRemoveTransactions = true
                    self.onDataDeleted?(indexPath,address)
                default:
                    return
                }
            }
        }) {
            
        }
    }
    
    public func onEditAddress(address:BMAddress) {
        let vc = EditAddressViewController(address: address)
        if let top = UIApplication.getTopMostViewController() {
            top.pushViewController(vc: vc)
        }
    }
    
    public func onQRCodeAddress(address:BMAddress) {
        let modalViewController = QRViewController(address: address, amount: nil)
        modalViewController.modalPresentationStyle = .overFullScreen
        modalViewController.modalTransitionStyle = .crossDissolve
        if let top = UIApplication.getTopMostViewController() {
            top.present(modalViewController, animated: true, completion: nil)
        }
    }
    
    public func onCopyAddress(address:BMAddress) {
        UIPasteboard.general.string = address.walletId
        ShowCopied(text: LocalizableStrings.address_copied)
    }
    
    public func trailingSwipeActions(indexPath:IndexPath) -> UISwipeActionsConfiguration? {
        let address:BMAddress = selectedState == .contacts ? contacts[indexPath.row].address : addresses[indexPath.row]
        
        let delete = UIContextualAction(style: .normal, title: nil) { (action, view, handler) in
            handler(true)
           self.onDeleteAddress(address: address, indexPath: indexPath)
        }
        delete.image = IconRowDelete()
        delete.backgroundColor = UIColor.main.orangeRed
        
        let copy = UIContextualAction(style: .normal, title: nil) { (action, view, handler) in
            handler(true)
            self.onCopyAddress(address: address)
        }
        copy.image = IconRowCopy()
        copy.backgroundColor = UIColor.main.warmBlue
        
        let edit = UIContextualAction(style: .normal, title: nil) { (action, view, handler) in
            handler(true)
            self.onEditAddress(address: address)
        }
        edit.image = IconRowEdit()
        edit.backgroundColor = UIColor.main.steel
        
        let configuration = UISwipeActionsConfiguration(actions: [delete, copy, edit])
        configuration.performsFirstActionWithFullSwipe = false
        return configuration
    }
}

extension AddressViewModel : WalletModelDelegate {
    func onWalletAddresses(_ walletAddresses: [BMAddress]) {
        DispatchQueue.main.async {
            if self.address != nil {
                if let address = walletAddresses.first(where: { $0.walletId == self.address?.walletId }) {
                    self.address = address
                    self.onDataChanged?()
                }
            }
            else if self.category != nil{
                self.addresses = AppModel.sharedManager().getAddressFrom(self.category!) as! [BMAddress]
                self.onDataChanged?()
            }
            else{
                self.filterAddresses()
            }
        }
    }
    
    func onContactsChange(_ contacts: [BMContact]) {
        DispatchQueue.main.async {
            if self.address != nil {
                if let contact = contacts.first(where: { $0.address.walletId == self.address?.walletId }) {
                    self.address = contact.address
                    self.onDataChanged?()
                }
            }
            else if self.category != nil{
                self.addresses = AppModel.sharedManager().getAddressFrom(self.category!) as! [BMAddress]
                self.onDataChanged?()
            }
            else{
                self.filterAddresses()
            }
        }
    }
    
    func onCategoriesChange() {
        DispatchQueue.main.async {
            if self.address == nil {
                self.filterAddresses()
            }
            else if self.category != nil{
                self.addresses = AppModel.sharedManager().getAddressFrom(self.category!) as! [BMAddress]
                self.onDataChanged?()
            }
        }
    }
}
