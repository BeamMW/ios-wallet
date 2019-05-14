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

class ClearDataViewController: BaseViewController {

    class ClearItem {
        public var title:String!
        public var isSelected:Bool!
        public var id:Int!
        
        init(title: String!, isSelected: Bool!, id:Int) {
            self.title = title
            self.isSelected = isSelected
            self.id = id
        }
    }
    
    @IBOutlet private weak var tableView: UITableView!

    private var items = [ClearItem(title: "Delete all addresses", isSelected: false, id: 1),
                         ClearItem(title: "Delete all contacts", isSelected: false, id: 2),
                         ClearItem(title: "Delete all transactions", isSelected: false, id: 3)]
    
    override func viewDidLoad() {
        super.viewDidLoad()

        title = "Clear data"
        
        addRightButton(title:"Clear", targer: self, selector: #selector(onClear), enabled: false)

        tableView.tableFooterView = UIView()
        tableView.separatorColor = UIColor.main.marineTwo
    }

    @objc private func onClear() {
        var deleted = [String]()
        if items[0].isSelected {
            deleted.append("addresses")
        }
        if items[1].isSelected {
            deleted.append("contacts")
        }
        if items[2].isSelected {
            deleted.append("transactions")
        }
        
        var str = ""
        if deleted.count == 1 {
            str = deleted.joined(separator: "")
        }
        else if deleted.count == 2 {
            str = deleted.joined(separator: " and ")
        }
        else if deleted.count == 3 {
            str = deleted.joined(separator: ", ")
        }
        
        let alert = UIAlertController(title: "Clear data", message: "Are you sure you want to delete all \(str) from your wallet?", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Cancel", style: .default, handler: nil))
        
        let ok = UIAlertAction(title: "Clear", style: .destructive, handler: { action in
            self.makeClear()
        })
        alert.addAction(ok)
        
        self.present(alert, animated: true)
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
        
        self.navigationController?.popViewController(animated: true)
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
        
        let cell = UITableViewCell(style: .default, reuseIdentifier: "Cell")
        cell.textLabel?.text = items[indexPath.row].title
        cell.textLabel?.font = RegularFont(size: 16)
        cell.backgroundColor = UIColor.clear
        cell.selectionStyle = .none
        cell.textLabel?.textColor = UIColor.white
        cell.textLabel?.adjustFontSize = true
        
        let selectedButton = UIButton(frame: CGRect(x: 0, y: 0, width: 40, height: 40))
        selectedButton.setImage(UIImage(named: "checkboxEmpty"), for: .normal)
        selectedButton.setImage(UIImage(named: "checkboxFull"), for: .selected)
        selectedButton.isSelected = items[indexPath.row].isSelected
        selectedButton.tag = indexPath.row
        selectedButton.addTarget(self, action: #selector(onCheckBox), for: .touchUpInside)
        selectedButton.contentHorizontalAlignment = UIControl.ContentHorizontalAlignment.right;
        cell.accessoryView = selectedButton
        
        return cell
    }
}
