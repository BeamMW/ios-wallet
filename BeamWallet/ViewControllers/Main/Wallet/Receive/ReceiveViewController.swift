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

    init(address:BMAddress) {
        super.init(nibName: nil, bundle: nil)
        
        self.address = address
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError(LocalizableStrings.fatalInitCoderError)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setGradientTopBar(image: GradientBlue())
        attributedTitle = LocalizableStrings.receive.uppercased()
        
        tableView.register([ReceiveFieldCell.self, ReceiveAddressButtonsCell.self, ReceiveAmountCell.self, ReceiveExpandCell.self, ReceiveAddressCell.self, ReceiveDetailCell.self])

        tableView.delegate = self
        tableView.dataSource = self
        tableView.keyboardDismissMode = .interactive
        
        self.sideMenuController?.isLeftViewSwipeGestureEnabled = false
    }
    
    override func viewDidLayoutSubviews() {
        
        tableView.frame = CGRect(x: 0, y: 150, width: self.view.bounds.width, height: self.view.bounds.size.height - 150)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        self.navigationController?.isNavigationBarHidden = true

        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: UIResponder.keyboardWillHideNotification, object: nil)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        self.navigationController?.isNavigationBarHidden = false

        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillShowNotification , object: nil)
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillHideNotification , object: nil)
    }
    
    private func onExpire() {
        let vc = AddressExpiresPickerViewController(duration: -1)
        vc.completion = {
            obj in
            
            self.address.duration = obj == 24 ? 86400 : 0
            
            AppModel.sharedManager().setExpires(Int32(obj), toAddress: self.address.walletId)
            
            self.tableView.reloadRows(at: [IndexPath(row: 0, section: 2)], with: .fade)
        }
        pushViewController(vc: vc)
    }
    
    private func onCategory() {
        if AppModel.sharedManager().categories.count == 0 {
            self.alert(title: LocalizableStrings.categories_empty_title, message: LocalizableStrings.categories_empty_text, handler: nil)
        }
        else{
            let vc  = CategoryPickerViewController(category: AppModel.sharedManager().findCategory(byId: self.address.category))
            vc.completion = {
                obj in
                if let category = obj {
                    self.didSelectCategory(category: category)
                }
            }
            pushViewController(vc: vc)
        }
    }
    
    private func didSelectCategory(category:BMCategory) {
        address.category = String(category.id)
        
        AppModel.sharedManager().setWalletCategory(self.address.category, toAddress: address.walletId)
        
        tableView.reloadRows(at: [IndexPath(row: 0, section: 3)], with: .fade)
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
        case 2:
            self.onExpire()
        case 3:
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
                .dequeueReusableCell(withType: ReceiveExpandCell.self, for: indexPath)
                .configured(with: (expand: showEdit, title: LocalizableStrings.edit_address.uppercased()))
            cell.delegate = self
            return cell
        case 2:
            let cell = tableView
                .dequeueReusableCell(withType: ReceiveDetailCell.self, for: indexPath)
                .configured(with: (title: LocalizableStrings.expires.uppercased(), value: (address.duration > 0 ? LocalizableStrings.hours_24 : LocalizableStrings.never), valueColor: UIColor.white))
            return cell
        case 3:
            var name = LocalizableStrings.none
            var color = UIColor.main.steelGrey
            
            if let category = AppModel.sharedManager().findCategory(byId: address.category) {
                name = category.name
                color = UIColor.init(hexString: category.color)
            }
     
            let cell = tableView
                .dequeueReusableCell(withType: ReceiveDetailCell.self, for: indexPath)
                .configured(with: (title: LocalizableStrings.category.uppercased(), value: name, valueColor: color))
            return cell
        case 4:
            let cell = tableView
                .dequeueReusableCell(withType: ReceiveFieldCell.self, for: indexPath)
                .configured(with: (name: LocalizableStrings.local_annotation_not_shared, value: address.label))
            cell.delegate = self
            return cell
        case 5:
            let cell = tableView
                .dequeueReusableCell(withType: ReceiveExpandCell.self, for: indexPath)
                .configured(with: (expand: showAdvanced, title: LocalizableStrings.advanced.uppercased()))
            cell.delegate = self
            return cell
        case 6:
            let cell = tableView
                .dequeueReusableCell(withType: ReceiveAmountCell.self, for: indexPath).configured(with: amount)
            cell.delegate = self
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
        view.backgroundColor = section > 0 ? UIColor.clear : UIColor.main.marineTwo.withAlphaComponent(0.2)
        return view
    }
}

extension ReceiveViewController : ReceiveCellProtocol {
    
    func textValueDidBegin(_ sender: UITableViewCell) {
        if let path = tableView.indexPath(for: sender)  {
            tableView.scrollToRow(at: path, at: .middle, animated: true)
        }
    }
    
    func textValueDidChange(_ sender: UITableViewCell, _ text: String) {
        if sender is ReceiveFieldCell {
            address.label = text
        }
        else if sender is ReceiveAmountCell {
            amount = text
        }
    }
    
    func textValueDidReturn(_ sender: UITableViewCell) {
        if sender is ReceiveFieldCell {
            AppModel.sharedManager().setWalletComment(address.label, toAddress: address.walletId)
        }
    }
    
    func onExpandRecieveAddress(_ sender: UITableViewCell) {
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
    
    func onChangeAddress() {
        let vc = ReceiveListViewController()
        vc.completion = {
            obj in
            
            if ((self.address.category.isEmpty || self.address.category == LocalizableStrings.zero) && self.address.label.isEmpty)
            {
                AppModel.sharedManager().deleteAddress(self.address.walletId)
            }
            
            self.address = obj
            self.tableView.reloadData()
        }
        pushViewController(vc: vc)
    }
    
    func onClickQRCode() {
        self.view.endEditing(true)

        let modalViewController = ReceiveQRViewController(address: address, amount: amount)
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

extension ReceiveViewController : ReceiveQRViewControllerDelegate {
    func onCopyDone() {
        self.navigationController?.popViewController(animated: true)
    }
}

// MARK: Keyboard Handling

extension ReceiveViewController {
    
    @objc func keyboardWillShow(_ notification: Notification) {
        if let keyboardFrame: NSValue = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue {
            let keyboardRectangle = keyboardFrame.cgRectValue
            let keyboardHeight = keyboardRectangle.height
            
            tableView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: keyboardHeight, right: 0)
        }
    }
    
    @objc func keyboardWillHide(notification: NSNotification) {
        tableView.contentInset = UIEdgeInsets.zero
    }
}
