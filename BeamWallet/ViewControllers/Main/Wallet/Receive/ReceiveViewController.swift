//
// ReceiveViewController.swift
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

class ReceiveViewController: BaseTableViewController {

    private var address:BMAddress!
    private var amount:String?
    private var showAdvanced = false
    private var showEdit = false
    private var isShared = false
    private var pickedAddress:BMAddress?

    init(address:BMAddress) {
        super.init(nibName: nil, bundle: nil)
        
        self.address = address
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError(LocalizableStrings.fatalInitCoderError)
    }
    
    override var isUppercasedTitle: Bool {
        get{
            return true
        }
        set{
            super.isUppercasedTitle = true
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        isGradient = true
        
        setGradientTopBar(mainColor: UIColor.main.brightSkyBlue)
        
        title = LocalizableStrings.receive.uppercased()
        
        tableView.register([BMFieldCell.self, ReceiveAddressButtonsCell.self, BMAmountCell.self, BMExpandCell.self, ReceiveAddressCell.self, BMDetailCell.self])

        if address.walletId == nil {
            AppModel.sharedManager().generateNewWalletAddress { (address, error) in
                if let result = address {
                    DispatchQueue.main.async {
                        self.address = result
                        self.tableView.delegate = self
                        self.tableView.dataSource = self
                        self.tableView.reloadData()
                    }
                }
                else if let reason = error?.localizedDescription {
                    DispatchQueue.main.async {
                        self.alert(message: reason)
                    }
                }
            }
        }
        else{
            tableView.delegate = self
            tableView.dataSource = self
        }
        
        tableView.keyboardDismissMode = .interactive
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        self.view.endEditing(true)

        if isMovingFromParent {
            
            if pickedAddress != nil {
                if !isShared {
                    if pickedAddress?.label != address.label || pickedAddress?.category != address.category {
                        AppModel.sharedManager().edit(pickedAddress!)
                    }
                }
            }
            else if !isShared
            {
                AppModel.sharedManager().deleteAddress(self.address.walletId)
            }
        }
    }
    
    private func onExpire() {
        let vc = AddressExpiresPickerViewController(duration: -1)
        vc.completion = { [weak self]
            obj in
            
            self?.address.duration = obj == 24 ? 86400 : 0
            
            AppModel.sharedManager().setExpires(Int32(obj), toAddress: self?.address.walletId ?? String.empty())
            
            self?.tableView.reloadRows(at: [IndexPath(row: 0, section: 3)], with: .fade)
        }
        vc.isGradient = true
        pushViewController(vc: vc)
    }
    
    private func onCategory() {
        if AppModel.sharedManager().categories.count == 0 {
            self.alert(title: LocalizableStrings.categories_empty_title, message: LocalizableStrings.categories_empty_text, handler: nil)
        }
        else{
            let vc  = CategoryPickerViewController(category: AppModel.sharedManager().findCategory(byId: self.address.category))
            vc.completion = { [weak self]
                obj in
                if let category = obj {
                    self?.didSelectCategory(category: category)
                }
            }
            vc.isGradient = true
            pushViewController(vc: vc)
        }
    }
    
    private func didSelectCategory(category:BMCategory) {
        address.category = String(category.id)
        
        AppModel.sharedManager().setWalletCategory(self.address.category, toAddress: address.walletId)
        
        tableView.reloadRows(at: [IndexPath(row: 0, section: 4)], with: .fade)
    }
}

extension ReceiveViewController : UITableViewDelegate {

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        switch section {
        case 0:
            return 0
        case 2:
            return showEdit ? 20 : 0
        case 3:
            return showEdit ? 20 : 0
        case 4:
            return showEdit ? 20 : 0
        case 6:
            return showAdvanced ? 20 : 0
        default:
            return 30
        }
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        switch indexPath.section {
        case 3:
            self.onExpire()
        case 4:
            self.onCategory()
        default:
            return
        }
    }
}

