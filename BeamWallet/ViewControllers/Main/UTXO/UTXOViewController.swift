//
// UTXOViewController.swift
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

class UTXOViewController: BaseTableViewController {
    
    private let viewModel = UTXOViewModel(selected: .active)
    
    private var headerView: UTXOSegmentView!
    private let hideUTXOView = UTXOSecurityView().loadNib()

    override var isUppercasedTitle: Bool {
        get{
            return true
        }
        set{
            super.isUppercasedTitle = true
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        title = Localizable.shared.strings.utxo
                
        tableView.delegate = self
        tableView.dataSource = self
        tableView.tableHeaderView = BMNetworkStatusView()
        tableView.register([UTXOCell.self, UTXOBlockCell.self])
        tableView.addPullToRefresh(target: self, handler: #selector(refreshData(_:)))
        tableView.isUserInteractionEnabled = !Settings.sharedManager().isHideAmounts

        headerView = UTXOSegmentView { [weak self] (selected)  in
            self?.viewModel.selectedState = UTXOViewModel.UTXOSelectedState(rawValue: selected) ?? .active
        }

        hideUTXOView.isHidden = !Settings.sharedManager().isHideAmounts
        view.addSubview(hideUTXOView)

        Settings.sharedManager().addDelegate(self)

        rightButton()
        onAddMenuIcon()
        
        subscribeUpdates()
    }
    
    deinit {
        Settings.sharedManager().removeDelegate(self)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        hideUTXOView.frame = CGRect(x: 0, y: tableView.frame.origin.y+30, width: tableView.frame.size.width, height: tableView.frame.size.height-30)
    }
    
    private func subscribeUpdates() {
        viewModel.onDataChanged = { [weak self] in
            UIView.performWithoutAnimation {
                self?.tableView.stopRefreshing()
                self?.tableView.reloadData()
            }
        }
        
        viewModel.onStatusChanged = { [weak self] in
            self?.tableView.stopRefreshing()
            
            if let cell = self?.tableView.findCell(UTXOBlockCell.self) as? UTXOBlockCell {
                cell.configure(with: AppModel.sharedManager().walletStatus)
            }
            else{
                UIView.performWithoutAnimation {
                    self?.tableView.reloadData()
                }
            }
        }
    }
    
    private func rightButton() {
        addRightButton(image: Settings.sharedManager().isHideAmounts ? IconShowBalance() : IconHideBalance(), target: self, selector: #selector(onHideAmounts))
    }
    
    @objc private func refreshData(_ sender: Any) {
        AppModel.sharedManager().getWalletStatus()
        AppModel.sharedManager().getUTXO()
    }
}

extension UTXOViewController : UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        switch section {
        case 1:
            return UTXOSegmentView.height
        default:
            return 0
        }
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        switch indexPath.section {
        case 0:
            return UTXOBlockCell.mainHeight()
        case 1:
            return UTXOCell.height()
        default:
            return 0
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        if indexPath.section == 1 {
            let vc = UTXODetailViewController(utxo: viewModel.utxos[indexPath.row])
            vc.hidesBottomBarWhenPushed = true
            self.pushViewController(vc: vc)
        }
    }
}

extension UTXOViewController : UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0:
            return 1
        case 1:
            return viewModel.utxos.count
        default:
            return 0
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        switch indexPath.section {
        case 0:
            let cell = tableView
                .dequeueReusableCell(withType: UTXOBlockCell.self, for: indexPath)
            cell.configure(with: AppModel.sharedManager().walletStatus)
            return cell
        case 1:
            let cell = tableView
                .dequeueReusableCell(withType: UTXOCell.self, for: indexPath)
                .configured(with: (row: indexPath.row, utxo: viewModel.utxos[indexPath.row]))
            return cell
        default:
            return BaseCell()
        }
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        switch section {
        case 1:
            return headerView
        default:
            return nil
        }
    }
}

extension UTXOViewController : SettingsModelDelegate {
    func onChangeHideAmounts() {
        rightButton()
        
        hideUTXOView.isHidden = !Settings.sharedManager().isHideAmounts
        tableView.isUserInteractionEnabled = !Settings.sharedManager().isHideAmounts
    }
}
