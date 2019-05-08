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
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = "Edit address"
        
        tableView.keyboardDismissMode = .interactive
        tableView.register(AddressSwitchCell.self)
        tableView.register(AddressExpiresCell.self)
        tableView.register(AddressExpiredCell.self)
        tableView.register(AddressCommentCell.self)
        tableView.register(AddressCategoryCell.self)

      //  hideKeyboardWhenTappedAround()
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Save", style: .plain, target: self, action: #selector(onSave))
        navigationItem.rightBarButtonItem?.tintColor = UIColor.main.brightTeal
        navigationItem.rightBarButtonItem?.isEnabled = false
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if Device.screenType == .iPhones_5 || Device.isZoomed {
            NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: UIResponder.keyboardWillShowNotification, object: nil)
            NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: UIResponder.keyboardWillHideNotification, object: nil)
        }
        
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        if Device.screenType == .iPhones_5 || Device.isZoomed  {
            NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillShowNotification , object: nil)
            NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillHideNotification , object: nil)
        }
    }
    
    private func checkIsChanges(){
        if oldAddress.label != address.label {
            navigationItem.rightBarButtonItem?.isEnabled = true
        }
        else if oldAddress.isNowExpired != address.isNowExpired {
            navigationItem.rightBarButtonItem?.isEnabled = true
        }
        else if oldAddress.isNowActive != address.isNowActive {
            navigationItem.rightBarButtonItem?.isEnabled = true
        }
        else if oldAddress.duration != address.duration {
            navigationItem.rightBarButtonItem?.isEnabled = true
        }
        else if oldAddress.category != address.category {
            navigationItem.rightBarButtonItem?.isEnabled = true
        }
        else{
            navigationItem.rightBarButtonItem?.isEnabled = false
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
        if indexPath.section == 1 {
            return 60
        }
        else if indexPath.section == 0 {
            return address.isExpired() ? 60 : 80
        }
        else if indexPath.section == 2 && address.isNowActive && address.isExpired() {
            return 80
        }
        else if indexPath.section == 3 {
            return 60
        }
        else if indexPath.section == 4 {
            return 120
        }
        return 0
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
                
//                let alertController = UIAlertController(title: "Categories list is empty", message: "You don’t have any categories at the moment.\nYou can create category in Settings or now", preferredStyle: .alert)
//
//                let later = UIAlertAction(title: "Not now", style: .default) { (action) in }
//
//                let create = UIAlertAction(title: "Create now", style: .default) { (action) in
//                    let vc = CategoryEditViewController(category: nil)
//                    vc.completion = {
//                        obj in
//                            if let category = obj {
//                                self.address.category = String(category.id)
//                                self.checkIsChanges()
//                                self.tableView.reloadData()
//                            }
//                    }
//                    self.pushViewController(vc: vc)
//                }
//
//                alertController.addAction(later)
//                alertController.addAction(create)
//
//                self.present(alertController, animated: true, completion: nil)
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
            let text = address.isExpired() ? "Active address" : "Expire address now"
            
            var selected = false
            
            if address.isExpired() {
                selected = address.isNowActive
            }
            else {
                selected = address.isNowExpired
            }
            
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
            tableView.scrollToRow(at: IndexPath(row: 0, section: 2), at: .top, animated: false)
        }
    }
    
    @objc func keyboardWillHide(notification: NSNotification) {
        tableView.contentInset = UIEdgeInsets.zero
    }
}