extension ReceiveViewController : UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 8
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 2 || section == 3 || section == 4 {
            return showEdit ? 1 : 0
        }
        else if section == 6 {
            return showAdvanced ? 1 : 0
        }
        return 1
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
       
        switch indexPath.section {
        case 0:
            let cell = tableView
                .dequeueReusableCell(withType: ReceiveAddressCell.self, for: indexPath)
                .configured(with: (hideLine: true, address: address, title: nil))
            cell.delegate = self
            return cell
        case 1:
            let cell = tableView
                .dequeueReusableCell(withType: BMExpandCell.self, for: indexPath)
                .configured(with: (expand: showEdit, title: LocalizableStrings.edit_address.uppercased()))
            cell.delegate = self
            return cell
        case 3:
            let cell = tableView
                .dequeueReusableCell(withType: BMDetailCell.self, for: indexPath)
                .configured(with: (title: LocalizableStrings.expires.uppercased(), value: (address.duration > 0 ? LocalizableStrings.hours_24 : LocalizableStrings.never), valueColor: UIColor.white))
            return cell
        case 4:
            var name = LocalizableStrings.none
            var color = UIColor.main.steelGrey
            
            if let category = AppModel.sharedManager().findCategory(byId: address.category) {
                name = category.name
                color = UIColor.init(hexString: category.color)
            }
     
            let cell = tableView
                .dequeueReusableCell(withType: BMDetailCell.self, for: indexPath)
                .configured(with: (title: LocalizableStrings.category.uppercased(), value: name, valueColor: color))
            return cell
        case 2:
            let cell = tableView
                .dequeueReusableCell(withType: BMFieldCell.self, for: indexPath)
                .configured(with: (name: LocalizableStrings.name.uppercased(), value: address.label, rightIcon:nil))
            cell.delegate = self
            cell.contentView.backgroundColor = UIColor.main.marineTwo.withAlphaComponent(0.35)
            return cell
        case 5:
            let cell = tableView
                .dequeueReusableCell(withType: BMExpandCell.self, for: indexPath)
                .configured(with: (expand: showAdvanced, title: LocalizableStrings.advanced.uppercased()))
            cell.delegate = self
            return cell
        case 6:
            let cell = tableView
                .dequeueReusableCell(withType: BMAmountCell.self, for: indexPath).configured(with: (name: LocalizableStrings.request_amount   , value: amount))
            cell.delegate = self
            cell.contentView.backgroundColor = UIColor.main.marineTwo.withAlphaComponent(0.35)
            return cell
        case 7:
            let cell = tableView
                .dequeueReusableCell(withType: ReceiveAddressButtonsCell.self, for: indexPath)
            cell.delegate = self
            return cell
        default:
            return BaseCell()
        }
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let view = UIView()
        switch section {
        case 2, 3, 4, 5, 6:
            view.backgroundColor = UIColor.main.marineTwo.withAlphaComponent(0.35)
        default:
            view.backgroundColor = UIColor.clear
        }

        return view
    }
}

extension ReceiveViewController : BMCellProtocol {
    
    func textValueDidBegin(_ sender: UITableViewCell) {
        if let path = tableView.indexPath(for: sender)  {
            tableView.scrollToRow(at: path, at: .middle, animated: true)
        }
    }
    
    func textValueDidChange(_ sender: UITableViewCell, _ text: String, _ input:Bool) {
        if sender is BMFieldCell {
            address.label = text
        }
        else if sender is BMAmountCell {
            amount = text
        }
    }
    
    func textValueDidReturn(_ sender: UITableViewCell) {
        if sender is BMFieldCell {
            AppModel.sharedManager().setWalletComment(address.label, toAddress: address.walletId)
        }
    }
    
    func onExpandCell(_ sender: UITableViewCell) {
        if let path = tableView.indexPath(for: sender)
        {
            if path.section == 1 {
                showEdit = !showEdit
                
                if showEdit {
                    self.tableView.insertRows(at: [IndexPath(row: 0, section: 2), IndexPath(row: 0, section: 3), IndexPath(row: 0, section: 4)], with: .fade)
                }
                else{
                    self.tableView.deleteRows(at: [IndexPath(row: 0, section: 2), IndexPath(row: 0, section: 3), IndexPath(row: 0, section: 4)], with: .fade)
                }
            }
            else{
                showAdvanced = !showAdvanced

                if showAdvanced {
                    self.tableView.insertRows(at: [IndexPath(row: 0, section: 6)], with: .fade)
                }
                else{
                    self.tableView.deleteRows(at: [IndexPath(row: 0, section: 6)], with: .fade)
                }
            }
        }
    }
    
    func onRightButton(_ sender: UITableViewCell) {
        let vc = ReceiveListViewController()
        vc.completion = {[weak self]
            obj in
            
            if let add = self?.address {
             
                if (self?.pickedAddress == nil && self?.isShared == false)
                {
                    AppModel.sharedManager().deleteAddress(add.walletId)
                }
                
                self?.isShared = false
                
                self?.pickedAddress = BMAddress()
                self?.pickedAddress?.label = obj.label
                self?.pickedAddress?.category = obj.category
                self?.pickedAddress?.walletId = obj.walletId

                self?.address = obj
                self?.tableView.reloadData()
            }
        }
        pushViewController(vc: vc)
    }
    
    func onClickQRCode() {
        self.isShared = true
        
        self.view.endEditing(true)

        let modalViewController = QRViewController(address: address, amount: amount)
        modalViewController.delegate = self
        modalViewController.modalPresentationStyle = .overFullScreen
        modalViewController.modalTransitionStyle = .crossDissolve
        present(modalViewController, animated: true, completion: nil)
    }
    
    func onClickShare() {
        self.view.endEditing(true)

        let vc = UIActivityViewController(activityItems: [address.walletId ?? String.empty()], applicationActivities: [])
        vc.completionWithItemsHandler = {(activityType: UIActivity.ActivityType?, completed: Bool, returnedItems: [Any]?, error: Error?) in
            if completed {
                self.isShared = true
                
                if activityType == UIActivity.ActivityType.copyToPasteboard {
                    ShowCopied()
                }
                
                self.navigationController?.popViewController(animated: true)
            }
        }
        vc.excludedActivityTypes = [UIActivity.ActivityType.assignToContact, UIActivity.ActivityType.print,UIActivity.ActivityType.openInIBooks]
        present(vc, animated: true)
    }
}

extension ReceiveViewController : QRViewControllerDelegate {
    func onCopyDone() {
        self.isShared = true

        self.navigationController?.popViewController(animated: true)
    }
}
