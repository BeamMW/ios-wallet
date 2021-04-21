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
    private var inputField = UITextField()

    override var tableStyle: UITableView.Style {
        get { return .grouped }
        set { super.tableStyle = newValue }
    }
    
    private lazy var footerView: UIView = {
        var view = UIView(frame: CGRect(x: 0, y: 0, width: UIScreen.main.bounds.size.width, height: 155))
        
        var connectButton = BMButton.defaultButton(frame: CGRect(x: (UIScreen.main.bounds.size.width-220)/2, y: 80, width: 220, height: 44), color: UIColor.main.brightTeal)
        connectButton.setImage(IconDoneBlue(), for: .normal)
        connectButton.setTitle(Localizable.shared.strings.connect.lowercased(), for: .normal)
        connectButton.setTitleColor(UIColor.main.marineOriginal, for: .normal)
        connectButton.setTitleColor(UIColor.main.marineOriginal.withAlphaComponent(0.5), for: .highlighted)
        connectButton.addTarget(self, action: #selector(onNext), for: .touchUpInside)
        view.addSubview(connectButton)
        
        return view
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setGradientTopBar(mainColor: UIColor.main.peacockBlue, addedStatusView: true)
        
        title = Localizable.shared.strings.node
        
        statusView.changeButton.removeFromSuperview()
        
        tableView.register(NodeCell.self)
        tableView.separatorStyle = .none
        tableView.dataSource = self
        tableView.delegate = self
        tableView.contentInsetAdjustmentBehavior = .never
        tableView.tableHeaderView = UIView(frame: CGRect(x: 0.0, y: 0.0, width: 0.0, height: 20))
        tableView.tableHeaderView?.backgroundColor = UIColor.main.marine
        tableView.tableFooterView = footerView
        tableView.backgroundColor = UIColor.main.marine
        tableView.keyboardDismissMode = .interactive
        
        items.append(SelectNode(title: Localizable.shared.strings.random_node_title, subTitle: Localizable.shared.strings.fast_sync, detail: Localizable.shared.strings.random_node_text, icon: "iconRandomNode", selected: false))
        items.append(SelectNode(title: Localizable.shared.strings.mobile_node_title, subTitle: Localizable.shared.strings.slow_sync, detail: Localizable.shared.strings.mobile_node_hint, icon: "iconMobbileNode", selected: false))
        items.append(SelectNode(title: Localizable.shared.strings.own_node_title, subTitle: Localizable.shared.strings.fast_secure_advance, detail: Localizable.shared.strings.own_node_text, icon: "iconSpecificNode", selected: false))
        
        if Settings.sharedManager().isNodeProtocolEnabled {
            items[1].selected = true
        }
        else if !Settings.sharedManager().connectToRandomNode {
            items[2].selected = true
        }
        else {
            items[0].selected = true
        }
        
        inputField.keyboardType = .numbersAndPunctuation
        inputField.spellCheckingType = .no
        inputField.autocorrectionType = .no
        inputField.autocapitalizationType = .none
        inputField.textColor = UIColor.white
        inputField.textAlignment = .right
        inputField.placeholder = String.empty()
        inputField.delegate = self
        inputField.text = Settings.sharedManager().customNode()
        inputField.tintColor = UIColor.white
        
        let label = UILabel(frame: CGRect(x: 0, y: 0, width: 80, height: 50))
        label.text = Localizable.shared.strings.ip_port
        label.textColor = UIColor.white.withAlphaComponent(0.2)
        inputField.leftView = label
        inputField.leftViewMode = .always
    }
    
    @objc private func onNext() {
        if items[0].selected {
            if Settings.sharedManager().isNodeProtocolEnabled {
                Settings.sharedManager().isNodeProtocolEnabled = false
                AppModel.sharedManager().enableBodyRequests(false)
            }
            Settings.sharedManager().connectToRandomNode = true
            Settings.sharedManager().nodeAddress = AppModel.chooseRandomNode();
            AppModel.sharedManager().changeNodeAddress()
        }
        else if items[1].selected {
            Settings.sharedManager().connectToRandomNode = true
            Settings.sharedManager().isNodeProtocolEnabled = true
            Settings.sharedManager().nodeAddress = AppModel.chooseRandomNode();
            AppModel.sharedManager().changeNodeAddress()
            AppModel.sharedManager().enableBodyRequests(true)
            
            let vc = OpenWalletProgressViewController(onlyConnect: true)
            vc.cancelCallback = {
                self.items[0].selected = true
                self.items[2].selected = false
                self.onNext()
            }
            pushViewController(vc: vc)
        }
        else {
            if let fullAddress = inputField.text {
                if AppModel.sharedManager().isValidNodeAddress(fullAddress) && !fullAddress.isEmpty {
                    Settings.sharedManager().connectToRandomNode = false
                    Settings.sharedManager().nodeAddress = fullAddress
                    AppModel.sharedManager().changeNodeAddress()
                }
                else {
                    alert(title: Localizable.shared.strings.invalid_address_title, message: Localizable.shared.strings.invalid_address_text, handler: nil)
                }
            }
        }
    }
}

extension SelectNodeViewController : UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        for (index, _) in items.enumerated() {
            items[index].selected = false
        }
        
        items[indexPath.section].selected = true
        
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
    
    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        if items[2].selected && section == 2 {
            let view = UIView(frame: CGRect(x: 0, y: 15, width: UIScreen.main.bounds.width, height: 50))
            view.backgroundColor = UIColor.main.cellBackgroundColor
            inputField.frame = CGRect(x: 15, y: 0, width: UIScreen.main.bounds.width-30, height: 50)
            view.addSubview(inputField)
            
            let topLine = UIView(frame: CGRect(x: 0, y: 15, width: UIScreen.main.bounds.width, height: 1))
            topLine.backgroundColor = UIColor.white.withAlphaComponent(0.13)

            let botLine = UIView(frame: CGRect(x: 0, y: 65, width: UIScreen.main.bounds.width, height: 1))
            botLine.backgroundColor = UIColor.white.withAlphaComponent(0.13)
            
            let mainView = UIView(frame: CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: 70))
            mainView.addSubview(topLine)
            mainView.addSubview(botLine)
            mainView.backgroundColor = UIColor.clear
            mainView.addSubview(view)
            
            return mainView
        }
        return nil
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return section > 0 ? 40 : 0
    }
    
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        if items[2].selected && section == 2 {
            return 70
        }
        return 0
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 3
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView
            .dequeueReusableCell(withType: NodeCell.self, for: indexPath)
        cell.configure(items[indexPath.section])
        
        return cell
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
