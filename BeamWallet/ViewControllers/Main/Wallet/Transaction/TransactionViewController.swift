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
    
    private var viewModel:DetailTransactionViewModel!
    
    init(transaction:BMTransaction) {
        super.init(nibName: nil, bundle: nil)

        viewModel = DetailTransactionViewModel(transaction: transaction)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError(Localizables.shared.strings.fatalInitCoderError)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        title = Localizables.shared.strings.transaction_details
        
        tableView.delegate = self
        tableView.dataSource = self
        
        tableView.register(GeneralInfoCell.self)
        tableView.register(WalletTransactionCell.self)
        tableView.register(TransactionPaymentProofCell.self)
        tableView.register(TransactionUTXOCell.self)
        
        tableView.addPullToRefresh(target: self, handler: #selector(refreshData(_:)))

        addRightButton(image: MoreIcon(), target: self, selector: #selector(self.onMore))

        subscribeToUpdates()
    }
    
    private func subscribeToUpdates() {
        viewModel.onDataChanged = { [weak self] in
            UIView.performWithoutAnimation {
                self?.tableView.stopRefreshing()
                self?.tableView.reloadData()
            }
        }
        
        viewModel.onDataUpdated = { [weak self]
            indexPath, transaction in
            AppModel.sharedManager().cancelTransaction(transaction)
            self?.back()
        }
        
        viewModel.onDataDeleted = { [weak self]
            indexPath, transaction in
            AppModel.sharedManager().prepareDeleteTransaction(transaction)
            self?.back()
        }
    }
    
    @objc private func refreshData(_ sender: Any) {
        AppModel.sharedManager().getWalletStatus()
    }
    
    @objc private func onMore(sender:UIBarButtonItem) {        
        BMPopoverMenu.show(menuArray: viewModel.actionItems(), done: { (selectedItem) in
            if let item = selectedItem {
                switch (item.action) {
                case .repeat_transaction:
                    self.viewModel.onRepeat(transaction: self.viewModel.transaction!)
                case .cancel_transaction :
                    self.viewModel.cancelTransation(indexPath: nil)
                case .delete_transaction :
                    self.viewModel.deleteTransation(indexPath: nil)
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
            return (viewModel.paymentProof != nil) ? BMTableHeaderTitleView.boldHeight : 0
        case 3:
            return (viewModel.utxos.count > 0 && !Settings.sharedManager().isHideAmounts) ? 60 : 0
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
            return viewModel.details.count
        case 2:
            return (viewModel.paymentProof != nil) ? 1 : 0
        case 3:
            return (Settings.sharedManager().isHideAmounts) ? 0 : viewModel.utxos.count
        default:
            return 0
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        switch indexPath.section {
        case 0:
            let cell = tableView
                .dequeueReusableCell(withType: WalletTransactionCell.self, for: indexPath)
                .configured(with: (row: indexPath.row, transaction: self.viewModel.transaction!, single:true, searchString:nil))
            return cell
        case 1:
            let cell = tableView
                .dequeueReusableCell(withType: GeneralInfoCell.self, for: indexPath)
                .configured(with: viewModel.details[indexPath.row])
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
            cell.configure(with: viewModel.utxos[indexPath.row])
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
            return BMTableHeaderTitleView(title: Localizables.shared.strings.general_info, bold: true)
        case 2:
            return (viewModel.paymentProof != nil) ? BMTableHeaderTitleView(title: Localizables.shared.strings.payment_proof, bold: true) : nil
        case 3:
            return (viewModel.utxos.count > 0 && !Settings.sharedManager().isHideAmounts) ? BMTableHeaderTitleView(title: Localizables.shared.strings.utxo_list, bold: true) : nil
        default:
            return nil
        }
    }
    
}

extension TransactionViewController: TransactionPaymentProofCellDelegate {
    
    func onPaymentProofDetails() {
        if let proof = viewModel.paymentProof {
            let vc = PaymentProofDetailViewController(transaction: self.viewModel.transaction!, paymentProof: proof)
            pushViewController(vc: vc)
        }
    }
    
    func onPaymentProofCopy() {
        if let code = viewModel.paymentProof?.code {
            UIPasteboard.general.string = code
            ShowCopied()
        }
    }
}

extension TransactionViewController : GeneralInfoCellDelegate {
    
    func onClickToCell(cell: UITableViewCell) {
        if let path = tableView.indexPath(for: cell) {
            if viewModel.details[path.row].text == Localizables.shared.strings.addDots(value: Localizables.shared.strings.kernel_id) {
                let kernelId = self.viewModel.transaction!.kernelId!
                let link = Settings.sharedManager().explorerAddress + kernelId
                if let url = URL(string: link) {
                    openUrl(url: url)
                }
            }
        }
    }
}
