//
// SelectNodeViewController.swift
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

struct SelectNode {
    let title:String
    let subTitle:String
    let detail:String
    let icon:String
    var selected:Bool
}

class SelectNodeViewController: BaseTableViewController {

    private var items = [SelectNode]()
    private var inputField = BMField()
    private var oldSelected = 0

    public var isNeedDisconnect = true
    public var isCreateWallet = false
    public var password:String?
    public var phrase:String?
    
    override var tableStyle: UITableView.Style {
        get { return .grouped }
        set { super.tableStyle = newValue }
    }
    
    private func footerView() -> UIView  {
        let view = UIView(frame: CGRect(x: 0, y: 0, width: UIScreen.main.bounds.size.width, height: 155))
        
        if !isCreateWallet && self.items[2].selected {
            let nextButton = BMButton.defaultButton(frame: CGRect(x: (UIScreen.main.bounds.size.width-220)/2, y: 10, width: 220, height: 44), color: UIColor.main.brightTeal)
            nextButton.setImage(IconNextBlue(), for: .normal)
            nextButton.setTitle(Localizable.shared.strings.proceed.lowercased(), for: .normal)
            nextButton.setTitleColor(UIColor.main.marineOriginal, for: .normal)
            nextButton.setTitleColor(UIColor.main.marineOriginal.withAlphaComponent(0.5), for: .highlighted)
            nextButton.addTarget(self, action: #selector(onNext), for: .touchUpInside)
            view.addSubview(nextButton)
        }
        else if isCreateWallet {
            let connectButton = BMButton.defaultButton(frame: CGRect(x: (UIScreen.main.bounds.size.width-220)/2, y: 25, width: 220, height: 44), color: UIColor.main.brightTeal)
            connectButton.setImage(IconNextBlue(), for: .normal)
            connectButton.setTitle(Localizable.shared.strings.start_using_wallet.lowercased(), for: .normal)
            connectButton.setTitleColor(UIColor.main.marineOriginal, for: .normal)
            connectButton.setTitleColor(UIColor.main.marineOriginal.withAlphaComponent(0.5), for: .highlighted)
            connectButton.addTarget(self, action: #selector(onNext), for: .touchUpInside)
            view.addSubview(connectButton)
        }
//        else if !isNeedDisconnect {
//            let connectButton = BMButton.defaultButton(frame: CGRect(x: (UIScreen.main.bounds.size.width-220)/2, y: 80, width: 220, height: 44), color: UIColor.main.brightTeal)
//            connectButton.setImage(IconDoneBlue(), for: .normal)
//            connectButton.setTitle(Localizable.shared.strings.connect.lowercased(), for: .normal)
//            connectButton.setTitleColor(UIColor.main.marineOriginal, for: .normal)
//            connectButton.setTitleColor(UIColor.main.marineOriginal.withAlphaComponent(0.5), for: .highlighted)
//            connectButton.addTarget(self, action: #selector(onNext), for: .touchUpInside)
//            view.addSubview(connectButton)
//        }
        
        return view
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        items.append(SelectNode(title: Localizable.shared.strings.random_node_title, subTitle: Localizable.shared.strings.fast_sync, detail: Localizable.shared.strings.random_node_text, icon: "iconRandomNode", selected: false))
        items.append(SelectNode(title: Localizable.shared.strings.mobile_node_title, subTitle: Localizable.shared.strings.slow_sync, detail: Localizable.shared.strings.mobile_node_hint, icon: "iconMobbileNode", selected: false))
        items.append(SelectNode(title: Localizable.shared.strings.own_node_title, subTitle: Localizable.shared.strings.fast_secure_advance, detail: Localizable.shared.strings.own_node_text, icon: "iconSpecificNode", selected: false))
        
        if isCreateWallet {
            oldSelected = 0
            items[0].selected = true
        }
        else {
            if Settings.sharedManager().isNodeProtocolEnabled {
                oldSelected = 1
                items[1].selected = true
            }
            else if !Settings.sharedManager().connectToRandomNode {
                oldSelected = 2
                items[2].selected = true
            }
            else {
                oldSelected = 0
                items[0].selected = true
            }
        }
        
        inputField.awakeFromNib()
        
        setGradientTopBar(mainColor: UIColor.main.peacockBlue, addedStatusView: !isCreateWallet)
        
        title = Localizable.shared.strings.node
        
        statusView.changeButton.removeFromSuperview()
        
        tableView.register(NodeCell.self)
        tableView.separatorStyle = .none
        tableView.dataSource = self
        tableView.delegate = self
        tableView.contentInsetAdjustmentBehavior = .never
        tableView.tableHeaderView = UIView(frame: CGRect(x: 0.0, y: 0.0, width: 0.0, height: 20))
        tableView.tableHeaderView?.backgroundColor = UIColor.main.marine
        tableView.tableFooterView = footerView()
        tableView.backgroundColor = UIColor.main.marine
        tableView.keyboardDismissMode = .interactive
                      
        inputField.setNormalColor(color: .white)
        inputField.keyboardType = .numbersAndPunctuation
        inputField.spellCheckingType = .no
        inputField.autocorrectionType = .no
        inputField.autocapitalizationType = .none
        inputField.textColor = UIColor.white
        inputField.textAlignment = .right
        inputField.placeholder = "12.123.123.1234"
        inputField.placeHolderColor = UIColor.white.withAlphaComponent(0.20)
        inputField.delegate = self
        if !isCreateWallet {
            inputField.text = Settings.sharedManager().customNode()
        }
        inputField.tintColor = UIColor.white
                
        if isCreateWallet {
            self.navigationItem.leftBarButtonItem = nil
        }
    }
    
    @objc private func onDisconnect() {
        isNeedDisconnect = false
        tableView.tableFooterView = footerView()
        tableView.reloadData()
    }
    
    private func openMain() {
        AppModel.sharedManager().stopChangeWallet()
        AppModel.sharedManager().refreshAddresses()
        AppModel.sharedManager().getUTXO()

        let mainVC = BaseNavigationController.navigationController(rootViewController: WalletViewController())
        let menuViewController = LeftMenuViewController()
        
        let sideMenuController = LGSideMenuController(rootViewController: mainVC,
                                                      leftViewController: menuViewController,
                                                      rightViewController: nil)
        
        sideMenuController.leftViewWidth = UIScreen.main.bounds.size.width - 60;
        sideMenuController.leftViewPresentationStyle = LGSideMenuPresentationStyle.slideAbove;
        sideMenuController.rootViewLayerShadowRadius = 0
        sideMenuController.rootViewLayerShadowColor = UIColor.clear
        sideMenuController.leftViewLayerShadowRadius = 0
        sideMenuController.rootViewCoverAlphaForLeftView = 0.5
        sideMenuController.rootViewCoverAlphaForRightView = 0.5
        sideMenuController.leftViewCoverAlpha = 0.5
        sideMenuController.rightViewCoverAlpha = 0.5
        sideMenuController.modalTransitionStyle = .crossDissolve
        
        self.navigationController?.setViewControllers([sideMenuController], animated: true)

        BMLockScreen.shared.onTapEvent()
    }
    
    @objc private func onNext() {
        isNeedDisconnect = true
        tableView.tableFooterView = footerView()
        tableView.reloadData()
        
        if items[0].selected {
            if isCreateWallet {
                Settings.sharedManager().removeCustomNode()
            }
     
            if Settings.sharedManager().isNodeProtocolEnabled {
                Settings.sharedManager().isNodeProtocolEnabled = false
                AppModel.sharedManager().enableBodyRequests(false)
            }
            Settings.sharedManager().connectToRandomNode = true
            Settings.sharedManager().nodeAddress = AppModel.chooseRandomNode();
            AppModel.sharedManager().changeNodeAddress()
            
            if isCreateWallet {
                openMain()
            }
        }
        else if items[1].selected {
            if isCreateWallet {
                Settings.sharedManager().removeCustomNode()
            }
            
            Settings.sharedManager().connectToRandomNode = true
            Settings.sharedManager().isNodeProtocolEnabled = true
            Settings.sharedManager().nodeAddress = AppModel.chooseRandomNode();
            AppModel.sharedManager().changeNodeAddress()
            AppModel.sharedManager().enableBodyRequests(true)
            
            if isCreateWallet {
                let vc = OpenWalletProgressViewController(password: self.password ?? "", phrase: self.phrase)
                self.pushViewController(vc: vc)
            }
            else {
                let vc = OpenWalletProgressViewController(onlyConnect: true)
                vc.cancelCallback = {
                    self.items[0].selected = true
                    self.items[2].selected = false
                    self.onNext()
                }
                pushViewController(vc: vc)
            }
        }
        else {
            if let fullAddress = inputField.text {
                if fullAddress.isEmpty {
                    isNeedDisconnect = false
                    tableView.tableFooterView = footerView()
                    tableView.reloadData()
                    
                    alert(title: Localizable.shared.strings.invalid_address_title, message: Localizable.shared.strings.enter_node_address, handler: nil)
                }
                else if AppModel.sharedManager().isValidNodeAddress(fullAddress) && !fullAddress.isEmpty {
                    
                    if isCreateWallet {
                        if Settings.sharedManager().isNodeProtocolEnabled {
                            Settings.sharedManager().isNodeProtocolEnabled = false
                            AppModel.sharedManager().enableBodyRequests(false)
                        }
                        Settings.sharedManager().connectToRandomNode = false
                        Settings.sharedManager().nodeAddress = fullAddress
                        AppModel.sharedManager().changeNodeAddress()
                        
                        let vc = OpenWalletProgressViewController(password: self.password ?? "", phrase: self.phrase)
                        self.pushViewController(vc: vc)
                    }
                    else {
                        if oldSelected == 0 {
                            self.confirmAlert(title: Localizable.shared.strings.switch_to_own, message: String.init(format: Localizable.shared.strings.switch_to_own_from_random, fullAddress), cancelTitle: Localizable.shared.strings.cancel, confirmTitle: Localizable.shared.strings.sw) { _  in
                                
                            } confirmHandler: { _  in
                                self.onToOwnNode(fullAddress: fullAddress)
                            }
                        }
                        else if oldSelected == 1 {
                            self.confirmAlert(title: Localizable.shared.strings.switch_to_own, message: String.init(format: Localizable.shared.strings.switch_to_own_from_mobile, fullAddress), cancelTitle: Localizable.shared.strings.cancel, confirmTitle: Localizable.shared.strings.sw) { _  in
                                
                            } confirmHandler: { _  in
                                self.onToOwnNode(fullAddress: fullAddress)
                            }
                        }
                        else if oldSelected == 2 {
                            if Settings.sharedManager().nodeAddress != fullAddress {
                                if (Settings.sharedManager().nodeAddress.contains("beam.mw")) {
                                    self.confirmAlert(title: Localizable.shared.strings.switch_to_own, message: String.init(format: Localizable.shared.strings.switch_to_own_from_random, fullAddress), cancelTitle: Localizable.shared.strings.cancel, confirmTitle: Localizable.shared.strings.sw) { _  in
                                        
                                    } confirmHandler: { _  in
                                        self.onToOwnNode(fullAddress: fullAddress)
                                    }
                                }
                                else {
                                    self.confirmAlert(title: Localizable.shared.strings.switch_to_own, message: String.init(format: Localizable.shared.strings.switch_to_own_from_own, Settings.sharedManager().nodeAddress, fullAddress), cancelTitle: Localizable.shared.strings.cancel, confirmTitle: Localizable.shared.strings.sw) { _  in
                                        
                                    } confirmHandler: { _  in
                                        self.onToOwnNode(fullAddress: fullAddress)
                                    }
                                }
                            }
                            else {
                                self.onToOwnNode(fullAddress: fullAddress)
                            }
                        }
                    }
                }
                else {
                    isNeedDisconnect = false
                    tableView.tableFooterView = footerView()
                    tableView.reloadData()
                    
                    alert(title: Localizable.shared.strings.invalid_address_title, message: Localizable.shared.strings.invalid_address_text, handler: nil)
                }
            }
        }
    }
    
    private func onToOwnNode(fullAddress:String) {
        if Settings.sharedManager().isNodeProtocolEnabled {
            Settings.sharedManager().isNodeProtocolEnabled = false
            AppModel.sharedManager().enableBodyRequests(false)
        }
        Settings.sharedManager().connectToRandomNode = false
        Settings.sharedManager().nodeAddress = fullAddress
        AppModel.sharedManager().changeNodeAddress()
        
        let vc = OpenWalletProgressViewController(onlyConnect: true)
        vc.cancelCallback = {
        }
        pushViewController(vc: vc)
    }
}

extension SelectNodeViewController : UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if indexPath.row == 1 {
            return 80
        }
        return UITableView.automaticDimension
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        if isCreateWallet {
            self.onNextSelected(indexPath: indexPath)
        }
        else if items[0].selected {
            if indexPath.section == 1 {
                self.confirmAlert(title: Localizable.shared.strings.switch_to_mobile, message: Localizable.shared.strings.switch_to_mobile_from_random, cancelTitle: Localizable.shared.strings.cancel, confirmTitle: Localizable.shared.strings.sw) { _  in
                    
                } confirmHandler: { _  in
                    self.oldSelected = 0
                    self.onNextSelected(indexPath: indexPath)
                    self.onNext()
                }
            }
            else if indexPath.section == 2 {
                self.onNextSelected(indexPath: indexPath)
            }
        }
        else if items[1].selected {
            if indexPath.section == 0 {
                self.confirmAlert(title: Localizable.shared.strings.switch_to_random, message: Localizable.shared.strings.switch_to_random_from_mobile, cancelTitle: Localizable.shared.strings.cancel, confirmTitle: Localizable.shared.strings.sw) { _  in
                    
                } confirmHandler: { _  in
                    self.onNextSelected(indexPath: indexPath)
                    self.onNext()
                }
            }
            else if indexPath.section == 2 {
                self.onNextSelected(indexPath: indexPath)
            }
        }
        else if items[2].selected {
            if !Settings.sharedManager().connectToRandomNode {
                if indexPath.section == 0 {
                    self.confirmAlert(title: Localizable.shared.strings.switch_to_random, message: String.init(format: Localizable.shared.strings.switch_to_random_from_own, Settings.sharedManager().connectToRandomNode ? "" : Settings.sharedManager().nodeAddress), cancelTitle: Localizable.shared.strings.cancel, confirmTitle: Localizable.shared.strings.sw) { _  in
                    } confirmHandler: { _  in
                        self.oldSelected = 0
                        self.onNextSelected(indexPath: indexPath)
                        self.onNext()
                    }
                }
                else if indexPath.section == 1 {
                    self.confirmAlert(title: Localizable.shared.strings.switch_to_mobile, message: String.init(format: Localizable.shared.strings.switch_to_mobile_from_own, Settings.sharedManager().connectToRandomNode ? "" : Settings.sharedManager().nodeAddress), cancelTitle: Localizable.shared.strings.cancel, confirmTitle: Localizable.shared.strings.sw) { _  in
                    } confirmHandler: { _  in
                        self.onNextSelected(indexPath: indexPath)
                        self.onNext()
                    }
                }
            }
            else {
                if indexPath.section == 0 && Settings.sharedManager().isNodeProtocolEnabled {
                    self.confirmAlert(title: Localizable.shared.strings.switch_to_random, message: Localizable.shared.strings.switch_to_random_from_mobile, cancelTitle: Localizable.shared.strings.cancel, confirmTitle: Localizable.shared.strings.sw) { _  in
                        
                    } confirmHandler: { _  in
                        self.oldSelected = 0
                        self.onNextSelected(indexPath: indexPath)
                        self.onNext()
                    }
                }
                else if indexPath.section == 1 && !Settings.sharedManager().isNodeProtocolEnabled {
                    self.confirmAlert(title: Localizable.shared.strings.switch_to_mobile, message: Localizable.shared.strings.switch_to_mobile_from_random, cancelTitle: Localizable.shared.strings.cancel, confirmTitle: Localizable.shared.strings.sw) { _  in
                        
                    } confirmHandler: { _  in
                        self.onNextSelected(indexPath: indexPath)
                        self.onNext()
                    }
                }
                else {
                    self.onNextSelected(indexPath: indexPath)
                }
            }
        }
    }
    
