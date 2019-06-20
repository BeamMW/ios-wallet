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
    private var addressViewModel:AddressViewModel!
    
    init(category:BMCategory?) {
        super.init(nibName: nil, bundle: nil)
        
        self.category = category
        self.addressViewModel = AddressViewModel(category: self.category)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError(LocalizableStrings.fatalInitCoderError)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = LocalizableStrings.category
        
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(AddressCell.self)
        tableView.register(CategoryNameCell.self)
        tableView.register(BMEmptyCell.self)

        addRightButton(image: MoreIcon(), target: self, selector: #selector(onMore))
        
        subscribeToUpdates()
    }
    
    private func subscribeToUpdates() {
        addressViewModel.onDataChanged = {[weak self] in
            self?.tableView.reloadData()
        }
        
        addressViewModel.onDataDeleted = { [weak self]
            indexPath, address in
            
            if let path = indexPath {
                self?.tableView.performUpdate({
                    self?.tableView.deleteRows(at: [path], with: .left)
                }, completion: {
                    AppModel.sharedManager().prepareDelete(address, removeTransactions: address.isNeedRemoveTransactions)
                })
            }
        }
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
}

extension CategoryDetailViewController : UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return ((addressViewModel.addresses.count > 0) && indexPath.section == 1)
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
        
        if indexPath.section == 1 && addressViewModel.addresses.count > 0 {
            let vc = AddressViewController(address: addressViewModel.addresses[indexPath.row])
            vc.hidesBottomBarWhenPushed = true
            pushViewController(vc: vc)
        }
    }
    
    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration?
    {
        return addressViewModel.trailingSwipeActions(indexPath: indexPath)
    }
}

extension CategoryDetailViewController : UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 1 {
            if addressViewModel.addresses.count == 0 {
                return 1
            }
            return addressViewModel.addresses.count
        }
        return 1
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        if indexPath.section == 1 {
            if addressViewModel.addresses.count == 0 {
                let cell =  tableView
                    .dequeueReusableCell(withType: BMEmptyCell.self, for: indexPath)
                    .configured(with: LocalizableStrings.no_category_addresses)
                return cell
            }
            else{
                let cell =  tableView
                    .dequeueReusableCell(withType: AddressCell.self, for: indexPath)
                    .configured(with: (row: indexPath.row, address: addressViewModel.addresses[indexPath.row], single:false, displayCategory:false))
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
