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
    
    override var isUppercasedTitle: Bool {
        get{
            return true
        }
        set{
            super.isUppercasedTitle = true
        }
    }
    
    override var tableStyle: UITableView.Style {
        get {
            return .grouped
        }
        set {
            super.tableStyle = newValue
        }
    }
    
    init(transaction:BMTransaction) {
        super.init(nibName: nil, bundle: nil)

        viewModel = DetailTransactionViewModel(transaction: transaction)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError(Localizable.shared.strings.fatalInitCoderError)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        setGradientTopBar(mainColor: UIColor.main.peacockBlue, addedStatusView: true)
        
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register([BMMultiLinesCell.self, TransactionUTXOCell.self, TransactionDetailCell.self, TransactionPaymentProofCell.self])
        tableView.contentInsetAdjustmentBehavior = .never
        tableView.tableHeaderView = UIView(frame: CGRect(x: 0.0, y: 0.0, width: 0.0, height: 1))
        tableView.tableHeaderView?.backgroundColor = UIColor.main.marine
        tableView.backgroundColor = UIColor.main.marine
        
        tableView.addPullToRefresh(target: self, handler: #selector(refreshData(_:)))

        title = Localizable.shared.strings.transaction_id.uppercased().replacingOccurrences(of: Localizable.shared.strings.id.uppercased(), with: String.empty()).replacingOccurrences(of: " ", with: String.empty())

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
                    self.viewModel.repeatTransation(transaction: self.viewModel.transaction!)
                case .cancel_transaction :
                    self.viewModel.cancelTransation(indexPath: nil)
                case .delete_transaction :
                    self.viewModel.deleteTransation(indexPath: nil)
                case .share :
                    self.viewModel.share()
                default:
                    return
                }
            }
        }, cancel: {

        })
    }
    
    @objc private func onMoreDetails() {
        viewModel.detailsExpand = !viewModel.detailsExpand
        tableView.reloadSections(IndexSet(arrayLiteral: 1), with: .fade)
    }
    
    @objc private func onMoreUtxo() {
        viewModel.utxoExpand = !viewModel.utxoExpand
        tableView.reloadSections(IndexSet(arrayLiteral: 3), with: .fade)
    }
}

extension TransactionViewController : UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        switch section {
        case 1:
            return BMTableHeaderTitleView.height
        case 3:
            return (viewModel.utxos.count > 0 && !Settings.sharedManager().isHideAmounts) ? BMTableHeaderTitleView.height : 0
        default:
            return 0
        }
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
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
            return (viewModel.detailsExpand ? viewModel.details.count : 0)
        case 2:
            return (viewModel.paymentProof != nil) ? 1 : 0
        case 3:
            return (Settings.sharedManager().isHideAmounts) ? 0 : (viewModel.utxoExpand ? viewModel.utxos.count : 0)
        default:
            return 0
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        switch indexPath.section {
        case 0:
            let cell = tableView
                .dequeueReusableCell(withType: TransactionDetailCell.self, for: indexPath)
                .configured(with: self.viewModel.transaction!)
            return cell
        case 1:
            let cell = tableView
                .dequeueReusableCell(withType: BMMultiLinesCell.self, for: indexPath)
                .configured(with: viewModel.details[indexPath.row])
            cell.increaseSpace = true
            cell.delegate = self
            cell.contentView.backgroundColor = UIColor.white.withAlphaComponent(0.05)
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
            return BMTableHeaderTitleView(title: Localizable.shared.strings.details.uppercased(), handler: #selector(onMoreDetails), target: self, expand: viewModel.detailsExpand)
        case 3:
            return (viewModel.utxos.count > 0 && !Settings.sharedManager().isHideAmounts) ? BMTableHeaderTitleView(title: Localizable.shared.strings.utxo_list.uppercased(), handler: #selector(onMoreUtxo), target: self, expand: viewModel.utxoExpand) : nil
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
            if viewModel.details[path.row].title == Localizable.shared.strings.kernel_id.uppercased() {
                let kernelId = self.viewModel.transaction!.kernelId!
                let link = Settings.sharedManager().explorerAddress + kernelId
                if let url = URL(string: link) {
                    openUrl(url: url)
                }
            }
        }
    }
}
