//
//  TransactionViewController.swift
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

class TransactionViewController: BaseViewController {
    
    @IBOutlet private weak var tableView: UITableView!
    @IBOutlet private var headerView: UIView!
    @IBOutlet private var proofHeaderView: UIView!
    @IBOutlet private var utxosHeaderView: UIView!

    
    struct TransactionGeneralInfo {
        var text:String!
        var detail:String!
        var failed:Bool!
        var canCopy:Bool!
    }
    
    private var paymentProof:BMPaymentProof?
    private var utxos:[BMUTXO]!

    private var transaction:BMTransaction!
    private var details = [TransactionGeneralInfo]()

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "Transaction details"
        
        tableView.register(GeneralTransactionInfoCell.self)
        tableView.register(WalletTransactionCell.self)
        tableView.register(TransactionPaymentProofCell.self)
        tableView.register(TransactionUTXOCell.self)
        
        tableView.addPullToRefresh(target: self, handler: #selector(refreshData(_:)))

        fillTransactionInfo()
        
        getPaymentProof()
    }
    
    @objc private func refreshData(_ sender: Any) {
        AppModel.sharedManager().getWalletStatus()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        AppModel.sharedManager().addDelegate(self)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        AppModel.sharedManager().removeDelegate(self)
    }
    
    private func getPaymentProof() {
        if transaction.hasPaymentProof() {
            AppModel.sharedManager().getPaymentProof(transaction)
        }
    }
    
    private func fillTransactionInfo() {
        if transaction.canCancel || transaction.canDelete {
            self.navigationItem.rightBarButtonItem = UIBarButtonItem(image: UIImage(named: "iconMore"), style: .plain, target: self, action: #selector(onMore))
        }
        else{
            self.navigationItem.rightBarButtonItem = nil
        }
        
        details = [TransactionGeneralInfo]()
        details.append(TransactionGeneralInfo(text: "Sending address:", detail: transaction.senderAddress, failed: false, canCopy:true))
        details.append(TransactionGeneralInfo(text: "Receiving address:", detail: transaction.receiverAddress, failed: false, canCopy:true))
        details.append(TransactionGeneralInfo(text: "Transaction fee:", detail: String.currency(value: transaction.fee), failed: false, canCopy:true))
        details.append(TransactionGeneralInfo(text: "Kernel ID:", detail: transaction.kernelId, failed: false, canCopy:true))
        
        if !transaction.comment.isEmpty {
            details.append(TransactionGeneralInfo(text: "Comment:", detail: transaction.comment, failed: false, canCopy:true))
        }
        
        if transaction.isFailed() {
            details.append(TransactionGeneralInfo(text: "Failure reason:", detail: transaction.failureReason, failed: true, canCopy:true))
        }
        
        //utxos
        utxos = (AppModel.sharedManager().getUTXOSFrom(transaction) as! [BMUTXO])
        
        tableView.reloadData()
    }
    
    @objc private func onMore(sender:UIBarButtonItem) {
        let frame = CGRect(x: UIScreen.main.bounds.size.width-80, y: 44, width: 60, height: 40)
//        var items = [BMPopoverMenu.BMPopoverMenuItem(name: "Repeat transaction", icon: "iconRepeat", id:1) /*, BMPopoverMenu.BMPopoverMenuItem(name: "Save peer address", icon: "iconSaveAddress", id:2)*/]
        
        var items = [BMPopoverMenu.BMPopoverMenuItem]()
        
        if transaction.canCancel {
            items.append(BMPopoverMenu.BMPopoverMenuItem(name: "Cancel transaction", icon: "iconCancelTransction", id:3))
        }
        if transaction.canDelete {
            items.append(BMPopoverMenu.BMPopoverMenuItem(name: "Delete transaction", icon: "iconDelete", id:4))
        }
        
        BMPopoverMenu.showForSenderFrame(senderFrame: frame, with: items, done: { (selectedItem) in
            if let item = selectedItem {
                switch (item.id) {
                case 1:
                    let vc = WalletSendViewController()
                    vc.transaction = self.transaction
                    self.pushViewController(vc: vc)
                case 3 :
                    AppModel.sharedManager().cancelTransaction(self.transaction)
                    self.navigationController?.popViewController(animated: true)
                case 4 :
                    AppModel.sharedManager().deleteTransaction(self.transaction)
                    self.navigationController?.popViewController(animated: true)
                default:
                    return
                }
            }
        }, cancel: {
            
        })
    }
}

extension TransactionViewController : UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        if section == 2 && paymentProof != nil {
            return 60
        }
        else if section == 3 && utxos.count > 0 {
            return 60
        }
        else if section == 1 {
            return 60
        }
        return 0
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if indexPath.section == 0 {
            return 86
        }
        return UITableView.automaticDimension
    }
    
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
}

extension TransactionViewController : UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 4
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            return 1
        }
        else if section == 1 {
            return details.count
        }
        else if section == 2 && paymentProof != nil {
            return 1
        }
        else if section == 3 {
            return utxos.count
        }
        return 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        if indexPath.section == 0 {
            let cell =  tableView
                .dequeueReusableCell(withType: WalletTransactionCell.self, for: indexPath)
                .configured(with: (row: indexPath.row, transaction: transaction, single:true))
            return cell
        }
        else if indexPath.section == 1 {
            let cell =  tableView
                .dequeueReusableCell(withType: GeneralTransactionInfoCell.self, for: indexPath)
                .configured(with: details[indexPath.row])
           
            return cell
        }
        else if indexPath.section == 2 {
            let cell =  tableView
                .dequeueReusableCell(withType: TransactionPaymentProofCell.self, for: indexPath)
            cell.delegate = self
            
            return cell
        }
        else if indexPath.section == 3 {
            let cell =  tableView
                .dequeueReusableCell(withType: TransactionUTXOCell.self, for: indexPath)
            cell.configure(with: utxos[indexPath.row])
            
            return cell
        }
        
        return UITableViewCell()
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        if section == 0 {
            return nil
        }
        else if section == 1 {
            return headerView
        }
        else if section == 2 && paymentProof != nil {
            return proofHeaderView
        }
        else if section == 3 && utxos.count > 0 {
            return utxosHeaderView
        }
        return nil
    }
    
}

extension TransactionViewController : WalletModelDelegate {

    func onReceivedTransactions(_ transactions: [BMTransaction]) {
        DispatchQueue.main.async {
            if let transaction = transactions.first(where: { $0.id == self.transaction.id }) {
                self.transaction = transaction
                
                UIView.performWithoutAnimation {
                    self.tableView.stopRefreshing()
                    self.fillTransactionInfo()
                }
            }
        }
    }
    
    func onReceive(_ proof: BMPaymentProof) {
        DispatchQueue.main.async {
            if proof.txID == self.transaction.id {
                self.paymentProof = proof
                
                UIView.performWithoutAnimation {
                    self.tableView.reloadData()
                }
            }
        }
    }
}

extension TransactionViewController: Configurable {
    
    func configure(with transaction:BMTransaction) {
        self.transaction = transaction
    }
}

extension TransactionViewController: TransactionPaymentProofCellDelegate {
    func onPaymentProofDetails() {
        if let proof = paymentProof {
            let vc = PaymentProofDetailViewController(transaction: transaction, paymentProof: proof)
            pushViewController(vc: vc)
        }
    }
    
    func onPaymentProofCopy() {
        if let code = paymentProof?.code {
            UIPasteboard.general.string = code
            
            SVProgressHUD.showSuccess(withStatus: "copied to clipboard")
            SVProgressHUD.dismiss(withDelay: 1.5)
        }
    }
}
