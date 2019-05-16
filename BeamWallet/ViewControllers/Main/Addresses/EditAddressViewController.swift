//
// EditAddressViewController.swift
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

class EditAddressViewController: BaseViewController {
    
    private let hours_24: UInt64 = 86400
    private var address:BMAddress!
    private var oldAddress:BMAddress!
    
    @IBOutlet private weak var tableView: UITableView!
    
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
        fatalError(LocalizableStrings.fatalInitCoderError)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = LocalizableStrings.edit_address
        
        tableView.keyboardDismissMode = .interactive
        tableView.register([AddressSwitchCell.self,AddressExpiresCell.self,AddressExpiredCell.self,
            AddressCommentCell.self,AddressCategoryCell.self])

        addRightButton(title:LocalizableStrings.save, targer: self, selector: #selector(onSave), enabled: false)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: UIResponder.keyboardWillHideNotification, object: nil)
        
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillShowNotification , object: nil)
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillHideNotification , object: nil)
    }
    
    private func checkIsChanges(){
        if oldAddress.label != address.label {
            enableRightButton(enabled: true)
        }
        else if oldAddress.isNowExpired != address.isNowExpired {
            enableRightButton(enabled: true)
        }
        else if oldAddress.isNowActive != address.isNowActive {
            enableRightButton(enabled: true)
        }
        else if oldAddress.duration != address.duration {
            enableRightButton(enabled: true)
        }
        else if oldAddress.category != address.category {
            enableRightButton(enabled: true)
        }
        else{
            enableRightButton(enabled: false)
        }
    }
    
    @IBAction func onSave(sender : UIBarButtonItem) {
        AppModel.sharedManager().edit(address)
        
        navigationController?.popViewController(animated: true)
    }
}

extension EditAddressViewController : UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        if section == 2 && address.isNowActive && address.isExpired() {
            return 30
        }
        else if section == 2 {
            return 0
        }
        return 30
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        
        switch indexPath.section {
        case 0:
            return address.isExpired() ? AddressExpiredCell.height() : AddressExpiresCell.height()
        case 1:
            return AddressSwitchCell.height()
        case 2:
            return (address.isNowActive && address.isExpired()) ? AddressExpiresCell.height() : 0
        case 3:
            return AddressCategoryCell.height()
        case 4:
            return AddressCommentCell.height()
        default:
            return 0
        }
    }
    
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        if (indexPath.section == 0) || (indexPath.section == 2 && address.isNowActive && address.isExpired()) {
            
            let vc = AddressExpiresPickerViewController(duration: -1)
            vc.completion = {
                obj in
                
                self.address.isChangedDate = true

                if obj == 24 {
                    self.address.isNowActive = true
                    self.address.isNowActiveDuration = self.hours_24
                    
                    if self.address.isExpired() {
                    }
                    else {
                        self.address.isNowExpired = false
                    }
                }
                else {
                    if self.address.isNowActive {
                        self.address.isNowActiveDuration = 0
                    }
                    else{
                        self.address.duration = 0
                    }
                    
                    if self.address.isExpired() {
                    }
                    else {
                        self.address.isNowExpired = false
                    }
                }
                
                self.checkIsChanges()
                self.tableView.reloadData()
            }
            
            pushViewController(vc: vc)
        }
        else if indexPath.section == 3 {
            if AppModel.sharedManager().categories.count == 0 {
               
                let vc = CategoryEditViewController(category: nil)
                vc.completion = {
                    obj in
                    if let category = obj {
                        self.address.category = String(category.id)
                        self.checkIsChanges()
                        self.tableView.reloadData()
                    }
                }
                self.pushViewController(vc: vc)
            }
            else{
                let vc  = CategoryPickerViewController(category: AppModel.sharedManager().findCategory(byId: self.address.category))
                vc.completion = {
                    obj in
                    if let cat = obj {
                        self.address.category = String(cat.id)
                        self.checkIsChanges()
                        self.tableView.reloadData()
                    }
                }
                pushViewController(vc: vc)
            }

        }
    }
}

extension EditAddressViewController : UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 5
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        if indexPath.section == 0 {
            if address.isExpired() {
                let cell = tableView
                    .dequeueReusableCell(withType: AddressExpiredCell.self, for: indexPath)
                    .configured(with: address)
                return cell
            }
            else{
                let cell = tableView
                    .dequeueReusableCell(withType: AddressExpiresCell.self, for: indexPath)
                    .configured(with: address)
                return cell
            }
        }
        else if indexPath.section == 1 {
            
            let text = address.isExpired() ? LocalizableStrings.active_address : LocalizableStrings.expire_now
            
            let selected = (address.isExpired()) ? address.isNowActive : address.isNowExpired
            
            let cell =  tableView
                .dequeueReusableCell(withType: AddressSwitchCell.self, for: indexPath)
                .configured(with: (text: text, selected: selected))
            cell.delegate = self
            
            return cell
        }
        else if indexPath.section == 2 && address.isNowActive && address.isExpired() {
            let cell = tableView
                .dequeueReusableCell(withType: AddressExpiresCell.self, for: indexPath)
                .configured(with: address)
            return cell
        }
        else if indexPath.section == 3 {
            let cell =  tableView
                .dequeueReusableCell(withType: AddressCategoryCell.self, for: indexPath)
                .configured(with: address)
            
            return cell
        }
        else if indexPath.section == 4 {
            let cell =  tableView
                .dequeueReusableCell(withType: AddressCommentCell.self, for: indexPath)
                .configured(with: address.label)
            cell.delegate = self
            
            return cell
        }

        
        let cell = BaseCell()
        return cell
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        return UIView()
    }
}

extension EditAddressViewController : AddressSwitchCellDelegate {
    func onSwitch(value:Bool) {
        if address.isExpired() {
            address.isNowActive = !address.isNowActive
            address.isNowExpired = false
        }
        else {
            address.isNowExpired = !address.isNowExpired
            address.isNowActive = false
        }
        
        checkIsChanges()
        
        tableView.reloadData()
    }
}

extension EditAddressViewController : AddressCommentCellDelegate {
    func onChangeComment(value: String) {
        address.label = value
        checkIsChanges()
    }
}

extension EditAddressViewController {
    @objc func keyboardWillShow(_ notification: Notification) {
        if let keyboardFrame: NSValue = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue {
            let keyboardRectangle = keyboardFrame.cgRectValue
            let keyboardHeight = keyboardRectangle.height
            
            tableView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: keyboardHeight, right: 0)
            tableView.scrollToRow(at: IndexPath(row: 0, section: 4), at: .top, animated: false)
        }
    }
    
    @objc func keyboardWillHide(notification: NSNotification) {
        tableView.contentInset = UIEdgeInsets.zero
    }
}

