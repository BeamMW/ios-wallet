//
// AddressViewController.swift
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

class AddressViewController: BaseTableViewController {

    private var addressViewModel:DetailAddressViewModel!
    
    init(address:BMAddress) {
        super.init(nibName: nil, bundle: nil)
        self.addressViewModel = DetailAddressViewModel(address: address)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError(LocalizableStrings.fatalInitCoderError)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register([GeneralInfoCell.self, WalletTransactionCell.self])
        tableView.tableHeaderView = UIView(frame: CGRect(x: 0, y: 0, width: 0, height: 10))
        
        addRightButton(image: MoreIcon(), target: self, selector: #selector(onMore))

        title = (addressViewModel.isContact ? LocalizableStrings.contact : LocalizableStrings.address)
        
        subscribeToUpdates()
    }
    
    private func subscribeToUpdates() {
        addressViewModel.onDataChanged = { [weak self] in
            self?.tableView.reloadData()
        }
        
        addressViewModel.onDataDeleted = { [weak self]
            indexPath, address in
            
            AppModel.sharedManager().prepareDelete(address, removeTransactions: address.isNeedRemoveTransactions)
            
            self?.back()
        }
        
        addressViewModel.transactionViewModel.onDataDeleted = { [weak self]
            indexPath, transaction in
            
            if let path = indexPath {
                self?.tableView.performUpdate({
                    self?.tableView.deleteRows(at: [path], with: .left)
                }, completion: {
                    AppModel.sharedManager().deleteTransaction(transaction)
                })
            }
        }
        
        addressViewModel.transactionViewModel.onDataUpdated = { [weak self]
            indexPath, transaction in
            
            if let path = indexPath {
                self?.tableView.performUpdate({
                    self?.tableView.reloadRows(at: [path], with: .fade)
                }, completion: {
                    AppModel.sharedManager().cancelTransaction(transaction)
                })
            }
        }
    }

    @objc private func onMore(sender:UIBarButtonItem) {
        BMPopoverMenu.show(menuArray: addressViewModel.actionItems(), done: { (selectedItem) in
            if let item = selectedItem {
                switch (item.action) {
                case .show_qr_code:
                    self.addressViewModel.onQRCodeAddress(address: self.addressViewModel.address!)
                case .copy_address :
                    self.addressViewModel.onCopyAddress(address: self.addressViewModel.address!)
                case .edit_address :
                    self.addressViewModel.onEditAddress(address: self.addressViewModel.address!)
                case .delete_address :
                    self.addressViewModel.onDeleteAddress(address: self.addressViewModel.address!, indexPath: nil)
                default:
                    return
                }
            }
        }, cancel: {

        })
    }
}

extension AddressViewController : UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        if indexPath.section == 1 && addressViewModel.transactions.count > 0 {
            return true
        }
        
        return false
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        if section == 1 && addressViewModel.transactions.count > 0 {
            return BMTableHeaderTitleView.boldHeight
        }
        
        return 0
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return indexPath.section == 1 ? WalletTransactionCell.height() : UITableView.automaticDimension
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        if indexPath.section == 1 {
            let vc = TransactionViewController(transaction: addressViewModel.transactions[indexPath.row])
            vc.hidesBottomBarWhenPushed = true
            pushViewController(vc: vc)
        }
    }
    
    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration?
    {
        return addressViewModel.transactionViewModel.trailingSwipeActions(indexPath:indexPath)
    }
}

extension AddressViewController : UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 1 {
            return addressViewModel.transactions.count
        }
        return addressViewModel.details.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        if indexPath.section == 0 {
            let cell = tableView
                .dequeueReusableCell(withType: GeneralInfoCell.self, for: indexPath)
                .configured(with: addressViewModel.details[indexPath.row])
            return cell
        }
        else{
            let cell = tableView
                .dequeueReusableCell(withType: WalletTransactionCell.self, for: indexPath)
                .configured(with: (row: indexPath.row, transaction: addressViewModel.transactions[indexPath.row], single:false, searchString:nil))
            return cell
        }
        
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        if section == 1 && addressViewModel.transactions.count > 0 {
            return BMTableHeaderTitleView(title: LocalizableStrings.transactions, bold: true)
        }
        
        return nil
    }
}
