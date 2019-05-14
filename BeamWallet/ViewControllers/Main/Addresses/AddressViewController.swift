//
//  AddressViewController.swift
//  BeamWallet
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

class AddressViewController: BaseViewController {

    private var address:BMAddress!
    private var transactions:[BMTransaction]!
    private var isContact = false
    
    @IBOutlet private weak var tableView: UITableView!
    @IBOutlet private var headerView: UIView!
    
    init(address:BMAddress, isContact:Bool) {
        super.init(nibName: nil, bundle: nil)
        
        self.address = address
        self.isContact = isContact
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(image: UIImage(named: "iconMore"), style: .plain, target: self, action: #selector(onMore))

        tableView.register(AddressCell.self)
        tableView.register(WalletTransactionCell.self)

        getTransactions()
        
        title = "Address"
        
        AppModel.sharedManager().addDelegate(self)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        if isMovingFromParent
        {
            AppModel.sharedManager().removeDelegate(self)
        }
    }
    
    @objc private func onMore(sender:UIBarButtonItem) {

        var items = [BMPopoverMenu.BMPopoverMenuItem(name: "Show QR code", icon: nil, action:.show_qr_code), BMPopoverMenu.BMPopoverMenuItem(name: "Copy address", icon:nil, action:.copy_address), BMPopoverMenu.BMPopoverMenuItem(name: "Edit address", icon:nil, action: .edit_address), BMPopoverMenu.BMPopoverMenuItem(name: "Delete address", icon: nil, action: .delete_address)]
        
        if isContact {
            items.remove(at: 2)
        }

        BMPopoverMenu.show(menuArray: items, done: { (selectedItem) in
            if let item = selectedItem {
                switch (item.action) {
                case .show_qr_code:
                    let modalViewController = WalletQRCodeViewController(address: self.address.walletId, amount: nil)
                    modalViewController.modalPresentationStyle = .overFullScreen
                    modalViewController.modalTransitionStyle = .crossDissolve
                    self.present(modalViewController, animated: true, completion: nil)
                case .copy_address :
                    UIPasteboard.general.string = self.address.walletId
                    SVProgressHUD.showSuccess(withStatus: "copied to clipboard")
                    SVProgressHUD.dismiss(withDelay: 1.5)
                case .edit_address :
                    let vc = EditAddressViewController(address: self.address)
                    self.pushViewController(vc: vc)
                case .delete_address :
                    AppModel.sharedManager().deleteAddress(self.address.walletId)
                    
                    NotificationManager.sharedManager.unSubscribeToTopic(topic: self.address.walletId)
                    
                    self.navigationController?.popViewController(animated: true)
                default:
                    return
                }
            }
        }, cancel: {
            
        })
    }
    
    private func getTransactions() {
        transactions = (AppModel.sharedManager().getTransactionsFrom(address) as! [BMTransaction])
    }
}

extension AddressViewController : UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        if section == 1 {
            return 40
        }
        
        return 0
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if indexPath.section == 1 {
            return 86
        }
        return 90
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        if indexPath.section == 1 {
            let vc = TransactionViewController(transaction: transactions[indexPath.row])
            vc.hidesBottomBarWhenPushed = true
            pushViewController(vc: vc)
        }
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
        return 1
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        if indexPath.section == 0 {
            let cell =  tableView
                .dequeueReusableCell(withType: AddressCell.self, for: indexPath)
                .configured(with: (row: indexPath.row, address: address, single:true))
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
            return headerView
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
                
                UIView.performWithoutAnimation {
                    self.tableView.reloadData()
                }
            }
        }
    }
}

