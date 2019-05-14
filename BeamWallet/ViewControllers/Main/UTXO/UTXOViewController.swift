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
    
    enum UTXOSelectedState: Int {
        case active = 0
        case all = 1
    }
    
    private var selectedState: UTXOSelectedState = .active
    private var utxos = [BMUTXO]()
    private var expandBlock = true

    private var headerView: UTXOSegmentView!
    private lazy var hideUTXOView = UTXOSecurityView().loadNib()

    override func viewDidLoad() {
        super.viewDidLoad()

        self.title = LocalizableStrings.utxo
        
        tableView.delegate = self
        tableView.dataSource = self
        
        headerView = UTXOSegmentView { (selected) in
            self.selectedState = UTXOSelectedState(rawValue: selected) ?? .active
            
            self.filterUTXOS()
            
            self.tableView.reloadData()
            self.tableView.scrollToTop()
        }
        
        tableView.tableHeaderView = BMNetworkStatusView()

        tableView.register([UTXOCell.self, UTXOBlockCell.self])
        
        tableView.addPullToRefresh(target: self, handler: #selector(refreshData(_:)))

        hideUTXOView.isHidden = !Settings.sharedManager().isHideAmounts
        tableView.isUserInteractionEnabled = !Settings.sharedManager().isHideAmounts
        
        AppModel.sharedManager().addDelegate(self)
        Settings.sharedManager().addDelegate(self)

        filterUTXOS()

        rightButton()
        
        self.view.addSubview(hideUTXOView)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        hideUTXOView.frame = CGRect(x: 0, y: 30, width: tableView.frame.size.width, height: tableView.frame.size.height-30)
    }
    
    private func rightButton() {
        let icon = Settings.sharedManager().isHideAmounts ? IconShowBalance() : IconHideBalance()
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(image: icon, style: .plain, target: self, action: #selector(onHideAmounts))
    }
    
    @objc private func refreshData(_ sender: Any) {
        AppModel.sharedManager().getWalletStatus()
        AppModel.sharedManager().getUTXO()
    }
    
    private func filterUTXOS() {
        switch selectedState {
        case .all:
            if let utox = AppModel.sharedManager().utxos {
                self.utxos = utox as! [BMUTXO]
            }
        case .active:
            if let utxos = AppModel.sharedManager().utxos {
                self.utxos = utxos as! [BMUTXO]
                self.utxos = self.utxos.filter { $0.status == 1 || $0.status == 2 }
            }
        }
        self.utxos = self.utxos.sorted(by: { $0.id < $1.id })
    }
    
    @objc private func onHideAmounts() {
        if !Settings.sharedManager().isHideAmounts {
            if Settings.sharedManager().isAskForHideAmounts {
                
                self.confirmAlert(title: LocalizableStrings.activate_security_title, message: LocalizableStrings.activate_security_text, cancelTitle: LocalizableStrings.cancel, confirmTitle: LocalizableStrings.activate, cancelHandler: { (_ ) in
                    
                }) { (_ ) in
                    Settings.sharedManager().isAskForHideAmounts = false
                    Settings.sharedManager().isHideAmounts = !Settings.sharedManager().isHideAmounts
                }
            }
            else{
                Settings.sharedManager().isHideAmounts = !Settings.sharedManager().isHideAmounts
            }
        }
        else{
            Settings.sharedManager().isHideAmounts = !Settings.sharedManager().isHideAmounts
        }
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
            return expandBlock ? UTXOBlockCell.mainHeight() : UTXOBlockCell.hideHeight()
        case 1:
            return UTXOCell.height()
        default:
            return 0
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        if indexPath.section == 1 {
            let vc = UTXODetailViewController(utxo: utxos[indexPath.row])
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
            return utxos.count
        default:
            return 0
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        switch indexPath.section {
        case 0:
            let cell = tableView
                .dequeueReusableCell(withType: UTXOBlockCell.self, for: indexPath)
            cell.configure(with: (status: AppModel.sharedManager().walletStatus, expand: expandBlock))
            cell.delegate = self
            return cell
        case 1:
            let cell = tableView
                .dequeueReusableCell(withType: UTXOCell.self, for: indexPath)
                .configured(with: (row: indexPath.row, utxo: utxos[indexPath.row]))
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

extension UTXOViewController : UTXOBlockCellDelegate {
    func onClickExpand() {
        expandBlock = !expandBlock
        
        UIView.performWithoutAnimation {
            self.tableView.reloadRow(UTXOBlockCell.self)
        }
    }
}

extension UTXOViewController : WalletModelDelegate {
    func onReceivedUTXOs(_ utxos: [BMUTXO]) {
        DispatchQueue.main.async {

            self.tableView.stopRefreshing()

            if Settings.sharedManager().isLocalNode {
                if let utox = AppModel.sharedManager().utxos {
                    var _utxos = utox as! [BMUTXO]
                    
                    if self.selectedState == .active {
                        _utxos = _utxos.filter { $0.status == 1 || $0.status == 2 }
                    }
                    
                    if _utxos.count > self.utxos.count {
                        let diff = _utxos.count - self.utxos.count
                        
                        if diff >= 200 {
                            var rows = [IndexPath]()
                            
                            for i in 0...diff-1 {
                                rows.append(IndexPath(row: self.utxos.count+i, section: 1))
                            }
                            
                            self.utxos = _utxos
                            
                            UIView.performWithoutAnimation {
                                self.tableView.beginUpdates()
                                self.tableView.insertRows(at: rows, with: .none)
                                self.tableView.endUpdates()
                            }
                        }              
                    }
                    else{
                        self.utxos = _utxos
                        
                        UIView.performWithoutAnimation {
                            self.tableView.reloadData()
                        }
                    }
                }
            }
            else{
                self.filterUTXOS()
                
                UIView.performWithoutAnimation {
                    self.tableView.reloadData()
                }
            }
        }
    }
    
    func onWalletStatusChange(_ status: BMWalletStatus) {
        DispatchQueue.main.async {
            self.tableView.stopRefreshing()

            if let cell = self.tableView.findCell(UTXOBlockCell.self) as? UTXOBlockCell {
                cell.configure(with: (status: AppModel.sharedManager().walletStatus, expand: self.expandBlock))
            }
            else{
                UIView.performWithoutAnimation {
                    self.tableView.reloadData()
                }
            }
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
