//
// AddressesViewController.swift
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

class AddressesViewController: BaseTableViewController {
    enum AddressesSelectedState: Int {
        case active = 0
        case expired = 1
        case contacts = 2
    }
    
    private var selectedState: AddressesSelectedState = .active
    private var addresses = [BMAddress]()
    private var contacts = [BMContact]()
    private var headerView: AddressesSegmentView!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        title = LocalizableStrings.addresses

        headerView = UIView.fromNib()
        headerView.delegate = self
        
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(AddressCell.self)
        tableView.addPullToRefresh(target: self, handler: #selector(refreshData(_:)))

        filterAddresses()
        
        AppModel.sharedManager().addDelegate(self)
        
        NotificationCenter.default.addObserver(self, selector: #selector(didBecomeActive), name: UIApplication.didBecomeActiveNotification, object: nil)
        
        if traitCollection.forceTouchCapability == .available {
            registerForPreviewing(with: self, sourceView: view)
        }
        
        onAddMenuIcon()
    }
        
    @objc private func didBecomeActive() {
        filterAddresses()
        tableView.reloadData()
    }
    
    @objc private func refreshData(_ sender: Any) {
        tableView.stopRefreshing()
    }

    private func filterAddresses() {
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
    }
    
    private func showDeleteAddressAndTransactions(indexPath:IndexPath) {
        let items = [BMPopoverMenu.BMPopoverMenuItem(name: LocalizableStrings.delete_address_transaction, icon: nil, action: .delete_address_transactions), BMPopoverMenu.BMPopoverMenuItem(name: LocalizableStrings.delete_address_only, icon: nil, action:.delete_address)]
        
        var address:BMAddress!
        
        if selectedState == .contacts {
            address = contacts[indexPath.row].address
        }
        else{
            address = addresses[indexPath.row]
        }

        BMPopoverMenu.show(menuArray: items, done: { (selectedItem) in
            if let item = selectedItem {
                switch (item.action) {
                case .delete_address:
                    if self.selectedState == .contacts {
                        self.contacts.remove(at: indexPath.row)
                    }
                    else{
                        self.addresses.remove(at: indexPath.row)
                    }
                    self.tableView.performUpdate({
                        self.tableView.deleteRows(at: [indexPath], with: .left)
                    }, completion: {
                        AppModel.sharedManager().prepareDelete(address, removeTransactions: false)
                    })
                case .delete_address_transactions :
                    if self.selectedState == .contacts {
                        self.contacts.remove(at: indexPath.row)
                    }
                    else{
                        self.addresses.remove(at: indexPath.row)
                    }
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

extension AddressesViewController : UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true;
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        if section == 0 {
            return AddressesSegmentView.height
        }
        
        return 0
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return AddressCell.height()
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        let address = selectedState == .contacts ? contacts[indexPath.row].address : addresses[indexPath.row]
        
        let vc = AddressViewController(address: address, isContact:(selectedState == .contacts))
        vc.hidesBottomBarWhenPushed = true
        pushViewController(vc: vc)
    }
    
    func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
        
        var address:BMAddress!
        
        if selectedState == .contacts {
            address = contacts[indexPath.row].address
        }
        else{
            address = addresses[indexPath.row]
        }
        
        let edit = UITableViewRowAction(style: .normal, title: LocalizableStrings.edit) { action, index in
            let vc = EditAddressViewController(address: address)
            self.pushViewController(vc: vc)
        }
        edit.backgroundColor = UIColor.main.steel
        
        
        let delete = UITableViewRowAction(style: .normal, title: LocalizableStrings.delete) { action, index in
            
            let transactions = (AppModel.sharedManager().getTransactionsFrom(address) as! [BMTransaction])
            
            if transactions.count > 0  {
                self.showDeleteAddressAndTransactions(indexPath: indexPath)
            }
            else{
                if self.selectedState == .contacts {
                    self.contacts.remove(at: indexPath.row)
                }
                else{
                    self.addresses.remove(at: indexPath.row)
                }
                self.tableView.performUpdate({
                    self.tableView.deleteRows(at: [indexPath], with: .left)
                }, completion: {
                    AppModel.sharedManager().prepareDelete(address, removeTransactions: false)
                })
            }
            
        }
        delete.backgroundColor = UIColor.main.orangeRed
        
        return (selectedState == .contacts) ? [delete] : [delete,edit]

    }
}

extension AddressesViewController : UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let count = selectedState == .contacts ? contacts.count : addresses.count
        return count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let address = selectedState == .contacts ? contacts[indexPath.row].address : addresses[indexPath.row]

        let cell =  tableView
            .dequeueReusableCell(withType: AddressCell.self, for: indexPath)
            .configured(with: (row: indexPath.row, address: address, single:false, displayCategory: true))
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        if section == 0 {
            return headerView
        }
        
        return nil
    }
    
}

extension AddressesViewController : WalletModelDelegate {
    func onWalletAddresses(_ walletAddresses: [BMAddress]) {
        DispatchQueue.main.async {
            self.filterAddresses()
            UIView.performWithoutAnimation {
                self.tableView.reloadData()
            }
        }
    }
    
    func onContactsChange(_ contacts: [BMContact]) {
        DispatchQueue.main.async {
            self.filterAddresses()
            UIView.performWithoutAnimation {
                self.tableView.reloadData()
            }
        }
    }
    
    func onCategoriesChange() {
        DispatchQueue.main.async {
            self.filterAddresses()
            UIView.performWithoutAnimation {
                self.tableView.reloadData()
            }
        }
    }
}

extension AddressesViewController : UIViewControllerPreviewingDelegate {
   
    func previewingContext(_ previewingContext: UIViewControllerPreviewing, viewControllerForLocation location: CGPoint) -> UIViewController? {
        
        guard let indexPath = tableView.indexPathForRow(at: location) else { return nil }
        
        guard let cell = tableView.cellForRow(at: indexPath) else { return nil }

        navigationItem.backBarButtonItem = UIBarButtonItem.arrowButton()

        let detailVC = PreviewQRCodeViewController(address: addresses[indexPath.row])
        detailVC.preferredContentSize = CGSize(width: 0.0, height: 340)
        
        previewingContext.sourceRect = cell.frame
        
        return detailVC
    }
    
    func previewingContext(_ previewingContext: UIViewControllerPreviewing, commit viewControllerToCommit: UIViewController) {
        
        navigationItem.backBarButtonItem = UIBarButtonItem.arrowButton()

        show(viewControllerToCommit, sender: self)
    }
}

extension AddressesViewController : AddressesSegmentViewDelegate {
    func onFilterClicked(index: Int) {
        selectedState = AddressesViewController.AddressesSelectedState(rawValue: index) ?? .active
        
        filterAddresses()
        
        UIView.performWithoutAnimation {
            self.tableView.reloadData()
            self.tableView.setContentOffset(CGPoint(x: 0, y: 0), animated: false)
        }
    }
}
