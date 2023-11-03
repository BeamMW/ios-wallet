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
    public var walletId = ""
    
    init(address:BMAddress) {
        super.init(nibName: nil, bundle: nil)
        self.walletId = address.walletId
        self.addressViewModel = DetailAddressViewModel(address: address)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError(Localizable.shared.strings.fatalInitCoderError)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setGradientTopBar(mainColor: UIColor.main.peacockBlue, addedStatusView: true)

        tableView.delegate = self
        tableView.dataSource = self
        tableView.register([WalletTransactionCell.self, BMMultiLinesCell.self])
        tableView.tableHeaderView = UIView(frame: CGRect(x: 0, y: 0, width: 0, height: 10))
        
        addRightButtons(image: [IconScanQr(), IconEdit()], target: self, selector: [#selector(onQRCode),#selector(onEdit)])
        
        title = Localizable.shared.strings.details
        
        subscribeToUpdates()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
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
                    AppModel.sharedManager().prepareDeleteTransaction(transaction)
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
    
    @objc private func onQRCode(sender:UIButton) {
        self.addressViewModel.onQRCodeAddress(address: self.addressViewModel.address!)
    }
    
    @objc private func onEdit(sender:UIButton) {
        self.addressViewModel.onEditAddress(address: self.addressViewModel.address!)
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
    
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        if section == 0 {
            return 30
        }
        
        return 0
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        if indexPath.section == 1 {
            let vc = TransactionPageViewController(transaction: addressViewModel.transactions[indexPath.row])
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
                .dequeueReusableCell(withType: BMMultiLinesCell.self, for: indexPath)
                .configured(with: addressViewModel.details[indexPath.row])
            cell.increaseSpace = true
            return cell
        }
        else{
            let cell = tableView
                .dequeueReusableCell(withType: WalletTransactionCell.self, for: indexPath)
                .configured(with: (row: indexPath.row+1, transaction: addressViewModel.transactions[indexPath.row], additionalInfo:false))
            return cell
        }
        
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        if section == 1 && addressViewModel.transactions.count > 0 {
            let header =  BMTableHeaderTitleView(title: Localizable.shared.strings.transactions_list.uppercased(), bold: true)
            if Settings.sharedManager().isDarkMode {
                header.backgroundColor = UIColor.main.marineThree
            }
            else if Settings.sharedManager().target == Mainnet  {
                header.backgroundColor = UIColor.init(red: 17 / 255, green: 41 / 255, blue: 73 / 255, alpha: 1)
            }
            else if Settings.sharedManager().target == Testnet  {
                header.backgroundColor = UIColor.main.cellBackgroundColor
            }
            else {
                header.backgroundColor = UIColor.init(red: 28 / 255, green: 28 / 255, blue: 28 / 255, alpha: 1)
            }
            header.letterSpacing = 1.5
            header.titleLabel.textColor = UIColor.white
            header.isCenter = true
        
            return header
        }
        
        return nil
    }
    
    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        if section == 0 {
            let header = UIView()
            header.backgroundColor = UIColor.clear
            return header
        }
        
        return nil
    }
}
