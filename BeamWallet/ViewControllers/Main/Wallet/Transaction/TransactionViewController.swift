//
// TransactionViewController.swift
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

class TransactionViewController: BaseTableViewController {
    
    private var paymentProof:BMPaymentProof?
    private var utxos:[BMUTXO]!

    private var transaction:BMTransaction!
    private var details = [GeneralInfo]()

    init(transaction:BMTransaction) {
        super.init(nibName: nil, bundle: nil)

        self.transaction = transaction
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError(LocalizableStrings.fatalInitCoderError)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        title = LocalizableStrings.transaction_details
        
        tableView.delegate = self
        tableView.dataSource = self
        
        tableView.register(GeneralInfoCell.self)
        tableView.register(WalletTransactionCell.self)
        tableView.register(TransactionPaymentProofCell.self)
        tableView.register(TransactionUTXOCell.self)
        
        tableView.addPullToRefresh(target: self, handler: #selector(refreshData(_:)))

        fillTransactionInfo()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        AppModel.sharedManager().addDelegate(self)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        AppModel.sharedManager().removeDelegate(self)
    }
    
    @objc private func refreshData(_ sender: Any) {
        AppModel.sharedManager().getWalletStatus()
    }
    

    private func fillTransactionInfo() {
        self.navigationItem.rightBarButtonItem = (transaction.canCancel || transaction.canDelete) ? UIBarButtonItem(image: MoreIcon(), style: .plain, target: self, action: #selector(onMore)) : nil
        
        details.removeAll()
        
        details.append(GeneralInfo(text: LocalizableStrings.sending_address, detail: transaction.senderAddress, failed: false, canCopy:true, color: UIColor.white))
        
        details.append(GeneralInfo(text: LocalizableStrings.receiving_address, detail: transaction.receiverAddress, failed: false, canCopy:true, color: UIColor.white))

        details.append(GeneralInfo(text: LocalizableStrings.transaction_fee, detail: String.currency(value: transaction.fee), failed: false, canCopy:true, color: UIColor.white))
        
        details.append(GeneralInfo(text: LocalizableStrings.transaction_id, detail: transaction.id, failed: false, canCopy:true, color: UIColor.white))
        
        details.append(GeneralInfo(text: LocalizableStrings.kernel_id, detail: transaction.kernelId, failed: false, canCopy:true, color: UIColor.white))
        
        if !transaction.comment.isEmpty {
            details.append(GeneralInfo(text: LocalizableStrings.comment, detail: transaction.comment, failed: false, canCopy:true, color: UIColor.white))
        }
        
        if transaction.isFailed() {
            details.append(GeneralInfo(text: LocalizableStrings.failure_reason, detail: transaction.failureReason, failed: true, canCopy:true, color: UIColor.white))
        }
        
        //utxos
        utxos = (AppModel.sharedManager().getUTXOSFrom(transaction) as! [BMUTXO])
        
        if paymentProof == nil && transaction.hasPaymentProof()  {
            AppModel.sharedManager().getPaymentProof(transaction)
        }

        tableView.reloadData()
    }
    
    @objc private func onMore(sender:UIBarButtonItem) {        
        var items = [BMPopoverMenu.BMPopoverMenuItem]()
        
        if transaction.canCancel {
            items.append(BMPopoverMenu.BMPopoverMenuItem(name: LocalizableStrings.cancel_transaction, icon: nil, action: .cancel_transaction))
        }
        
        if transaction.canDelete {
            items.append(BMPopoverMenu.BMPopoverMenuItem(name: LocalizableStrings.delete_transaction, icon: nil, action: .delete_transaction))
        }
        
        BMPopoverMenu.show(menuArray: items, done: { (selectedItem) in
            if let item = selectedItem {
                switch (item.action) {
                case .cancel_transaction :
                    AppModel.sharedManager().cancelTransaction(self.transaction)
                    self.navigationController?.popViewController(animated: true)
                case .delete_transaction :
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
        switch section {
        case 1:
            return BMTableHeaderTitleView.boldHeight
        case 2:
            return (paymentProof != nil) ? BMTableHeaderTitleView.boldHeight : 0
        case 3:
            return (utxos.count > 0 && !Settings.sharedManager().isHideAmounts) ? 60 : 0
        default:
            return 0
        }
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return (indexPath.section == 0) ? WalletTransactionCell.height() : UITableView.automaticDimension
    }
}

extension TransactionViewController : UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 4
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0:
            return 1
        case 1:
            return details.count
        case 2:
            return (paymentProof != nil) ? 1 : 0
        case 3:
            return (Settings.sharedManager().isHideAmounts) ? 0 : utxos.count
        default:
            return 0
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        switch indexPath.section {
        case 0:
            let cell = tableView
                .dequeueReusableCell(withType: WalletTransactionCell.self, for: indexPath)
                .configured(with: (row: indexPath.row, transaction: transaction, single:true))
            return cell
        case 1:
            let cell = tableView
                .dequeueReusableCell(withType: GeneralInfoCell.self, for: indexPath)
                .configured(with: details[indexPath.row])
            cell.delegate = self
            return cell
        case 2:
            let cell = tableView
                .dequeueReusableCell(withType: TransactionPaymentProofCell.self, for: indexPath)
            cell.delegate = self
            return cell
        case 3:
            let cell = tableView
                .dequeueReusableCell(withType: TransactionUTXOCell.self, for: indexPath)
            cell.configure(with: utxos[indexPath.row])
            return cell
        default:
            return UITableViewCell()
        }
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        switch section {
        case 0:
            return nil
        case 1:
            return BMTableHeaderTitleView(title: LocalizableStrings.general_info, bold: true)
        case 2:
            return (paymentProof != nil) ? BMTableHeaderTitleView(title: LocalizableStrings.payment_proof, bold: true) : nil
        case 3:
            return (utxos.count > 0 && !Settings.sharedManager().isHideAmounts) ? BMTableHeaderTitleView(title: LocalizableStrings.utxo_list, bold: true) : nil
        default:
            return nil
        }
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
            ShowCopiedProgressHUD()
        }
    }
}

extension TransactionViewController : GeneralInfoCellDelegate {
    func onClickToCell(cell: UITableViewCell) {
        if let path = tableView.indexPath(for: cell)
        {
            if details[path.row].text == LocalizableStrings.kernel_id {
                let kernelId = self.transaction.kernelId!
                let link = Settings.sharedManager().explorerAddress + "block?kernel_id=" + kernelId
                if let url = URL(string: link) {
                    openUrl(url: url)
                }
            }
        }
    }
}
