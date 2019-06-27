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
    
    init(utxo:BMUTXO) {
        super.init(nibName: nil, bundle: nil)
        
        self.viewModel = DetailUTXOViewModel(utxo: utxo)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError(Localizable.shared.strings.fatalInitCoderError)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        tableView.delegate = self
        tableView.dataSource = self
        tableView.register([UTXODetailCell.self, GeneralInfoCell.self, UTXOTransactionCell.self])
        
        title = Localizable.shared.strings.utxo_details
        
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
        return (viewModel.history.count > 0) ? 3 : 2
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0:
            return 1
        case 1:
            return viewModel.details.count
        case 2:
            return viewModel.history.count
        default:
            return 0
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        switch indexPath.section {
        case 0:
            let cell = tableView
                .dequeueReusableCell(withType: UTXODetailCell.self, for: indexPath)
                .configured(with: (row: indexPath.row, utxo: viewModel.utxo))
            return cell
        case 1:
            let cell = tableView
                .dequeueReusableCell(withType: GeneralInfoCell.self, for: indexPath)
                .configured(with: viewModel.details[indexPath.row])
            cell.delegate = self
            return cell
        case 2:
            let cell = tableView
                .dequeueReusableCell(withType: UTXOTransactionCell.self, for: indexPath)
                .configured(with: viewModel.history[indexPath.row])
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
            return BMTableHeaderTitleView(title: Localizable.shared.strings.utxo_details, bold: true)
        case 2:
            return UTXOTransactionsHeaderView().loadNib()
        default:
            return nil
        }
    }
}

extension UTXODetailViewController : GeneralInfoCellDelegate {
    func onClickToCell(cell: UITableViewCell) {
        if let path = tableView.indexPath(for: cell)
        {
            if viewModel.details[path.row].text == Localizable.shared.strings.addDots(value: Localizable.shared.strings.kernel_id) {
                let kernelId = viewModel.details[path.row].detail!
                let link = Settings.sharedManager().explorerAddress + kernelId
                if let url = URL(string: link) {
                    openUrl(url: url)
                }
            }
        }
    }
}

