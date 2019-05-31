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

    private var address:BMAddress!
    private var transactions = [BMTransaction]()
    private var details = [GeneralInfo]()

    private var isContact = false
    
    init(address:BMAddress, isContact:Bool) {
        super.init(nibName: nil, bundle: nil)
        
        self.address = address
        self.isContact = isContact
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError(LocalizableStrings.fatalInitCoderError)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(image: MoreIcon(), style: .plain, target: self, action: #selector(onMore))

        getTransactions()
        fillDetails()
        
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register([GeneralInfoCell.self, WalletTransactionCell.self])
        tableView.tableHeaderView = UIView(frame: CGRect(x: 0, y: 0, width: 0, height: 10))
        
        title = LocalizableStrings.address
        
        AppModel.sharedManager().addDelegate(self)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        if isMovingFromParent
        {
            AppModel.sharedManager().removeDelegate(self)
        }
    }
    
    private func fillDetails() {
        details.removeAll()
        
        details.append(GeneralInfo(text: LocalizableStrings.address_id, detail: self.address.walletId, failed: false, canCopy:true, color: UIColor.white))
        
        if !isContact {
            details.append(GeneralInfo(text: LocalizableStrings.exp_date, detail: self.address.formattedDate(), failed: false, canCopy:false, color: UIColor.white))
            
            if !self.address.category.isEmpty {
                if let category = AppModel.sharedManager().findCategory(byId: self.address.category) {
                    details.append(GeneralInfo(text: LocalizableStrings.category + ":", detail: category.name, failed: false, canCopy:false, color: UIColor.init(hexString: category.color)))
                }
            }
        }
        
        if !self.address.label.isEmpty {
            details.append(GeneralInfo(text: LocalizableStrings.annotation, detail: self.address.label, failed: false, canCopy:false, color: UIColor.white))
        }
    }
    
    @objc private func onMore(sender:UIBarButtonItem) {

        var items = [BMPopoverMenu.BMPopoverMenuItem(name: LocalizableStrings.show_qr_code, icon: nil, action: .show_qr_code), BMPopoverMenu.BMPopoverMenuItem(name: LocalizableStrings.copy_address, icon: nil, action:.copy_address), BMPopoverMenu.BMPopoverMenuItem(name: LocalizableStrings.edit_address, icon: nil, action:.edit_address), BMPopoverMenu.BMPopoverMenuItem(name: LocalizableStrings.delete_address, icon: nil, action:.delete_address)]
        
        if isContact {
            items.remove(at: 2)
        }

        BMPopoverMenu.show(menuArray: items, done: { (selectedItem) in
            if let item = selectedItem {
                switch (item.action) {
                case .show_qr_code:
                    let modalViewController = ReceiveQRViewController(address: self.address, amount: nil)
                    modalViewController.modalPresentationStyle = .overFullScreen
                    modalViewController.modalTransitionStyle = .crossDissolve
                    self.present(modalViewController, animated: true, completion: nil)
                case .copy_address :
                    UIPasteboard.general.string = self.address.walletId
                    ShowCopied()
                case .edit_address :
                    let vc = EditAddressViewController(address: self.address)
                    self.pushViewController(vc: vc)
                case .delete_address :
                    if self.transactions.count > 0  {
                        self.showDeleteAddressAndTransactions()
                    }
                    else{
                        AppModel.sharedManager().prepareDelete(self.address, removeTransactions: false)
                        
                      //  AppModel.sharedManager().deleteAddress(self.address.walletId)
                        
                     //   NotificationManager.sharedManager.unSubscribeToTopic(topic: self.address.walletId)
                        
                        self.navigationController?.popViewController(animated: true)
                    }
         
                default:
                    return
                }
            }
        }, cancel: {
            
        })
    }
    
    private func showDeleteAddressAndTransactions() {
        let items = [BMPopoverMenu.BMPopoverMenuItem(name: LocalizableStrings.delete_address_transaction, icon: nil, action: .delete_address_transactions), BMPopoverMenu.BMPopoverMenuItem(name: LocalizableStrings.delete_address_only, icon: nil, action:.delete_address)]
        
        BMPopoverMenu.show(menuArray: items, done: { (selectedItem) in
            if let item = selectedItem {
                switch (item.action) {
                case .delete_address:
                    AppModel.sharedManager().prepareDelete(self.address, removeTransactions: false)

                  //  AppModel.sharedManager().deleteAddress(self.address.walletId)
                    
                 //   NotificationManager.sharedManager.unSubscribeToTopic(topic: self.address.walletId)
                    
                    self.navigationController?.popViewController(animated: true)
                case .delete_address_transactions :
                    AppModel.sharedManager().removeDelegate(self)
                    
                  //  for tr in self.transactions {
                    //    AppModel.sharedManager().deleteTransaction(tr)
                  //  }
                    
                  //  AppModel.sharedManager().deleteAddress(self.address.walletId)
                    
                 //   NotificationManager.sharedManager.unSubscribeToTopic(topic: self.address.walletId)
                    
                    AppModel.sharedManager().prepareDelete(self.address, removeTransactions: true)

                    self.navigationController?.popViewController(animated: true)
                default:
                    return
                }
            }
        }) {
            
        }
    }
    
    private func getTransactions() {
        transactions = (AppModel.sharedManager().getTransactionsFrom(address) as! [BMTransaction])
    }
}

