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

class SettingsViewController: BaseViewController {
    
    class SettingsItem {
        enum Position {
            case one
            case midle
        }
        
        public var title:String?
        public var detail:String?
        public var isSwitch:Bool?
        public var id:Int!
        public var position:Position!

        init(title: String?, detail: String?, isSwitch: Bool?, id:Int, position:Position) {
            self.title = title
            self.detail = detail
            self.isSwitch = isSwitch
            self.id = id
            self.position = position
        }
    }
    

    @IBOutlet private weak var talbeView: UITableView!
    @IBOutlet private weak var versionLabel:UILabel!
    @IBOutlet private var headerView:UIView!
    @IBOutlet private var nodeTitleHeaderView:UIView!

    private var items = [[SettingsItem]]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.navigationItem.title = "Settings"
        
        versionLabel.text = UIApplication.version()
        
        var first = [SettingsItem]()
        first.append(SettingsItem(title: "ip:port:", detail: Settings.sharedManager().nodeAddress, isSwitch: nil, id: 5, position: .one))
        
        var second = [SettingsItem]()
        second.append(SettingsItem(title: "Ask for password on every Send", detail: nil, isSwitch: Settings.sharedManager().isNeedaskPasswordForSend, id: 3, position: .midle))
        
        if BiometricAuthorization.shared.canAuthenticate() {
            second.append(SettingsItem(title: BiometricAuthorization.shared.faceIDAvailable() ? "Enable Face ID" : "Enable Touch ID", detail: nil, isSwitch: Settings.sharedManager().isEnableBiometric, id: 4, position: .midle))
        }
        
        second.append(SettingsItem(title: "Change wallet password", detail: nil, isSwitch: nil, id: 1, position: .one))
        
        var three = [SettingsItem]()
        three.append(SettingsItem(title: "Report a problem", detail: nil, isSwitch: nil, id: 2, position: .one))

        items.append(first)
        items.append(second)
        items.append(three)
        
        talbeView.register(SettingsCell.self)
        talbeView.tableHeaderView = headerView
    }
}

extension SettingsViewController : UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 40
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        let item = items[indexPath.section][indexPath.row]
        
        switch item.id {
        case 2:
            self.onClickReport()
        case 1:
            let vc = UnlockPasswordViewController(event: .changePassword)
            vc.hidesBottomBarWhenPushed = true
            pushViewController(vc: vc)
        case 5:
            let vc = EnterNodeAddressViewController()
            vc.hidesBottomBarWhenPushed = true
            vc.completion = {
                obj in
                
                if obj == true {
                    self.items[0][0].detail = Settings.sharedManager().nodeAddress
                    self.talbeView.reloadData()
                }
            }
            pushViewController(vc: vc)
        default:
            return
        }
    }
    
}

extension SettingsViewController : UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        if section == 0 {
            return nodeTitleHeaderView
        }
        
        let view = UIView()
        view.backgroundColor = UIColor.clear
        return view
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return items.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return items[section].count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView
            .dequeueReusableCell(withType: SettingsCell.self, for: indexPath)
        cell.configure(with: items[indexPath.section][indexPath.row])
        cell.delegate = self
        
        
        return cell
    }
}

extension SettingsViewController : SettingsCellDelegate {
    
    func onClickSwitch(value: Bool, cell: SettingsCell) {
        if let indexPath = talbeView.indexPath(for: cell) {
            let item = items[indexPath.section][indexPath.row]
            item.isSwitch = value
            items[indexPath.section][indexPath.row] = item

            if value == false && item.id == 3 {
                let vc = UnlockPasswordViewController(event: .unlock)
                vc.hidesBottomBarWhenPushed = true
                vc.completion = {
                    obj in
                    
                    if obj == false {
                    
                        item.isSwitch = true
                        
                        self.talbeView.reloadData()
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
                        
                        self.talbeView.reloadData()
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
        }
    }
}

extension SettingsViewController {
    func onClickReport() {
        let path = AppModel.sharedManager().getZipLogs()
        let url = URL(fileURLWithPath: path)
        
        let act = ShareLogActivity()
        act.zipUrl = url
        
        let vc = UIActivityViewController(activityItems: [url], applicationActivities: [act])
        if (AppDelegate.CurrentTarget == .Test) {
            vc.setValue("beam wallet testnet logs", forKey: "subject")
        }
        else{
            vc.setValue("beam wallet logs", forKey: "subject")
        }
        
        vc.excludedActivityTypes = [UIActivity.ActivityType.postToFacebook, UIActivity.ActivityType.assignToContact, UIActivity.ActivityType.copyToPasteboard, UIActivity.ActivityType.print,UIActivity.ActivityType.openInIBooks]
        
        present(vc, animated: true)
    }
}
