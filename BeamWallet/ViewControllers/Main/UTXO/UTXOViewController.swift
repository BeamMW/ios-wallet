//
//  UTXOViewController.swift
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

class UTXOViewController: BaseViewController {
    enum UTXOSelectedState: Int {
        case active
        case all
    }
    
    private var selectedState: UTXOSelectedState = .active
    private var utxos = [BMUTXO]()
    private var expandBlock = true

    @IBOutlet private weak var tableView: UITableView!
    @IBOutlet private var headerView: UIView!
    @IBOutlet private var networkHeaderView: UIView!
    @IBOutlet private var hideUTXOView: UIView!

    override func viewDidLoad() {
        super.viewDidLoad()

        self.title = "UTXO"
        
        tableView.tableHeaderView = networkHeaderView

        tableView.register(UTXOCell.self)
        tableView.register(UTXOBlockCell.self)
        tableView.addPullToRefresh(target: self, handler: #selector(refreshData(_:)))

        hideUTXOView.isHidden = !Settings.sharedManager().isHideAmounts

        filterUTXOS()
        
        AppModel.sharedManager().addDelegate(self)
        Settings.sharedManager().addDelegate(self)
        
        rightButton()
    }
    
    private func rightButton() {
        let icon = Settings.sharedManager().isHideAmounts ? UIImage(named: "iconShowBalance") : UIImage(named: "iconHideBalance")
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(image: icon, style: .plain, target: self, action: #selector(onHideAmounts))
    }
    
    @objc private func refreshData(_ sender: Any) {
        AppModel.sharedManager().getWalletStatus()
        AppModel.sharedManager().getUTXO()
    }
    
    private func filterUTXOS() {
        if selectedState == .all {
            if let utox = AppModel.sharedManager().utxos {
                self.utxos = utox as! [BMUTXO]
            }
        }
        else{
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
                let alert = UIAlertController(title: "Activate security mode", message: "All the balances will be hidden until this icon is tapped again", preferredStyle: .alert)
                
                alert.addAction(UIAlertAction(title: "Cancel", style: .default, handler:{ (UIAlertAction)in
                }))
                
                alert.addAction(UIAlertAction(title: "Activate", style: .default, handler:{ (UIAlertAction)in
                    
                    Settings.sharedManager().isAskForHideAmounts = false
                    Settings.sharedManager().isHideAmounts = !Settings.sharedManager().isHideAmounts
                }))
                
                self.present(alert, animated: true)
            }
            else{
                Settings.sharedManager().isHideAmounts = !Settings.sharedManager().isHideAmounts
            }
        }
        else{
            Settings.sharedManager().isHideAmounts = !Settings.sharedManager().isHideAmounts
        }
    }
    
    @IBAction func onStatus(sender : UISegmentedControl) {
        selectedState = UTXOViewController.UTXOSelectedState(rawValue: sender.selectedSegmentIndex) ?? .active
        
        switch selectedState {
        case .active:
            onClickActive()
        case .all:
            onClickAll()
        }
    }
}

extension UTXOViewController : UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        if section == 1 {
            return 55
        }
        
        return 0
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if indexPath.row == 0 && indexPath.section == 0{
            return expandBlock ? 123 : 70
        }
        return 60
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
        if section == 0 {
            return 1
        }
        return utxos.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        if indexPath.section == 0 {
            let cell = tableView
                .dequeueReusableCell(withType: UTXOBlockCell.self, for: indexPath)
            cell.configure(with: (status: AppModel.sharedManager().walletStatus, expand: expandBlock))
            cell.delegate = self
            return cell
        }
        else{
            let cell = tableView
                .dequeueReusableCell(withType: UTXOCell.self, for: indexPath)
                .configured(with: (row: indexPath.row, utxo: utxos[indexPath.row]))
            return cell
        }
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        if section == 0 {
            return nil
        }
        
        return headerView
    }
}

extension UTXOViewController : UTXOBlockCellDelegate {
    func onClickAll() {
        selectedState = .all
        
        filterUTXOS()

        tableView.reloadData()
        tableView.setContentOffset(CGPoint(x: 0, y: 0), animated: false)
    }
    
    func onClickActive() {
        selectedState = .active
        
        filterUTXOS()

        tableView.reloadData()
        tableView.setContentOffset(CGPoint(x: 0, y: 0), animated: false)
    }
    
    func onClickExpand() {
        expandBlock = !expandBlock
        
        self.tableView.reloadRows(at: [IndexPath(row: 0, section: 0)], with: .fade)
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
                if let utox = AppModel.sharedManager().utxos {
                    self.utxos = utox as! [BMUTXO]
                    
                    if self.selectedState == .active {
                        self.utxos = self.utxos.filter { $0.status == 1 || $0.status == 2 }
                    }
                }
                
                self.utxos = self.utxos.sorted(by: { $0.id < $1.id })
                
                UIView.performWithoutAnimation {
                    self.tableView.reloadData()
                }
            }
        }
    }
    
    func onWalletStatusChange(_ status: BMWalletStatus) {
        DispatchQueue.main.async {
            self.tableView.stopRefreshing()

            if let cell = self.tableView.cellForRow(at: IndexPath(row: 0, section: 0)) as? UTXOBlockCell
            {
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
    }
}