    private func onNextSelected(indexPath: IndexPath) {
        for (index, _) in items.enumerated() {
            items[index].selected = false
        }
        
        items[indexPath.section].selected = true
        
        tableView.tableFooterView = footerView()
        tableView.reloadData()
    }
}

extension SelectNodeViewController : UITableViewDataSource {
    
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        if section > 0 {
            let view = UIView()
            view.backgroundColor = UIColor.clear
            return view
        }
        return nil
    }
    
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return section > 0 ? 40 : 0
    }
    

    func numberOfSections(in tableView: UITableView) -> Int {
        return items.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 2 {
            return items[section].selected ? 2 : 1
        }
        return 1
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        if indexPath.row == 1 {
            var cell = tableView.dequeueReusableCell(withIdentifier: "Cell")
            if cell == nil {
                cell = UITableViewCell.init(style: .default, reuseIdentifier: "Cell")
                
                cell?.backgroundColor = UIColor.main.cellBackgroundColor
                cell?.contentView.backgroundColor = UIColor.clear
                cell?.selectionStyle = .none
                
                let view = UIView(frame: CGRect(x: 0, y: 5, width: UIScreen.main.bounds.width, height: 65))
                inputField.frame = CGRect(x: UIScreen.main.bounds.width-265, y: 10, width: 250, height: 45)
                view.addSubview(inputField)
                
                let label = UILabel(frame: CGRect(x: 15, y: 0, width: 80, height: 65))
                label.text = Localizable.shared.strings.ip_port.uppercased()
                label.textColor = UIColor.white
                label.font = BoldFont(size: 14)
                view.addSubview(label)
                
                let mainView = UIView(frame: CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: 80))
                mainView.backgroundColor = UIColor.clear
                mainView.addSubview(view)
                
                cell?.contentView.addSubview(mainView)
            }
  
            cell?.isUserInteractionEnabled = true
            cell?.alpha = 1.0
            cell?.contentView.alpha = 1
            
            
            return cell ?? UITableViewCell()
        }
        else {
            let cell = tableView
                .dequeueReusableCell(withType: NodeCell.self, for: indexPath)
            cell.configure(items[indexPath.section], selected: items[indexPath.section].selected)
            
            cell.isUserInteractionEnabled = true
            cell.alpha = 1.0
            cell.contentView.alpha = 1
            
            return cell
        }
    }
}

extension SelectNodeViewController: UITextFieldDelegate {
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        
        return true
    }
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        
        let textFieldText: NSString = (textField.text ?? "") as NSString
        
        let txtAfterUpdate = textFieldText.replacingCharacters(in: range, with: string)
        
        if txtAfterUpdate.countInstances(of: ":") > 1 {
            return false
        }
        else if txtAfterUpdate.contains(":") {
            let splited = txtAfterUpdate.split(separator: ":")
            if splited.count == 2 {
                let port = String(splited[1])
                let portRange = (txtAfterUpdate as NSString).range(of: String(port))
                
                if port.isEmpty == false && string == ":" {
                    return false
                }
                else if range.intersection(portRange) != nil || port.lengthOfBytes(using: .utf8) == 1 {
                    return (port.isNumeric() && port.isValidPort())
                }
            }
        }
        
        return true
    }
    
    func textFieldShouldClear(_ textField: UITextField) -> Bool {
        return true
    }
}
