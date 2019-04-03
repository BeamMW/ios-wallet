//
//  EditAddressViewController.swift
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
import SelectItemController

class EditAddressViewController: BaseViewController {

    private let hours_24: UInt64 = 86400
    private var address:BMAddress!
    private var oldAddress:BMAddress!

    private var details = [TransactionViewController.TransactionGeneralInfo]()

    @IBOutlet private weak var tableView: UITableView!
    @IBOutlet private weak var saveButton: UIButton!

    init(address:BMAddress) {
        super.init(nibName: nil, bundle: nil)
        
        self.oldAddress = address
        
        self.address = BMAddress()
        self.address.walletId = address.walletId
        self.address.label = address.label
        self.address.category = address.category
        self.address.createTime = address.createTime
        self.address.duration = address.duration
        self.address.ownerId = address.ownerId
        self.address.isNowExpired = false
        self.address.isNowActive = false
        self.address.isNowActiveDuration = hours_24
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        title = "Edit address"
        
        tableView.keyboardDismissMode = .interactive
        tableView.register(GeneralTransactionInfoCell.self)
        tableView.register(AddressSwitchCell.self)
        tableView.register(AddressExpireCell.self)
        tableView.register(AddressCommentCell.self)

        hideKeyboardWhenTappedAround()
        
        fillDetails()
    }
    
    private func checkIsChanges(){
        if oldAddress.label != address.label {
            saveButton.isEnabled = true
        }
        else if oldAddress.isNowExpired != address.isNowExpired {
            saveButton.isEnabled = true
        }
        else if oldAddress.isNowActive != address.isNowActive {
            saveButton.isEnabled = true
        }
        else if oldAddress.duration != address.duration {
            saveButton.isEnabled = true
        }
        else{
            saveButton.isEnabled = false
        }
    }
    
    private func fillDetails() {
        details.removeAll()
        
        details.append(TransactionViewController.TransactionGeneralInfo(text: "Address ID:", detail: address.walletId, failed: false, canCopy:true))
        
        if address.isExpired() {
            details.append(TransactionViewController.TransactionGeneralInfo(text: "Expired:", detail: address.formattedDate(), failed: false, canCopy:false))
        }
        
        tableView.reloadData()
    }
    
    @IBAction func onSave(sender : UIButton) {
        AppModel.sharedManager().edit(address)
        
        navigationController?.popViewController(animated: true)
    }
}

extension EditAddressViewController : UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        if section == 1 || section == 2 {
            return 30
        }
        
        return 0
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if indexPath.section == 0 {
            if indexPath.row == details.count {
                return 80
            }
        }
        else if indexPath.section == 1 && address.isNowActive && indexPath.row == 1 {
            return 80
        }
        
        return UITableView.automaticDimension
    }
    
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
}

extension EditAddressViewController : UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 3
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            return details.count + (address.isExpired() ? 0 : 1)
        }
        else if section == 1 && address.isNowActive {
            return 2
        }
        
        return 1
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        if indexPath.section == 0 {
            if indexPath.row == details.count {
                let cell =  tableView
                    .dequeueReusableCell(withType: AddressExpireCell.self, for: indexPath)
                    .configured(with: address)
                cell.delegate = self
                return cell
            }
            else{
                let cell =  tableView
                    .dequeueReusableCell(withType: GeneralTransactionInfoCell.self, for: indexPath)
                    .configured(with: details[indexPath.row])
                
                return cell
            }
        }
        else if indexPath.section == 1 {
            if address.isNowActive && indexPath.row == 1 {
                let cell =  tableView
                    .dequeueReusableCell(withType: AddressExpireCell.self, for: indexPath)
                    .configured(with: address)
                cell.delegate = self
                return cell
            }
            else{
                let text = address.isExpired() ? "Active address" : "Expire address now"
                let selected = false
                
                let cell =  tableView
                    .dequeueReusableCell(withType: AddressSwitchCell.self, for: indexPath)
                    .configured(with: (text: text, selected: selected))
                cell.delegate = self
                
                return cell
            }
        }
        else if indexPath.section == 2 {
            
            let cell =  tableView
                .dequeueReusableCell(withType: AddressCommentCell.self, for: indexPath)
                .configured(with: address.label)
            cell.delegate = self
            
            return cell
        }
        else{
            return UITableViewCell()
        }
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        if section == 1 || section == 2 {
            return UIView()
        }
        
        return nil
    }
}

extension EditAddressViewController : AddressSwitchCellDelegate {
    func onSwitch(value:Bool) {
        if address.isExpired() {
            address.isNowActive = !address.isNowActive
        }
        else {
            address.isNowExpired = !address.isNowExpired
        }
        
        checkIsChanges()

        fillDetails()
        
        tableView.reloadData()
    }
}

extension EditAddressViewController : AddressCommentCellDelegate {
    func onChangeComment(value: String) {
        address.label = value
        checkIsChanges()
    }
}

extension EditAddressViewController : AddressExpireCellDelegate {
    func onShowPopover() {
        let items = ["24 hours", "Never"]
        let params = Parameters(title: "Expires", items: items, cancelButton: "Cancel")
        
        SelectItemController().show(parent: self, params: params) { (index) in
            if let index = index {
                if self.address.isNowActive {
                    self.address.isNowActiveDuration = (index == 0 ? self.hours_24 : 0)
                }
                else{
                    self.address.duration = (index == 0 ? self.hours_24 : 0)
                }
                
                self.checkIsChanges()
                self.fillDetails()
                self.tableView.reloadData()
            }
        }
    }
}