extension AddressViewController : UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        if indexPath.section == 1 && transactions.count > 0 {
            return true
        }
        
        return false
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        if section == 1 {
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
            let vc = TransactionViewController(transaction: transactions[indexPath.row])
            vc.hidesBottomBarWhenPushed = true
            pushViewController(vc: vc)
        }
    }
    
    func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
        
        let transaction = transactions[indexPath.row]
        
        let cancel = UITableViewRowAction(style: .normal, title: LocalizableStrings.cancel) { action, index in
            
            self.confirmAlert(title: LocalizableStrings.cancel_transaction, message: LocalizableStrings.cancel_transaction_text, cancelTitle: LocalizableStrings.no, confirmTitle: LocalizableStrings.yes, cancelHandler: { (_) in
                
            }, confirmHandler: { (_) in
                transaction.status = LocalizableStrings.cancelled
                
                self.tableView.performUpdate({
                    self.tableView.reloadRows(at: [indexPath], with: .fade)
                }, completion: {
                    AppModel.sharedManager().cancelTransaction(transaction)
                })
            })
        }
        cancel.backgroundColor = UIColor.main.steel
        
        let rep = UITableViewRowAction(style: .normal, title: LocalizableStrings.rep) { action, index in
            let vc = WalletSendViewController()
            vc.transaction = transaction
            self.pushViewController(vc: vc)
        }
        rep.backgroundColor = UIColor.main.brightBlue
        
        let delete = UITableViewRowAction(style: .normal, title: LocalizableStrings.delete) { action, index in
            
            self.confirmAlert(title: LocalizableStrings.delete_transaction_title, message: LocalizableStrings.delete_transaction_text, cancelTitle: LocalizableStrings.cancel, confirmTitle: LocalizableStrings.delete, cancelHandler: { (_ ) in
                
            }, confirmHandler: { (_ ) in
                self.transactions.remove(at: indexPath.row)
                self.tableView.performUpdate({
                    self.tableView.deleteRows(at: [indexPath], with: .left)
                }, completion: {
                    AppModel.sharedManager().deleteTransaction(transaction)
                })
            })
        }
        delete.backgroundColor = UIColor.main.orangeRed
        
        var actions = [UITableViewRowAction]()
        
        if transaction.canCancel {
            actions.append(cancel)
        }
        
        if !transaction.isIncome {
            actions.append(rep)
        }
        
        if transaction.canDelete {
            actions.append(delete)
        }
        
        return actions.reversed()
    }
}

extension AddressViewController : UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        if transactions.count > 0 {
            return 2
        }
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 1 {
            return transactions.count
        }
        return self.details.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        if indexPath.section == 0 {
            let cell = tableView
                .dequeueReusableCell(withType: GeneralInfoCell.self, for: indexPath)
                .configured(with: details[indexPath.row])
            return cell
        }
        else{
            let cell =  tableView
                .dequeueReusableCell(withType: WalletTransactionCell.self, for: indexPath)
                .configured(with: (row: indexPath.row, transaction: transactions[indexPath.row], single:false))
            return cell
        }
        
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        if section == 1 {
            return BMTableHeaderTitleView(title: LocalizableStrings.transactions, bold: true)
        }
        
        return nil
    }
    
    
}

extension AddressViewController : WalletModelDelegate {
    
    func onReceivedTransactions(_ transactions: [BMTransaction]) {
        DispatchQueue.main.async {
            self.getTransactions()
            
            UIView.performWithoutAnimation {
                self.tableView.reloadData()
            }
        }
    }
    
    func onWalletAddresses(_ walletAddresses: [BMAddress]) {
        DispatchQueue.main.async {
            if let address = walletAddresses.first(where: { $0.walletId == self.address.walletId }) {
                self.address = address
                
                self.fillDetails()
                
                UIView.performWithoutAnimation {
                    self.tableView.reloadData()
                }
            }
        }
    }
}

