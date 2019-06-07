//
// WalletViewController.swift
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

class SettingsViewController: BaseTableViewController {
    
    @IBOutlet private weak var versionLabel:UILabel!
    @IBOutlet private var versionView:UIView!

    private var viewModel:SettingsViewModel!
    
    override var tableStyle: UITableView.Style {
        get {
            return .grouped
        }
        set {
            super.tableStyle = newValue
        }
    }
    
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
        
        title = LocalizableStrings.settings
        
        viewModel = SettingsViewModel()
        viewModel.needReloadTable = {
            self.tableView.reloadData()
        }
        
        versionLabel.text = UIApplication.version()
        
        tableView.register(SettingsCell.self)
        tableView.separatorColor = UIColor.white.withAlphaComponent(0.1)
        tableView.separatorStyle = .singleLine
        tableView.tableHeaderView = BMNetworkStatusView()
        tableView.tableFooterView = versionView
        tableView.dataSource = self
        tableView.delegate = self
        
        onAddMenuIcon()
    }
}

extension SettingsViewController : UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        
        return UITableView.automaticDimension
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        
        if section == 0 {
            return BMTableHeaderTitleView.height
        }
        else if section == 4 {
            return BMTableHeaderTitleView.height
        }
        else if section == 5 && AppModel.sharedManager().categories.count > 0 {
            return 10
        }
        
        return 20
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        tableView.deselectRow(at: indexPath, animated: true)
        
        let item = viewModel.getItem(indexPath: indexPath)
        
        if item.category != nil {
            let vc = CategoryDetailViewController(category: item.category!)
            vc.hidesBottomBarWhenPushed = true
            self.pushViewController(vc: vc)
        }
        else{
            switch item.id {
            case 2:
                self.viewModel.onClickReport(controller: self)
            case 1:
                self.viewModel.onChangePassword(controller: self)
            case 5:
                self.viewModel.onChangeNode(controller: self) { (_) in
                    self.tableView.reloadData()
                }
            case 6:
                self.viewModel.onClearData(controller: self)
            case 7:
                let vc = QRScannerViewController()
                vc.delegate = self
                vc.isBotScanner = true
                vc.hidesBottomBarWhenPushed = true
                self.pushViewController(vc: vc)
            case 8:
                self.viewModel.onOpenTgBot()
            case 10:
                self.viewModel.onCategory(controller: self, category: nil)
            case 11:
                self.showRateDialog()
            case 12:
                let vc = OwnerKeyUnlockViewController()
                vc.hidesBottomBarWhenPushed = true
                self.pushViewController(vc: vc)
            default:
                return
            }
        }
    }
    
}

extension SettingsViewController : UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        
        if section == 0 {
            return BMTableHeaderTitleView(title: "node", bold: false)
        }
        else if section == 4 {
            return BMTableHeaderTitleView(title: "categories", bold: false)
        }
        
        let view = UIView()
        view.backgroundColor = UIColor.clear
        return view
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        
        return viewModel.items.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        return viewModel.items[section].count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView
            .dequeueReusableCell(withType: SettingsCell.self, for: indexPath)
        cell.configure(with: viewModel.getItem(indexPath: indexPath))
        cell.delegate = self
        
        return cell
    }
}

extension SettingsViewController : SettingsCellDelegate {
    
    func onClickSwitch(value: Bool, cell: SettingsCell) {
        
        if let indexPath = tableView.indexPath(for: cell) {
           // viewModel.onSwitch(controller: self, indexPath: indexPath)
            
            let item = viewModel.getItem(indexPath: indexPath)
            item.isSwitch = value
            viewModel.items[indexPath.section][indexPath.row] = item

            if value == false && item.id == 3 {
                let vc = UnlockPasswordViewController(event: .unlock)
                vc.hidesBottomBarWhenPushed = true
                vc.completion = {
                    obj in
                    
                    if obj == false {
                    
                        item.isSwitch = true
                        
                        self.tableView.reloadData()
                    }
                    else{
                        Settings.sharedManager().isNeedaskPasswordForSend = false
                    }
                }
                pushViewController(vc: vc)
            }
            else if value == true && item.id == 3 {
                Settings.sharedManager().isNeedaskPasswordForSend = true
            }
            else if value == false && item.id == 4 {
                let vc = UnlockPasswordViewController(event: .unlock)
                vc.hidesBottomBarWhenPushed = true
                vc.completion = {
                    obj in
                    
                    if obj == false {
                        
                        item.isSwitch = true
                        
                        self.tableView.reloadData()
                    }
                    else{
                        Settings.sharedManager().isEnableBiometric = false
                    }
                }
                pushViewController(vc: vc)
            }
            else if value == true && item.id == 4 {
                Settings.sharedManager().isEnableBiometric = true
            }
            else if item.id == 9 {
                Settings.sharedManager().isAllowOpenLink = value
            }
        }
    }
}

extension SettingsViewController : QRScannerViewControllerDelegate {
   
    func didScanQRCode(value:String, amount:String?) {
        if TGBotManager.sharedManager.isValidUserFromJson(value: value) {
            TGBotManager.sharedManager.startLinking { (_ ) in
                
            }
        }
    }
}
