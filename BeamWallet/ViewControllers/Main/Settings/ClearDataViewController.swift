//
// ClearDataViewController.swift
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

class ClearDataViewController: BaseTableViewController {

    class ClearItem {
        public var title:String!
        public var isSelected:Bool!
        public var id:Int!
        public var name:String!

        init(title: String!, isSelected: Bool!, id:Int, name:String!) {
            self.title = title
            self.isSelected = isSelected
            self.id = id
            self.name = name
        }
    }
    
    private var items = [ClearItem(title: Localizable.shared.strings.delete_all_addresses, isSelected: false, id: 1, name: Localizable.shared.strings.addresses.lowercased()), ClearItem(title: Localizable.shared.strings.delete_all_contacts, isSelected: false, id: 2, name: Localizable.shared.strings.contacts.lowercased()), ClearItem(title: Localizable.shared.strings.delete_all_transactions, isSelected: false, id: 3, name: Localizable.shared.strings.transactions.lowercased())]
    
    override func viewDidLoad() {
        super.viewDidLoad()

        title = Localizable.shared.strings.clear_data
        
        addRightButton(title:Localizable.shared.strings.clear, target: self, selector: #selector(onClear), enabled: false)

        tableView.dataSource = self
        tableView.delegate = self
        tableView.tableFooterView = UIView()
        tableView.separatorColor = UIColor.white.withAlphaComponent(0.13)
        tableView.separatorStyle = .singleLine
    }

    @objc private func onClear() {
        var deleted = [String]()
        
        for item in items {
            if item.isSelected {
                deleted.append(item.name)
            }
        }
        
        var str = String.empty()
        if deleted.count == 1 {
            str = deleted.joined(separator: String.empty())
        }
        else if deleted.count == 2 {
            str = deleted.joined(separator: Localizable.shared.strings.and)
        }
        else if deleted.count == 3 {
            str = deleted.joined(separator: ", ")
        }
        
        self.confirmAlert(title: Localizable.shared.strings.clear_data, message: Localizable.shared.strings.delete_data_text(str: str), cancelTitle: Localizable.shared.strings.cancel, confirmTitle: Localizable.shared.strings.clear, cancelHandler: { (_ ) in
            
        }) { (_ ) in
            self.makeClear()
        }
    }
    
    private func makeClear() {
        for item in items {
            if item.isSelected {
                switch (item.id)
                {
                case 1:
                    AppModel.sharedManager().clearAllAddresses()
                    break
                case 2:
                    AppModel.sharedManager().clearAllContacts()
                    break
                case 3:
                    AppModel.sharedManager().clearAllTransactions()
                    break
                default:
                    break
                }
            }
        }
        
        self.back()
    }
    
    @objc private func onCheckBox(sender:UIButton){
        sender.isSelected = !sender.isSelected
        
        items[sender.tag].isSelected = sender.isSelected

        checkIsEnabled()
    }
    
    private func checkIsEnabled() {
        var isAllDisabled = true
        
        for item in items {
            if item.isSelected {
                isAllDisabled = false
            }
        }
        
        enableRightButton(enabled: !isAllDisabled)
    }
}

extension ClearDataViewController : UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 50
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        items[indexPath.row].isSelected = !items[indexPath.row].isSelected
        
        checkIsEnabled()
        
        tableView.reloadRows(at: [indexPath], with: .none)
    }
    
}

extension ClearDataViewController : UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return items.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = UITableViewCell(style: .default, reuseIdentifier: String(describing: UITableViewCell.self))
        cell.textLabel?.text = items[indexPath.row].title
        cell.textLabel?.font = RegularFont(size: 16)
        cell.backgroundColor = UIColor.clear
        cell.selectionStyle = .none
        cell.textLabel?.textColor = UIColor.white
        cell.textLabel?.adjustFontSize = true
        
        let selectedButton = UIButton(frame: CGRect(x: 0, y: 0, width: 40, height: 40))
        selectedButton.setImage(CheckboxEmpty(), for: .normal)
        selectedButton.setImage(CheckboxFull(), for: .selected)
        selectedButton.isSelected = items[indexPath.row].isSelected
        selectedButton.tag = indexPath.row
        selectedButton.addTarget(self, action: #selector(onCheckBox), for: .touchUpInside)
        selectedButton.contentHorizontalAlignment = UIControl.ContentHorizontalAlignment.right;
        cell.accessoryView = selectedButton
        
        return cell
    }
}
