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
    
    private let viewModel = SettingsViewModel()
    
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
        
        setGradientTopBar(mainColor: UIColor.main.peacockBlue, addedStatusView: true)
        
        title = Localizable.shared.strings.settings
        
        viewModel.onDataChanged = { [weak self] in
            self?.tableView.reloadData()
        }
                
        tableView.register(SettingsCell.self)
        tableView.separatorColor = UIColor.white.withAlphaComponent(0.13)
        tableView.separatorStyle = .singleLine
        tableView.tableFooterView = versionView()
        tableView.dataSource = self
        tableView.delegate = self
        tableView.contentInsetAdjustmentBehavior = .never
        tableView.tableHeaderView = UIView(frame: CGRect(x: 0.0, y: 0.0, width: 0.0, height: 1))
        tableView.tableHeaderView?.backgroundColor = UIColor.main.marine
        tableView.backgroundColor = UIColor.main.marine
        
        Settings.sharedManager().addDelegate(self)        
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        tableView.frame = CGRect(x: 0, y: tableView.y - 5, width: self.view.bounds.width, height: tableView.h + 10)
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        
        if isMovingFromParent {
            Settings.sharedManager().removeDelegate(self)
        }
    }
    
    private func versionView() -> UIView {
        let view = UIView(frame: CGRect(x: 0, y: 0, width: UIScreen.main.bounds.size.width, height: 70))
        view.backgroundColor = UIColor.clear
        
        let v = UIApplication.appVersion()
        let string = Localizable.shared.strings.version + ": " + v
        
        let range = (string as NSString).range(of: String(v))

        let attributedText = NSMutableAttributedString(string: string)
        attributedText.addAttribute(NSAttributedString.Key.font, value: BoldFont(size: 14) , range: range)

        let label = UILabel(frame: CGRect(x: 0, y: 5, width: UIScreen.main.bounds.size.width, height: 20))
        label.textAlignment = .center
        label.font = RegularFont(size: 14)
        label.textColor = UIColor.main.blueyGrey
        label.attributedText = attributedText
        view.addSubview(label)
        
        return view
    }
}

extension SettingsViewController : UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return BMTableHeaderTitleView.height
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        let item = viewModel.getItem(indexPath: indexPath)
        
        if item.category != nil {
          self.viewModel.openCategory(category: item.category)
        }
        else{
            switch item.id {
            case 2:
                self.viewModel.onClickReport()
            case 1:
                self.viewModel.onChangePassword(controller: self)
            case 5:
                self.viewModel.onChangeNode() { [weak self] (_)  in
                    self?.tableView.reloadData()
                }
            case 6:
                self.viewModel.onClearData()
            case 7:
               self.viewModel.openQRScanner(delegate: self)
            case 8:
                self.viewModel.onOpenTgBot()
            case 10:
                self.viewModel.openCategory(category: nil)
            case 11:
                self.showRateDialog()
            case 12:
                self.viewModel.showOwnerKey()
            case 13:
                self.viewModel.onLanguage()
            case 15:
                self.viewModel.onLockScreen()
            default:
                return
            }
        }
    }
    
}

extension SettingsViewController : UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        switch section {
        case 0:
            return BMTableHeaderTitleView(title: Localizable.shared.strings.node, bold: false)
        case 1:
            return BMTableHeaderTitleView(title: Localizable.shared.strings.general_settings, bold: false)
        case 2:
            return BMTableHeaderTitleView(title: Localizable.shared.strings.categories, bold: false)
        case 3:
            return BMTableHeaderTitleView(title: Localizable.shared.strings.feedback, bold: false)
        default:
            return nil
        }
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
            
            let item = viewModel.getItem(indexPath: indexPath)
            item.isSwitch = value
            viewModel.items[indexPath.section][indexPath.row] = item

            if value == false && item.id == 3 {
                let vc = UnlockPasswordViewController(event: .unlock)
                vc.hidesBottomBarWhenPushed = true
                vc.completion = { [weak self]
                    obj in
                    
                    if obj == false {
                    
                        item.isSwitch = true
                        
                        self?.tableView.reloadData()
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
            else if item.id == 14 {
                Settings.sharedManager().connectToRandomNode = value
                
                if(value)
                {
                    Settings.sharedManager().nodeAddress = AppModel.chooseRandomNode();
                    AppModel.sharedManager().changeNodeAddress()
                    
                    viewModel.items[0][1].detail = Settings.sharedManager().nodeAddress
                }
                else if Settings.sharedManager().customNode().isEmpty == false {
                    Settings.sharedManager().nodeAddress = Settings.sharedManager().customNode();
                    AppModel.sharedManager().changeNodeAddress()
                    
                    viewModel.items[0][1].detail = Settings.sharedManager().nodeAddress
                }
                
                tableView.reloadRows(at: [IndexPath(row: 1, section: 0)], with: .fade)
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

extension SettingsViewController : SettingsModelDelegate {
    
    func onChangeLanguage() {
        setGradientTopBar(mainColor: UIColor.main.peacockBlue, addedStatusView: true, menu: true)
        title = Localizable.shared.strings.settings
        tableView.tableFooterView = versionView()
    }
}
