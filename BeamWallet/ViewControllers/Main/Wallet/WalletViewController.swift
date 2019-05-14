//
// WalletViewController.swift
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

class WalletViewController: BaseTableViewController {

    private var expandAvailable = true
    private var expandProgress = true
    
    private var transactions = [BMTransaction]()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        self.navigationItem.title = LocalizableStrings.wallet
        
        tableView.delegate = self
        tableView.dataSource = self
        
        tableView.register([WalletStatusCell.self, WalletAvailableCell.self, WalletProgressCell.self, WalletTransactionCell.self, EmptyCell.self])
        
        tableView.tableHeaderView = BMNetworkStatusView()

        tableView.addPullToRefresh(target: self, handler: #selector(refreshData(_:)))
        
        AppModel.sharedManager().walletAddresses = AppModel.sharedManager().getWalletAddresses()
        
        AppModel.sharedManager().addDelegate(self)
        AppModel.sharedManager().isLoggedin = true
        
        NotificationManager.sharedManager.subscribeToTopics(addresses: AppModel.sharedManager().walletAddresses as? [BMAddress])
        
        Settings.sharedManager().addDelegate(self)

        if let tr = AppModel.sharedManager().transactions {
            transactions = tr as! [BMTransaction]
        }
        
        expandProgress = !Settings.sharedManager().isHideAmounts
        expandAvailable = !Settings.sharedManager().isHideAmounts
        
        rightButton()
        
        if TGBotManager.sharedManager.isNeedLinking() {
            TGBotManager.sharedManager.startLinking { (_ ) in
                
            }
        }
        else{
            NotificationManager.sharedManager.displayConfirmAlert()
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        if !NotificationManager.sharedManager.clickedTransaction.isEmpty {
            if let transaction = transactions.first(where: { $0.id == NotificationManager.sharedManager.clickedTransaction }) {
                let vc = TransactionViewController(transaction: transaction)
                vc.hidesBottomBarWhenPushed = true
                self.pushViewController(vc: vc)
            }
            
            NotificationManager.sharedManager.clickedTransaction = ""
        }
    }
    
    
    private func rightButton() {
        let icon = Settings.sharedManager().isHideAmounts ? IconShowBalance() : IconHideBalance()
      
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(image: icon, style: .plain, target: self, action: #selector(onHideAmounts))
    }

    
    //MARK: - IBAction

    @objc private func onHideAmounts() {
        
        if !Settings.sharedManager().isHideAmounts {
            if Settings.sharedManager().isAskForHideAmounts {
    
                self.confirmAlert(title: LocalizableStrings.activate_security_title, message: LocalizableStrings.activate_security_text, cancelTitle: LocalizableStrings.cancel, confirmTitle: LocalizableStrings.activate, cancelHandler: { (_ ) in
                    
                }) { (_ ) in
                    Settings.sharedManager().isAskForHideAmounts = false
                    Settings.sharedManager().isHideAmounts = !Settings.sharedManager().isHideAmounts
                }
            }
            else{
                Settings.sharedManager().isHideAmounts = !Settings.sharedManager().isHideAmounts
            }
        }
        else{
            Settings.sharedManager().isHideAmounts = !Settings.sharedManager().isHideAmounts
        }
    }
    
    @objc private func refreshData(_ sender: Any) {
       AppModel.sharedManager().getWalletStatus()
    }
    
    @objc private func onMore(_ sender: Any) {
                
        var items = [BMPopoverMenu.BMPopoverMenuItem]()
        items.append(BMPopoverMenu.BMPopoverMenuItem(name: LocalizableStrings.payment_proof, icon: nil, action: .payment_proof))
        
        if transactions.count > 0 {
            items.append(BMPopoverMenu.BMPopoverMenuItem(name: LocalizableStrings.export, icon: nil, action: .export_transactions))
        }
        
        BMPopoverMenu.show(menuArray: items, done: { (selectedItem) in
            if let item = selectedItem {
                switch (item.action) {
                case .payment_proof:
                    let vc  = PaymentProofDetailViewController(transaction: nil, paymentProof: nil)
                    vc.hidesBottomBarWhenPushed = true
                    self.pushViewController(vc: vc)
                    return
                case .export_transactions:
                    AppModel.sharedManager().exportTransactions(toCSV: { (csvPath) in
                        let vc = UIActivityViewController(activityItems: [csvPath], applicationActivities: nil)
                        vc.excludedActivityTypes = [UIActivity.ActivityType.postToFacebook, UIActivity.ActivityType.assignToContact, UIActivity.ActivityType.copyToPasteboard, UIActivity.ActivityType.print,UIActivity.ActivityType.openInIBooks]
                        self.present(vc, animated: true)
                    })
                    return
                default:
                    return
                }
            }
        }, cancel: {
            
        })
    }
}

extension WalletViewController : UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        switch indexPath.section {
        case 0:
            if indexPath.row == 0 {
                return WalletStatusCell.height()
            }
            else if indexPath.row == 1 {
                if Settings.sharedManager().isHideAmounts || !expandAvailable {
                    return WalletAvailableCell.hideHeight()
                }
                else{
                   return AppModel.sharedManager().walletStatus?.maturing == 0 ? WalletAvailableCell.singleHeight() : WalletAvailableCell.mainHeight()
                }
            }
            else if indexPath.row == 2 {
                if Settings.sharedManager().isHideAmounts || !expandProgress {
                    return WalletProgressCell.hideHeight()
                }
                else{
                    return AppModel.sharedManager().walletStatus?.isSendingAndReceiving() ?? false ? WalletProgressCell.mainHeight() : WalletProgressCell.singleHeight()
                }
            }
            else{
                return 0
            }
        case 1:
            return WalletTransactionCell.height()
        default:
            return 0
        }
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        if section == 1 {
            return BMTableHeaderTitleView.height
        }
        return 0
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        if indexPath.section == 1 && transactions.count > 0 {
            let vc = TransactionViewController(transaction: transactions[indexPath.row])
            vc.hidesBottomBarWhenPushed = true
            pushViewController(vc: vc)
        }
    }
}

