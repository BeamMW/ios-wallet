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

    private var transaction:BMTransaction!
    
    @IBOutlet private weak var talbeView: UITableView!

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "Transaction details"
        
        talbeView.register(GeneralTransactionInfoCell.self)
        
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(image: UIImage(named: "iconMore"), style: .plain, target: self, action: #selector(onMore))
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        AppModel.sharedManager().addDelegate(self)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        AppModel.sharedManager().removeDelegate(self)
    }
    
    @objc private func onMore(sender:UIBarButtonItem) {
        
        if transaction.canCancel {
            let alert = UIAlertController(title: "Cancel Transaction", message: nil, preferredStyle: .actionSheet)
            
            alert.addAction(UIAlertAction(title: "Yes", style: .default , handler:{ (UIAlertAction)in
                
                AppModel.sharedManager().cancelTransaction(self.transaction)
                self.navigationController?.popViewController(animated: true)
            }))
            
            alert.addAction(UIAlertAction(title: "No", style: .cancel, handler:{ (UIAlertAction)in
            }))
            
            self.present(alert, animated: true, completion: {
            })
        }
        else if transaction.canDelete {
            let alert = UIAlertController(title: "Delete Transaction", message: nil, preferredStyle: .actionSheet)
            
            alert.addAction(UIAlertAction(title: "Delete", style: .destructive , handler:{ (UIAlertAction)in
                
                AppModel.sharedManager().deleteTransaction(self.transaction)
                self.navigationController?.popViewController(animated: true)
            }))
            
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler:{ (UIAlertAction)in
            }))
            
            self.present(alert, animated: true, completion: {
            })
        }
    }
}

extension TransactionViewController : UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 500
    }
    
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
}

extension TransactionViewController : UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell =  tableView
            .dequeueReusableCell(withType: GeneralTransactionInfoCell.self, for: indexPath)
        cell.configure(with: transaction)
        
        return cell
    }
    
}

extension TransactionViewController : WalletModelDelegate {

    func onReceivedTransactions(_ transactions: [BMTransaction]) {
        DispatchQueue.main.async {
            if let transaction = transactions.first(where: { $0.id == self.transaction.id }) {
                self.transaction = transaction
                
                UIView.performWithoutAnimation {
                    self.talbeView.reloadData()
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
