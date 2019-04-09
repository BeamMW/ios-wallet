//
//  WalletViewController.swift
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

class WalletViewController: BaseViewController {

    private var rowHeight = [CGFloat(100.0),CGFloat(130.0),CGFloat(135.0)]
    private var expandAvailable = true
    private var expandProgress = true

    @IBOutlet private weak var talbeView: UITableView!
    @IBOutlet private var transactionsHeaderView: BaseView!

    private var transactions = [BMTransaction]()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        self.navigationItem.title = "Wallet"
        
        talbeView.register(WalletStatusCell.self)
        talbeView.register(WalletAvailableCell.self)
        talbeView.register(WalletProgressCell.self)
        talbeView.register(WalletTransactionCell.self)
        talbeView.addPullToRefresh(target: self, handler: #selector(refreshData(_:)))
        
        AppModel.sharedManager().addDelegate(self)
        AppModel.sharedManager().isLoggedin = true

        if let tr = AppModel.sharedManager().transactions {
            transactions = tr as! [BMTransaction]
        }
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
    
    @objc private func refreshData(_ sender: Any) {
       AppModel.sharedManager().getWalletStatus()
    }
    
    @IBAction func onMore(sender :UIButton) {
        
        let headerFrame = talbeView.convert(transactionsHeaderView.frame, to: self.view)

        let frame = CGRect(x: UIScreen.main.bounds.size.width-80, y: headerFrame.origin.y, width: 60, height: 40)
        
        var items = [BMPopoverMenu.BMPopoverMenuItem]()
        items.append(BMPopoverMenu.BMPopoverMenuItem(name: "Search", icon: "iconSearch", id:1))
        items.append(BMPopoverMenu.BMPopoverMenuItem(name: "Filter", icon: "iconFilter", id:2))
        items.append(BMPopoverMenu.BMPopoverMenuItem(name: "Payment proof", icon: "iconProof", id:3))

        BMPopoverMenu.showForSenderFrame(senderFrame: frame, with: items, done: { (selectedItem) in
            if let item = selectedItem {
                switch (item.id) {
                case 3:
                    let vc  = PaymentProofDetailViewController(transaction: nil, paymentProof: nil)
                    vc.hidesBottomBarWhenPushed = true
                    self.pushViewController(vc: vc)
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
    func onNetwotkStatusChange(_ connected: Bool) {
        DispatchQueue.main.async {
            self.talbeView.reloadRows(at: [IndexPath(row: 0, section: 0)], with: .none)
        }
    }
    
    func onWalletStatusChange(_ status: BMWalletStatus) {
        DispatchQueue.main.async {
            UIView.performWithoutAnimation {
                self.talbeView.stopRefreshing()
                self.talbeView.reloadData()
              //  self.talbeView.reloadRows(at: [IndexPath(row: 1, section: 0)], with: .none)
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
            let vc = WalletReceiveViewController()
            vc.hidesBottomBarWhenPushed = true
            self.pushViewController(vc: vc)
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

extension WalletViewController : WalletProgressCellDelegate {
    func onExpandProgress() {
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
