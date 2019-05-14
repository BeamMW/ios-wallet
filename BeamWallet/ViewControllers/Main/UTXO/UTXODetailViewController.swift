//
// UTXODetailViewController.swift
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

class UTXODetailViewController: BaseTableViewController {

    private var details = [GeneralInfo]()
    private var history = [BMTransaction]()

    private var utxo:BMUTXO!
    
    init(utxo:BMUTXO) {
        super.init(nibName: nil, bundle: nil)
        
        self.utxo = utxo
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError(LocalizableStrings.fatalInitCoderError)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        tableView.delegate = self
        tableView.dataSource = self
        
        tableView.register([UTXODetailCell.self, GeneralInfoCell.self, UTXOTransactionCell.self])
        
        fillDetailInfo()

        title = LocalizableStrings.utxo_details
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        AppModel.sharedManager().addDelegate(self)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        AppModel.sharedManager().removeDelegate(self)
    }
    
    private func fillDetailInfo() {
        history = AppModel.sharedManager().getTransactionsFrom(utxo) as! [BMTransaction]
        
        details.removeAll()
        
        if let kernel = history.first?.kernelId {
            details.append(GeneralInfo(text: LocalizableStrings.kernel_id, detail: kernel, failed: false, canCopy:true, color: UIColor.white))
        }
        
        details.append(GeneralInfo(text: LocalizableStrings.utxo_type, detail: utxo.typeString, failed: false, canCopy:false, color: UIColor.white))
    }
}

extension UTXODetailViewController : UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        switch section {
        case 0:
            return 0
        case 1:
            return BMTableHeaderTitleView.boldHeight
        case 2:
            return UTXOTransactionsHeaderView.height
        default:
            return 0
        }
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return indexPath.section == 0 ? UTXODetailCell.height() : UITableView.automaticDimension
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
}

extension UTXODetailViewController : UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return (history.count > 0) ? 3 : 2
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0:
            return 1
        case 1:
            return details.count
        case 2:
            return history.count
        default:
            return 0
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        switch indexPath.section {
        case 0:
            let cell = tableView
                .dequeueReusableCell(withType: UTXODetailCell.self, for: indexPath)
                .configured(with: (row: indexPath.row, utxo: utxo))
            return cell
        case 1:
            let cell = tableView
                .dequeueReusableCell(withType: GeneralInfoCell.self, for: indexPath)
                .configured(with: details[indexPath.row])
            return cell
        case 2:
            let cell = tableView
                .dequeueReusableCell(withType: UTXOTransactionCell.self, for: indexPath)
                .configured(with: history[indexPath.row])
            return cell
        default:
            return BaseCell()
        }
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
       
        switch section {
        case 0:
            return nil
        case 1:
            return BMTableHeaderTitleView(title: LocalizableStrings.utxo_details, bold: true)
        case 2:
            return UTXOTransactionsHeaderView().loadNib()
        default:
            return nil
        }
    }
}

extension UTXODetailViewController : WalletModelDelegate {
    func onReceivedTransactions(_ transactions: [BMTransaction]) {
        DispatchQueue.main.async {
            self.fillDetailInfo()
            
            UIView.performWithoutAnimation {
                self.tableView.stopRefreshing()
                self.tableView.reloadData()
            }
        }
    }
    
    func onReceivedUTXOs(_ utxos: [BMUTXO]) {
        DispatchQueue.main.async {
            if let utxo = utxos.first(where: { $0.id == self.utxo.id }) {
                self.utxo = utxo
                self.fillDetailInfo()
                
                UIView.performWithoutAnimation {
                    self.tableView.stopRefreshing()
                    self.tableView.reloadData()
                }
            }
        }
    }
}