extension WalletViewController : UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        switch section {
        case 1:
            return BMTableHeaderTitleView(title: LocalizableStrings.transactions, handler: #selector(onMore), target: self)
        default:
            return nil
        }
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 2;
    }
    
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0:
           return AppModel.sharedManager().walletStatus?.hasInProgressBalance() ?? false ? 3 : 2
        case 1:
            return (transactions.count == 0) ? 1 : transactions.count
        default:
            return 0
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        switch indexPath.section {
        case 0:
            switch indexPath.row {
            case 0:
                let cell = tableView.dequeueReusableCell(withType: WalletStatusCell.self, for: indexPath)
                cell.delegate = self
                return cell
            case 1:
                let cell = tableView
                    .dequeueReusableCell(withType: WalletAvailableCell.self, for: indexPath)
                    .configured(with: (expand: expandAvailable, status: AppModel.sharedManager().walletStatus))
                cell.delegate = self
                return cell
            case 2:
                let cell =  tableView
                    .dequeueReusableCell(withType: WalletProgressCell.self, for: indexPath)
                    .configured(with: (expand: expandProgress, status: AppModel.sharedManager().walletStatus))
                cell.delegate = self
                return cell
            default:
                return UITableViewCell()
            }
        case 1:
            if transactions.count == 0 {
                let cell = tableView
                    .dequeueReusableCell(withType: EmptyCell.self, for: indexPath)
                    .configured(with: LocalizableStrings.empty_transactions_list)
                return cell
            }
            else{
                let cell = tableView
                    .dequeueReusableCell(withType: WalletTransactionCell.self, for: indexPath)
                    .configured(with: (row: indexPath.row, transaction: transactions[indexPath.row], single:false))
                return cell
            }
        default:
            return UITableViewCell()
        }
    }
}

extension WalletViewController : WalletModelDelegate {

    func onWalletStatusChange(_ status: BMWalletStatus) {
        DispatchQueue.main.async {
            UIView.performWithoutAnimation {
               
                self.tableView.stopRefreshing()

                if Settings.sharedManager().isLocalNode {
                    
                    if let cell = self.tableView.findCell(WalletAvailableCell.self) as? WalletAvailableCell {
                        cell.configure(with: (expand: self.expandAvailable, status: AppModel.sharedManager().walletStatus))
                    }
                    
                    if status.hasInProgressBalance() {
                        if let cell = self.tableView.findCell(WalletProgressCell.self) as? WalletProgressCell {
                            cell.configure(with: (expand: self.expandProgress, status: AppModel.sharedManager().walletStatus))
                        }
                    }
                }
                else{
                    self.tableView.reloadData()
                }
            }
        }
    }
    
    func onReceivedTransactions(_ transactions: [BMTransaction]) {
        DispatchQueue.main.async {
            if let tr = AppModel.sharedManager().transactions {
                self.transactions = tr as! [BMTransaction]
            }
            
            UIView.performWithoutAnimation {
                self.tableView.stopRefreshing()
                self.tableView.reloadData()
            }
        }
    }

    func onWalletAddresses(_ walletAddresses: [BMAddress]) {
        DispatchQueue.main.async {
            for address in walletAddresses {
                if address.isExpired() {
                    NotificationManager.sharedManager.unSubscribeToTopic(topic: address.walletId)
                }
                else{
                    NotificationManager.sharedManager.subscribeToTopic(topic: address.walletId)
                }
            }
        }
    }
}

extension WalletViewController : WalletStatusCellDelegate {
   
    func onClickReceived() {        
        AppModel.sharedManager().generateNewWalletAddress { (address, error) in
            if let result = address {
                DispatchQueue.main.async {
                    NotificationManager.sharedManager.subscribeToTopic(topic: result.walletId)
                    
                    let vc = WalletReceiveViewController(address: result)
                    vc.hidesBottomBarWhenPushed = true
                    self.pushViewController(vc: vc)
                }
            }
            else if let reason = error?.localizedDescription {
                DispatchQueue.main.async {
                    self.alert(message: reason)
                }
            }
        }
    }
    
    func onClickSend() {
        let vc = WalletSendViewController()
        vc.hidesBottomBarWhenPushed = true
        self.pushViewController(vc: vc)
    }
}

extension WalletViewController : WalletAvailableCellDelegate {
    
    func onExpandAvailable() {
        if !Settings.sharedManager().isHideAmounts {
            expandAvailable = !expandAvailable
            
            UIView.performWithoutAnimation {
                self.tableView.reloadRow(WalletAvailableCell.self)
            }
        }
    }
}

extension WalletViewController : WalletProgressCellDelegate {
    func onExpandProgress() {
        if !Settings.sharedManager().isHideAmounts {
            expandProgress = !expandProgress
            
            UIView.performWithoutAnimation {
                self.tableView.reloadRow(WalletProgressCell.self)
            }
        }
    }
}

extension WalletViewController : SettingsModelDelegate {
    func onChangeHideAmounts() {
        rightButton()
        
        expandProgress = !Settings.sharedManager().isHideAmounts
        expandAvailable = !Settings.sharedManager().isHideAmounts
        
        tableView.reloadData()
    }
}
