//
// CategoryDetailViewController.swift
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

class CategoryDetailViewController: BaseTableViewController {

    private var category:BMCategory!
    private var addresses = [BMAddress]()

    init(category:BMCategory?) {
        super.init(nibName: nil, bundle: nil)
        
        self.category = category
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError(LocalizableStrings.fatalInitCoderError)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = LocalizableStrings.category
        
        loadAddresses()
        
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(AddressCell.self)
        tableView.register(CategoryNameCell.self)
        tableView.register(BMEmptyCell.self)

        addRightButton(image: MoreIcon(), target: self, selector: #selector(onMore))

        AppModel.sharedManager().addDelegate(self)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        if isMovingFromParent
        {
            AppModel.sharedManager().removeDelegate(self)
        }
    }
    
    private func loadAddresses() {
        addresses = AppModel.sharedManager().getAddressFrom(self.category) as! [BMAddress]
    }
    
    @objc private func onMore(sender:UIBarButtonItem) {        
        let items = [BMPopoverMenu.BMPopoverMenuItem(name: LocalizableStrings.edit, icon: nil, action:.edit_category), BMPopoverMenu.BMPopoverMenuItem(name: LocalizableStrings.delete, icon: nil, action:.delete_category)]
        
        BMPopoverMenu.show(menuArray: items, done: { (selectedItem) in
            if let item = selectedItem {
                switch (item.action) {
                case .edit_category:
                    let vc = CategoryEditViewController(category: self.category)
                    vc.hidesBottomBarWhenPushed = true
                    self.pushViewController(vc: vc)
                case .delete_category :
                    self.confirmAlert(title: LocalizableStrings.delete_category, message:LocalizableStrings.delete_category_text(str:self.category.name) , cancelTitle: LocalizableStrings.cancel, confirmTitle: LocalizableStrings.delete, cancelHandler: { (_ ) in
                        
                    }, confirmHandler: { (_ ) in
                        AppModel.sharedManager().removeDelegate(self)
                        
                        AppModel.sharedManager().deleteCategory(self.category)
                        self.navigationController?.popViewController(animated: true)
                    })
                default:
                    return
                }
            }
        }, cancel: {
            
        })
    }
    
    private func showDeleteAddressAndTransactions(indexPath:IndexPath) {
   
        let address:BMAddress = addresses[indexPath.row]

        let isContact = (AppModel.sharedManager().getContactFromId(address.walletId) != nil)

        let items = [BMPopoverMenu.BMPopoverMenuItem(name: (isContact ? LocalizableStrings.delete_contact_transaction : LocalizableStrings.delete_address_transaction), icon: nil, action: .delete_address_transactions), BMPopoverMenu.BMPopoverMenuItem(name: (isContact ? LocalizableStrings.delete_contact_only : LocalizableStrings.delete_address_only), icon: nil, action:.delete_address)]
        
        BMPopoverMenu.show(menuArray: items, done: { (selectedItem) in
            if let item = selectedItem {
                switch (item.action) {
                case .delete_address:
                    self.addresses.remove(at: indexPath.row)
                    self.tableView.performUpdate({
                        self.tableView.deleteRows(at: [indexPath], with: .left)
                    }, completion: {
                        AppModel.sharedManager().prepareDelete(address, removeTransactions: false)
                    })
                case .delete_address_transactions :
                    self.addresses.remove(at: indexPath.row)
                    self.tableView.performUpdate({
                        self.tableView.deleteRows(at: [indexPath], with: .left)
                    }, completion: {
                        AppModel.sharedManager().prepareDelete(address, removeTransactions: true)
                    })
                default:
                    return
                }
            }
        }) {
            
        }
    }
}

extension CategoryDetailViewController : UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return ((addresses.count > 0) && indexPath.section == 1)
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        if section == 1 {
            return BMTableHeaderTitleView.boldHeight
        }
        
        return 0
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if indexPath.section == 0 {
            return 80
        }
        return 90
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        if indexPath.section == 1 && addresses.count > 0 {
            let vc = AddressViewController(address: addresses[indexPath.row], isContact:false)
            vc.hidesBottomBarWhenPushed = true
            pushViewController(vc: vc)
        }
    }
    
    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration?
    {
        let address = addresses[indexPath.row]
        
        let delete = UIContextualAction(style: .normal, title: nil) { (action, view, handler) in
            handler(true)
            
            let transactions = (AppModel.sharedManager().getTransactionsFrom(address) as! [BMTransaction])
            
            if transactions.count > 0  {
                self.showDeleteAddressAndTransactions(indexPath: indexPath)
            }
            else{
                self.addresses.remove(at: indexPath.row)

                self.tableView.performUpdate({
                    self.tableView.deleteRows(at: [indexPath], with: .left)
                }, completion: {
                    AppModel.sharedManager().prepareDelete(address, removeTransactions: false)
                })
            }
        }
        delete.image = IconRowDelete()
        delete.backgroundColor = UIColor.main.orangeRed
        
        let copy = UIContextualAction(style: .normal, title: nil) { (action, view, handler) in
            handler(true)
            
            UIPasteboard.general.string = address.walletId
            ShowCopied(text: LocalizableStrings.address_copied)
        }
        copy.image = IconRowCopy()
        copy.backgroundColor = UIColor.main.warmBlue
        
        let edit = UIContextualAction(style: .normal, title: nil) { (action, view, handler) in
            handler(true)
            let vc = EditAddressViewController(address: address)
            self.pushViewController(vc: vc)
        }
        edit.image = IconRowEdit()
        edit.backgroundColor = UIColor.main.steel
        
        let configuration = UISwipeActionsConfiguration(actions: [delete, copy, edit])
        configuration.performsFirstActionWithFullSwipe = false
        return configuration
    }
}

extension CategoryDetailViewController : UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 1 {
            if addresses.count == 0 {
                return 1
            }
            return addresses.count
        }
        return 1
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        if indexPath.section == 1 {
            if addresses.count == 0 {
                let cell =  tableView
                    .dequeueReusableCell(withType: BMEmptyCell.self, for: indexPath)
                    .configured(with: LocalizableStrings.no_category_addresses)
                return cell
            }
            else{
                let cell =  tableView
                    .dequeueReusableCell(withType: AddressCell.self, for: indexPath)
                    .configured(with: (row: indexPath.row, address: addresses[indexPath.row], single:false, displayCategory:false))
                return cell
            }

        }
        else{
            let cell =  tableView
                .dequeueReusableCell(withType: CategoryNameCell.self, for: indexPath)
                .configured(with: self.category)
            return cell
        }
        
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        if section == 1 {
            return BMTableHeaderTitleView(title: LocalizableStrings.addresses, bold: true)
        }
        
        return nil
    }
}

extension CategoryDetailViewController : WalletModelDelegate {
    
    func onWalletAddresses(_ walletAddresses: [BMAddress]) {
        DispatchQueue.main.async {
            self.loadAddresses()
            UIView.performWithoutAnimation {
                self.tableView.reloadData()
            }
        }
    }
    
    func onContactsChange(_ contacts: [BMContact]) {
        DispatchQueue.main.async {
            self.loadAddresses()
            UIView.performWithoutAnimation {
                self.tableView.reloadData()
            }
        }
    }
    
    func onCategoriesChange() {
        DispatchQueue.main.async {
            let categories = AppModel.sharedManager().categories as! [BMCategory]
            if let category = categories.first(where: { $0.id == self.category.id }) {
                self.category = category
                self.loadAddresses()
                
                UIView.performWithoutAnimation {
                    self.tableView.reloadData()
                }
            }
        }
    }
}
