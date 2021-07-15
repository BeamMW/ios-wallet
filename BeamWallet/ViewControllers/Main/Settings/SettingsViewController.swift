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
    
    private var viewModel:SettingsViewModel!
    private var type:SettingsViewModel.SettingsType!
    
    init(type:SettingsViewModel.SettingsType) {
        super.init(nibName: nil, bundle: nil)
        self.type = type
        self.viewModel = SettingsViewModel(type: type)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError(Localizable.shared.strings.fatalInitCoderError)
    }
    
    override var tableStyle: UITableView.Style {
        get { return .grouped }
        set { super.tableStyle = newValue }
    }  
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setGradientTopBar(mainColor: UIColor.main.peacockBlue, addedStatusView: true)
        
        title = viewModel.title()
        
        if(self.type == .node) {
            statusView.changeButton.removeFromSuperview()
        }
        
        viewModel.onDataChanged = { [weak self] in
            self?.tableView.reloadData()
        }
                
        tableView.register(SettingsCell.self)
        tableView.separatorColor = UIColor.white.withAlphaComponent(0.13)
        tableView.separatorStyle = .singleLine
        tableView.dataSource = self
        tableView.delegate = self
        tableView.contentInsetAdjustmentBehavior = .never
        tableView.tableHeaderView = UIView(frame: CGRect(x: 0.0, y: 0.0, width: 0.0, height: 20))
        tableView.tableHeaderView?.backgroundColor = UIColor.main.marine
        tableView.backgroundColor = UIColor.main.marine
        
        if type == .main {
            tableView.tableFooterView = versionView()
        }
        
        AppModel.sharedManager().addDelegate(self)
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
            AppModel.sharedManager().removeDelegate(self)
        }
    }
    
    private func versionView() -> UIView {
        let view = UIView(frame: CGRect(x: 0, y: 0, width: UIScreen.main.bounds.size.width, height: 70))
        view.backgroundColor = UIColor.clear
        
        let v = UIApplication.appVersion()
        let string = "v " + v
    
        let label = UILabel(frame: CGRect(x: 0, y: 5, width: UIScreen.main.bounds.size.width, height: 20))
        label.textAlignment = .center
        label.font = BoldFont(size: 14)
        label.textColor = UIColor.main.blueyGrey
        label.text = string
        view.addSubview(label)
        
        return view
    }
}

extension SettingsViewController : UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        let item = viewModel.getItem(indexPath: indexPath)
        if let isSwitch = item.isSwitch, let cell = tableView.cellForRow(at: indexPath) as? SettingsCell {
            onClickSwitch(value: !isSwitch, cell: cell)
            tableView.reloadData()
        }
        else {
            viewModel.didSelectItem(item: viewModel.getItem(indexPath: indexPath))
        }
    }
}

extension SettingsViewController : UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return viewModel.items.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.items[section].count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let item = viewModel.getItem(indexPath: indexPath)
        
        let cell = tableView
            .dequeueReusableCell(withType: SettingsCell.self, for: indexPath)
        cell.configure(with: item)
        cell.delegate = self
        
        if item.type == .blockchain {
            cell.isUserInteractionEnabled = false
        }
        else {
            cell.isUserInteractionEnabled = true
        }
        
        return cell
    }
}

extension SettingsViewController : SettingsCellDelegate {
    
    func onClickSwitch(value: Bool, cell: SettingsCell) {
        if let indexPath = tableView.indexPath(for: cell) {
            
            let item = viewModel.getItem(indexPath: indexPath)
            item.isSwitch = value
            viewModel.items[indexPath.section][indexPath.row] = item

            if value == false && item.type == .ask_password {
                let vc = UnlockPasswordPopover(event: .settings)
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
                vc.modalPresentationStyle = .overFullScreen
                vc.modalTransitionStyle = .crossDissolve
                present(vc, animated: true, completion: nil)
            }
            else if value == true && item.type == .ask_password {
                Settings.sharedManager().isNeedaskPasswordForSend = true
            }
            else if value == false && item.type == .enable_bio {
                let vc = UnlockPasswordPopover(event: .settings, allowBiometric: false)
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
                vc.modalPresentationStyle = .overFullScreen
                vc.modalTransitionStyle = .crossDissolve
                present(vc, animated: true, completion: nil)
            }
            else if value == true && item.type == .enable_bio {
                Settings.sharedManager().isEnableBiometric = true
            }
            else if item.type == .allow_open_link {
                Settings.sharedManager().isAllowOpenLink = value
            }
            else if item.type == .dark_mode {
                Settings.sharedManager().isDarkMode = value
            }
            else if item.type == .random_node {
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
            else if item.type == .mobile_node {
                AppModel.sharedManager().enableBodyRequests(value)
            }
        }
    }
}

extension SettingsViewController : WalletModelDelegate {
    func onNetwotkStartReconnecting() {
        if self.type == SettingsViewModel.SettingsType.node {
            viewModel.items[0][1].detail = Settings.sharedManager().nodeAddress
            tableView.reloadData()
        }
    }
}

extension SettingsViewController : SettingsModelDelegate {

    func onChangeLanguage() {
        setGradientTopBar(mainColor: UIColor.main.peacockBlue, addedStatusView: true, menu: self.navigationController?.viewControllers.first == self)
        title = viewModel.title()
        if type == .main {
            tableView.tableFooterView = versionView()
        }
        viewModel.reload()
        tableView.reloadData()
        
        statusView.removeFromSuperview()
        
        statusView = BMNetworkStatusView()
        statusView.tag = 11
        statusView.y = Device.isXDevice ? 110 : 80
        statusView.x = 5
        self.view.addSubview(statusView)
    }
    
    func onChangeDarkMode() {
        UIView.animate(withDuration: 0.5) {
            self.view.backgroundColor = UIColor.main.marine
            self.tableView.backgroundColor = UIColor.main.marine
            self.tableView.tableHeaderView?.backgroundColor = UIColor.main.marine
        }
        
        let cells = tableView.visibleCells
        for cell in cells {
            if let bCell = cell as? SettingsCell {
                bCell.changeBacgkroundView()
            }
        }
        
        tableView.reloadData()
    }
}
