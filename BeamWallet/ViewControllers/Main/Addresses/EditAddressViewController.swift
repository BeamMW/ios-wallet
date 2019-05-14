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

class EditAddressViewController: BaseViewController {
    
    private let hours_24: UInt64 = 86400
    private var address:BMAddress!
    private var oldAddress:BMAddress!
    
    private var details = [GeneralInfo]()
    
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
        tableView.register(GeneralInfoCell.self)
        tableView.register(AddressSwitchCell.self)
        tableView.register(AddressExpireCell.self)
        tableView.register(AddressCommentCell.self)
        
        hideKeyboardWhenTappedAround()
        
        fillDetails()
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
        
        details.append(GeneralInfo(text: "Address ID:", detail: address.walletId, failed: false, canCopy:true, color: UIColor.white))
        
        if address.isExpired() {
            details.append(GeneralInfo(text: "Expired:", detail: address.formattedDate(), failed: false, canCopy:false, color: UIColor.white))
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
                    .dequeueReusableCell(withType: GeneralInfoCell.self, for: indexPath)
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
                var text = address.isExpired() ? "Active address" : "Expire address now"
                
                if Device.screenType == .iPhones_Plus || Device.screenType == .iPhone_XSMax {
                    text = address.isExpired() ? "Active address" : "Expire address\nnow"
                }
                
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
        
        let alert = UIAlertController(title: "Expires", message: nil, preferredStyle: .actionSheet)
        
        alert.addAction(UIAlertAction(title: "24 hours", style: .default , handler:{ (UIAlertAction)in
            if self.address.isNowActive {
                self.address.isNowActiveDuration = self.hours_24
            }
            else{
                self.address.duration = self.hours_24
            }
            
            self.checkIsChanges()
            self.fillDetails()
            self.tableView.reloadData()
        }))
        
        alert.addAction(UIAlertAction(title: "Never", style: .default , handler:{ (UIAlertAction)in
            if self.address.isNowActive {
                self.address.isNowActiveDuration = 0
            }
            else{
                self.address.duration = 0
            }
            
            self.checkIsChanges()
            self.fillDetails()
            self.tableView.reloadData()
        }))
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler:{ (UIAlertAction)in
        }))
        
        self.present(alert, animated: true)
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

