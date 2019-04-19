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

class WalletViewController: BaseViewController {

    private var rowHeight = [CGFloat(66.0),CGFloat(130.0),CGFloat(135.0)]
    private var expandAvailable = true
    private var expandProgress = true

    @IBOutlet private weak var talbeView: UITableView!
    @IBOutlet private var transactionsHeaderView: BaseView!
    @IBOutlet private var networkHeaderView: UIView!

    private var transactions = [BMTransaction]()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        self.navigationItem.title = "Wallet"
        
        talbeView.tableHeaderView = networkHeaderView
        
        talbeView.register(WalletStatusCell.self)
        talbeView.register(WalletAvailableCell.self)
        talbeView.register(WalletProgressCell.self)
        talbeView.register(WalletTransactionCell.self)
        talbeView.addPullToRefresh(target: self, handler: #selector(refreshData(_:)))
        
        AppModel.sharedManager().walletAddresses = AppModel.sharedManager().getWalletAddresses()

        AppModel.sharedManager().addDelegate(self)
        AppModel.sharedManager().isLoggedin = true
        
        subscribeToAPNSTopics()
        
        Settings.sharedManager().delegate = self
        
        if let tr = AppModel.sharedManager().transactions {
            transactions = tr as! [BMTransaction]
        }
        
        if Settings.sharedManager().isHideAmounts {
            rowHeight[1] = 80
            rowHeight[2] = 65
            
            expandProgress = false
            expandAvailable = false
        }
        
        rightButton()        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        if !NotificationManager.sharedManager.clickedTransaction.isEmpty {
            if let transaction = transactions.first(where: { $0.id == NotificationManager.sharedManager.clickedTransaction }) {
                let vc = TransactionViewController()
                vc.hidesBottomBarWhenPushed = true
                vc.configure(with: transaction)
                self.pushViewController(vc: vc)
            }
            
            NotificationManager.sharedManager.clickedTransaction = ""
        }
    }
    
    
    private func rightButton() {
        let icon = Settings.sharedManager().isHideAmounts ? UIImage(named: "iconShowBalance") : UIImage(named: "iconHideBalance")
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(image: icon, style: .plain, target: self, action: #selector(onHideAmounts))
    }
    
    private func subscribeToAPNSTopics() {
        if let walletAddresses = AppModel.sharedManager().walletAddresses as? [BMAddress] {
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
    
    //MARK: - IBAction

    @objc private func onHideAmounts() {
        if !Settings.sharedManager().isHideAmounts {
            let alert = UIAlertController(title: "Activate security mode", message: "All balances will be hidden till you will press this button again", preferredStyle: .alert)
            

            alert.addAction(UIAlertAction(title: "Cancel", style: .default, handler:{ (UIAlertAction)in
            }))
            
            alert.addAction(UIAlertAction(title: "Activate", style: .default, handler:{ (UIAlertAction)in
                
                Settings.sharedManager().isHideAmounts = !Settings.sharedManager().isHideAmounts
            }))
            
            self.present(alert, animated: true)
            
        }
        else{
            Settings.sharedManager().isHideAmounts = !Settings.sharedManager().isHideAmounts
        }
    }
    
    @objc private func refreshData(_ sender: Any) {
       AppModel.sharedManager().getWalletStatus()
    }
    
    @IBAction func onMore(sender :UIButton) {
        
        let headerFrame = talbeView.convert(transactionsHeaderView.frame, to: self.view)

        let frame = CGRect(x: UIScreen.main.bounds.size.width-80, y: headerFrame.origin.y, width: 60, height: 40)
        
        var items = [BMPopoverMenu.BMPopoverMenuItem]()
      // items.append(BMPopoverMenu.BMPopoverMenuItem(name: "Search", icon: "iconSearch", id:1))
      // items.append(BMPopoverMenu.BMPopoverMenuItem(name: "Filter", icon: "iconFilter", id:2))
        items.append(BMPopoverMenu.BMPopoverMenuItem(name: "Payment proof", icon: nil, id:3))
        items.append(BMPopoverMenu.BMPopoverMenuItem(name: "Export", icon: nil, id:4))


        BMPopoverMenu.showForSenderFrame(senderFrame: frame, with: items, done: { (selectedItem) in
            if let item = selectedItem {
                switch (item.id) {
                case 3:
                    let vc  = PaymentProofDetailViewController(transaction: nil, paymentProof: nil)
                    vc.hidesBottomBarWhenPushed = true
                    self.pushViewController(vc: vc)
                    return
                case 4:
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
        if indexPath.section == 0 && indexPath.row == 0 {
            return rowHeight[0]
        }
        else if indexPath.section == 0 && indexPath.row == 1 {
            return rowHeight[1]
        }
        else if indexPath.section == 0 && indexPath.row == 2 {
            return rowHeight[2]
        }
        else if indexPath.section == 1 {
            return 86
        }
        return 0
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        if section == 1 {
            return 40
        }
        return 0
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        if indexPath.section == 1 {
            let vc = TransactionViewController()
            vc.hidesBottomBarWhenPushed = true
            vc.configure(with: transactions[indexPath.row])
            pushViewController(vc: vc)
        }
    }
}

extension WalletViewController : UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        if section == 1 {
           return transactionsHeaderView
        }
        
        return nil
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        if transactions.count > 0 {
            return 2;
        }
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 1 {
            return transactions.count
        }
        else if let status = AppModel.sharedManager().walletStatus {
            if status.realMaturing == 0
                && status.realReceiving == 0
                && status.realSending == 0 {
                return 2
            }
        }
        return 3
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        if indexPath.section == 0 && indexPath.row == 0 {
            let cell = tableView.dequeueReusableCell(withType: WalletStatusCell.self, for: indexPath)
            cell.delegate = self
            return cell
        }
        else if indexPath.section == 0 && indexPath.row == 1 {
            let cell = tableView
                .dequeueReusableCell(withType: WalletAvailableCell.self, for: indexPath)
                .configured(with: (expand: expandAvailable, status: AppModel.sharedManager().walletStatus))
            cell.delegate = self
            return cell
        }
        else if indexPath.section == 0 && indexPath.row == 2 {
            let cell =  tableView
                .dequeueReusableCell(withType: WalletProgressCell.self, for: indexPath)
                .configured(with: (expand: expandProgress, status: AppModel.sharedManager().walletStatus))
            cell.delegate = self
            return cell
        }
        else if indexPath.section == 1 {
            let cell =  tableView
                .dequeueReusableCell(withType: WalletTransactionCell.self, for: indexPath)
                .configured(with: (row: indexPath.row, transaction: transactions[indexPath.row], single:false))
            return cell
        }
        
        return UITableViewCell()
    }
    
}

extension WalletViewController : WalletModelDelegate {

    func onWalletStatusChange(_ status: BMWalletStatus) {
        DispatchQueue.main.async {
            UIView.performWithoutAnimation {
                self.talbeView.stopRefreshing()

                if Settings.sharedManager().isLocalNode {
                    let progressIsNull = (status.realMaturing == 0
                        && status.realReceiving == 0
                        && status.realSending == 0)
                    
                    if let cell = self.talbeView.cellForRow(at: IndexPath(row: 1, section: 0)) as? WalletAvailableCell
                    {
                        cell.configure(with: (expand: self.expandAvailable, status: AppModel.sharedManager().walletStatus))
                    }
                    else{
                        self.talbeView.reloadData()
                    }
                    
                    if !progressIsNull {
                        if let cell = self.talbeView.cellForRow(at: IndexPath(row: 2, section: 0)) as? WalletProgressCell
                        {
                            cell.configure(with: (expand: self.expandProgress, status: AppModel.sharedManager().walletStatus))
                        }
                        else{
                            self.talbeView.reloadData()
                        }
                    }
                }
                else{
                    self.talbeView.reloadData()
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
                self.talbeView.stopRefreshing()
                self.talbeView.reloadData()
            }
        }
    }
    
    func onGeneratedNewAddress(_ address: BMAddress) {
        DispatchQueue.main.async {
            NotificationManager.sharedManager.subscribeToTopic(topic: address.walletId)

            let vc = WalletReceiveViewController()
            vc.hidesBottomBarWhenPushed = true
            self.pushViewController(vc: vc)
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
        AppModel.sharedManager().generateNewWalletAddress()
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
            
            if !expandAvailable {
                rowHeight[1] = 80
            }
            else{
                rowHeight[1] = 130
            }
            
            self.talbeView.reloadRows(at: [IndexPath(row: 1, section: 0)], with: .fade)
        }
    }
}

extension WalletViewController : WalletProgressCellDelegate {
    func onExpandProgress() {
        if !Settings.sharedManager().isHideAmounts {
            expandProgress = !expandProgress
            
            if !expandProgress {
                rowHeight[2] = 65
            }
            else{
                rowHeight[2] = 135
            }
            
            self.talbeView.reloadRows(at: [IndexPath(row: 2, section: 0)], with: .fade)
        }
    }
}

extension WalletViewController : SettingsModelDelegate {
    func onChangeHideAmounts() {
        rightButton()
        
        if Settings.sharedManager().isHideAmounts {
            rowHeight[1] = 80
            rowHeight[2] = 65
            
            expandProgress = false
            expandAvailable = false
        }
        else{
            rowHeight[1] = 130
            rowHeight[2] = 135
            
            expandProgress = true
            expandAvailable = true
        }
        
        talbeView.reloadData()
    }
}
