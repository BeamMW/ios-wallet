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
    
    private var viewModel:DetailUTXOViewModel!
    
    override var tableStyle: UITableView.Style {
        get {
            return .grouped
        }
        set {
            super.tableStyle = newValue
        }
    }
    
  
    
    init(utxo:BMUTXO) {
        super.init(nibName: nil, bundle: nil)
        
        self.viewModel = DetailUTXOViewModel(utxo: utxo)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError(Localizable.shared.strings.fatalInitCoderError)
    }
    
    private let showTransactions = false
    
    override func viewDidLoad() {
        super.viewDidLoad()

        setGradientTopBar(mainColor: UIColor.main.peacockBlue, addedStatusView: true)

        tableView.delegate = self
        tableView.dataSource = self
        tableView.register([UTXODetailCell.self, UTXOTransactionCell.self, BMMultiLinesCell.self])
        tableView.contentInsetAdjustmentBehavior = .never
        tableView.tableHeaderView = UIView(frame: CGRect(x: 0.0, y: 0.0, width: 0.0, height: 1))
        tableView.tableHeaderView?.backgroundColor = UIColor.main.marine
        tableView.backgroundColor = UIColor.main.marine
        
        title = Localizable.shared.strings.utxo
        
        subscribeUpdates()
    }
    
    private func subscribeUpdates() {
        viewModel.onDataChanged = { [weak self] in
            UIView.performWithoutAnimation {
                self?.tableView.stopRefreshing()
                self?.tableView.reloadData()
            }
        }
    }
    
    @objc private func onMoreDetails() {
        viewModel.detailsExpand = !viewModel.detailsExpand
        tableView.reloadSections(IndexSet(arrayLiteral: 1), with: .fade)
    }
    
    @objc private func onMoreHistory() {
        viewModel.historyExpand = !viewModel.historyExpand
        tableView.reloadSections(IndexSet(arrayLiteral: 2), with: .fade)
    }
}

extension UTXODetailViewController : UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        switch section {
        case 0:
            return 15
        case 1:
            return 30
        default:
            return 0
        }
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        switch section {
        case 1, 2:
            return BMTableHeaderTitleView.height
        default:
            return 0
        }
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        if indexPath.section == 2 && viewModel.history.count > 0 {
            let vc = TransactionViewController(transaction: viewModel.history[indexPath.row])
            vc.hidesBottomBarWhenPushed = true
            pushViewController(vc: vc)
        }
    }
}

extension UTXODetailViewController : UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return (viewModel.history.count > 0 && showTransactions) ? 3 : 2
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0:
            return 1
        case 1:
            return (viewModel.detailsExpand ? viewModel.details.count : 0)
        case 2:
            return (viewModel.historyExpand ? viewModel.history.count : 0)
        default:
            return 0
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        switch indexPath.section {
        case 0:
            let cell = tableView
                .dequeueReusableCell(withType: UTXODetailCell.self, for: indexPath)
                .configured(with: viewModel.utxo)
            return cell
        case 1:
            let cell = tableView
                .dequeueReusableCell(withType: BMMultiLinesCell.self, for: indexPath)
                .configured(with: viewModel.details[indexPath.row])
            cell.increaseSpace = true
            cell.contentView.backgroundColor = UIColor.white.withAlphaComponent(0.05)
            return cell
        case 2:
            let cell = tableView
                .dequeueReusableCell(withType: UTXOTransactionCell.self, for: indexPath)
                .configured(with: (row: indexPath.row, transaction: viewModel.history[indexPath.row]))
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
           return BMTableHeaderTitleView(title: Localizable.shared.strings.details.uppercased(), handler: #selector(onMoreDetails), target: self, expand: viewModel.detailsExpand)
        case 2:
            return BMTableHeaderTitleView(title: Localizable.shared.strings.transaction_history.uppercased(), handler: #selector(onMoreHistory), target: self, expand: viewModel.historyExpand)
        default:
            return nil
        }
    }
    
    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        let view =  UIView()
        view.backgroundColor = UIColor.clear
        return view
    }
}

