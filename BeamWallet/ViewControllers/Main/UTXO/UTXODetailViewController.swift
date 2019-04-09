//
//  UTXODetailViewController.swift
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

class UTXODetailViewController: BaseViewController {

    @IBOutlet private weak var tableView: UITableView!
    @IBOutlet private var headerInfoView: UIView!
    @IBOutlet private var headerHistoryView: UIView!

    private var details = [TransactionViewController.TransactionGeneralInfo]()
    private var history = [BMTransaction]()

    private var utxo:BMUTXO!
    
    init(utxo:BMUTXO) {
        super.init(nibName: nil, bundle: nil)
        
        self.utxo = utxo
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        fillDetailInfo()
        
        tableView.register(UTXODetailCell.self)
        tableView.register(GeneralTransactionInfoCell.self)
        tableView.register(UTXOTransactionCell.self)

        title = "UTXO Details"
    }
    
    private func fillDetailInfo() {
        history = AppModel.sharedManager().getTransactionsFrom(utxo) as! [BMTransaction]
        
        if let txid = utxo.createTxId {
            details.append(TransactionViewController.TransactionGeneralInfo(text: "Transaction ID:", detail: txid, failed: false, canCopy:true))
        }
        else if let txid = utxo.spentTxId {
            details.append(TransactionViewController.TransactionGeneralInfo(text: "Transaction ID:", detail: txid, failed: false, canCopy:true))
        }
        details.append(TransactionViewController.TransactionGeneralInfo(text: "UTXO type:", detail: utxo.typeString, failed: false, canCopy:true))
        
//        for transaction in history {
//            if let contact = AppModel.sharedManager().getContactFromId(transaction.receiverAddress)
//            {
//                let value = contact.name.isEmpty ? contact.address.walletId : contact.name + "\n" + contact.address.walletId
//                details.append(TransactionViewController.TransactionGeneralInfo(text: "Contact:", detail: value, failed: false, canCopy:true))
//            }
//        }
    }
}

extension UTXODetailViewController : UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        if section == 1 || section == 2 {
            if section == 2 {
                return 100
            }
            return 60
        }
        
        return 0
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if indexPath.section == 0 {
            return 80
        }
        return UITableView.automaticDimension
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
}

extension UTXODetailViewController : UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        if history.count > 0 {
            return 3
        }
        return 2
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            return 1
        }
        else if section == 1 {
            return details.count
        }
        return history.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        if indexPath.section == 0 {
            let cell = tableView
                .dequeueReusableCell(withType: UTXODetailCell.self, for: indexPath)
                .configured(with: (row: indexPath.row, utxo: utxo))
            return cell
        }
        else if indexPath.section == 1{
            let cell =  tableView
                .dequeueReusableCell(withType: GeneralTransactionInfoCell.self, for: indexPath)
                .configured(with: details[indexPath.row])
            
            return cell
        }
        else{
            let cell =  tableView
                .dequeueReusableCell(withType: UTXOTransactionCell.self, for: indexPath)
                .configured(with: history[indexPath.row])
            
            return cell
        }
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        if section == 0 {
            return nil
        }
        else if section == 1 {
            return headerInfoView
        }
        else{
            return headerHistoryView
        }
    }
}
