//
// ReceiveNewAddressViewController.swift
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

class ReceiveNewAddressViewController: BaseTableViewController {

    private var address:BMAddress!
    
    init(address:BMAddress) {
        super.init(nibName: nil, bundle: nil)
        
        self.address = address
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError(LocalizableStrings.fatalInitCoderError)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.hidesBackButton = true
        
        largeTitle = LocalizableStrings.create_address.uppercased()
        
        tableView.register([ReceiveAddressCell.self, ReceiveAddressCommentCell.self, ReceiveCategoryCell.self, ReceiveExpireCell.self, ReceiveCreateCell.self])
        tableView.delegate = self
        tableView.dataSource = self
        tableView.keyboardDismissMode = .interactive
        
        addLeftButton(image: IconBack())
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
    
    private func onExpire() {
        let vc = AddressExpiresPickerViewController(duration: -1)
        vc.completion = {
            obj in
            
              self.address.duration = obj == 24 ? 86400 : 0
            
            AppModel.sharedManager().setExpires(Int32(obj), toAddress: self.address.walletId)
            
            self.tableView.reloadRow(ReceiveExpireCell.self)
        }
        pushViewController(vc: vc)
    }
    
    private func onCategory() {
        if AppModel.sharedManager().categories.count == 0 {
            
            let vc = CategoryEditViewController(category: nil)
            vc.completion = {
                obj in
                if let category = obj {
                    self.didSelectCategory(category: category)
                }
            }
            pushViewController(vc: vc)
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
        
        tableView.reloadRow(ReceiveCategoryCell.self)
    }
}

extension ReceiveNewAddressViewController : UITableViewDelegate {
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        self.didEndScroll(scrollView: scrollView)
    }
    
    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        self.didEndScroll(scrollView: scrollView)
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        self.didScroll(scrollView: scrollView)
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        switch section {
        case 0:
            return 0
        default:
            return 40
        }
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        switch indexPath.section {
        case 1:
            self.onExpire()
        case 2:
            self.onCategory()
        default:
            return
        }
    }
}

extension ReceiveNewAddressViewController : UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 5
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        switch indexPath.section {
        case 0:
            let cell = tableView
                .dequeueReusableCell(withType: ReceiveAddressCell.self, for: indexPath)
                .configured(with: (hideLine: true, address: address, title:LocalizableStrings.new_address.uppercased()))
            return cell
        case 1:
            let cell = tableView
                .dequeueReusableCell(withType: ReceiveExpireCell.self, for: indexPath)
                .configured(with: address)
            return cell
        case 2:
            let cell = tableView
                .dequeueReusableCell(withType: ReceiveCategoryCell.self, for: indexPath)
                .configured(with: address)
            return cell
        case 3:
            let cell = tableView
                .dequeueReusableCell(withType: ReceiveAddressCommentCell.self, for: indexPath)
                .configured(with: address)
            cell.delegate = self
            return cell
        case 4:
            let cell = tableView
                .dequeueReusableCell(withType: ReceiveCreateCell.self, for: indexPath)
            cell.delegate = self
            return cell
        default:
            return BaseCell()
        }
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let view = UIView()
        view.backgroundColor = UIColor.clear
        return view
    }
}

extension ReceiveNewAddressViewController : ReceiveCellProtocol {
    
    func textValueDidBegin(_ sender: UITableViewCell) {
        if let path = tableView.indexPath(for: sender)  {
            tableView.scrollToRow(at: path, at: .middle, animated: true)
        }
    }
    
    func textValueDidChange(_ sender: UITableViewCell, _ text: String) {
        if sender is ReceiveAddressCommentCell {
            address.label = text
        }
    }
    
    func textValueDidReturn(_ sender: UITableViewCell) {
        if sender is ReceiveAddressCommentCell {
            AppModel.sharedManager().setWalletComment(address.label, toAddress: address.walletId)
        }
    }
    
    func onConfirmCreate() {
        let vc = ReceiveDetailViewController(address: address)
        pushViewController(vc: vc)
    }
    
    func onCancelCreate() {
        AppModel.sharedManager().deleteAddress(address.walletId)
        
        navigationController?.popViewController(animated: true)
    }
}

// MARK: Keyboard Handling

extension ReceiveNewAddressViewController {
    
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


