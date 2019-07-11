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

    private let viewModel = ReceiveAddressViewModel()
    
    private var showAdvanced = false
    private var showEdit = false

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
        
        title = Localizable.shared.strings.receive.uppercased()
        
        tableView.register([BMFieldCell.self, ReceiveAddressButtonsCell.self, BMAmountCell.self, BMExpandCell.self, BMPickedAddressCell.self, BMDetailCell.self])
        tableView.keyboardDismissMode = .interactive
        
        viewModel.onDataChanged = { [weak self] in
            self?.tableView.reloadData()
        }
        
        viewModel.onShared = { [weak self] in
            self?.back()
        }
        
        viewModel.onAddressCreated = {[weak self]
            error in
            
            if let reason = error?.localizedDescription {
                self?.alert(title: Localizable.shared.strings.error, message: reason, handler: { (_ ) in
                    self?.back()
                })
            }
            else{
                self?.tableView.delegate = self
                self?.tableView.dataSource = self
                self?.tableView.reloadData()
            }
        }
        viewModel.createAddress()
        
        addCustomBackButton(target: self, selector: #selector(onBack))
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        self.view.endEditing(true)
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        
        if isMovingFromParent {
            viewModel.revertChanges()
        }
    }
    
    @objc private func onBack() {
        let state = viewModel.isNeedAskToSave()
        if state != .none {
            self.confirmAlert(title: state == .new ? Localizable.shared.strings.save_address_title : Localizable.shared.strings.save_changes, message: state == .new ? Localizable.shared.strings.save_address_text : Localizable.shared.strings.save_edit_address_text, cancelTitle: Localizable.shared.strings.not_save, confirmTitle: Localizable.shared.strings.save, cancelHandler: { [weak self] (_ ) in
                self?.back()
            }) { [weak self] (_ ) in
                self?.viewModel.isShared = true
                self?.back()
            }
        }
        else{
            back()
        }
    }
}

extension ReceiveViewController : UITableViewDelegate {

    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        switch section {
        case 0:
            return 0
        case 1:
            return 5
        case 3:
            return showAdvanced ? 15 : 5
        default:
            return 20
        }
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        switch section {
        case 0:
            return 0
        case 1, 3:
            return 5
        case 2:
            return 20
        case 4:
            return 20
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
        case 1:
            if indexPath.row == 2 {
                viewModel.onExpire()
            }
            else if indexPath.row == 3 {
                viewModel.onCategory()
            }
        default:
            return
        }
    }
}

extension ReceiveViewController : UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 5
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 1 {
            return showEdit ? 4 : 1
        }
        else if section == 3 {
            return showAdvanced ? 2 : 1
        }
        return 1
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
       
        switch indexPath.section {
        case 0:
            var title = viewModel.pickedAddress == nil ? Localizable.shared.strings.auto_address : Localizable.shared.strings.address.uppercased()
            if viewModel.pickedAddress != nil {
                if viewModel.pickedAddress?.walletId == viewModel.startedAddress?.walletId {
                    title = Localizable.shared.strings.auto_address
                }
            }
            let cell = tableView
                .dequeueReusableCell(withType: BMPickedAddressCell.self, for: indexPath)
                .configured(with: (hideLine: true, address: viewModel.address, title: title))
            cell.delegate = self
            cell.contentView.backgroundColor = UIColor.main.marineThree
            return cell
        case 1:
            if indexPath.row == 0 {
                let cell = tableView
                    .dequeueReusableCell(withType: BMExpandCell.self, for: indexPath)
                    .configured(with: (expand: showEdit, title: Localizable.shared.strings.edit_address.uppercased()))
                cell.delegate = self
                return cell
            }
            else if indexPath.row == 1 {
                let cell = tableView
                    .dequeueReusableCell(withType: BMFieldCell.self, for: indexPath)
                    .configured(with: (name: Localizable.shared.strings.name.uppercased(), value: viewModel.address.label, rightIcon:nil))
                cell.delegate = self
                cell.contentView.backgroundColor = UIColor.main.marineThree
                return cell
            }
            else if indexPath.row == 2 {
                let cell = tableView
                    .dequeueReusableCell(withType: BMDetailCell.self, for: indexPath)
                    .configured(with: (title: Localizable.shared.strings.expires.uppercased(), value: (viewModel.address.duration > 0 ? Localizable.shared.strings.hours_24 : Localizable.shared.strings.never), valueColor: UIColor.white))
                cell.space = 20
                return cell
            }
            else{
                let cell = tableView
                    .dequeueReusableCell(withType: BMDetailCell.self, for: indexPath)
                cell.simpleConfigure(with: (title: Localizable.shared.strings.category.uppercased(), attributedValue: viewModel.address.categoriesName()))
                cell.space = 20
                return cell
            }
        case 2:
            let cell = tableView
                .dequeueReusableCell(withType: BMFieldCell.self, for: indexPath)
                .configured(with: (name: Localizable.shared.strings.transaction_comment, value: viewModel.transactionComment, rightIcon:nil))
            cell.delegate = self
            cell.contentView.backgroundColor = UIColor.clear
            return cell
        case 3:
            if indexPath.row == 0 {
                let cell = tableView
                    .dequeueReusableCell(withType: BMExpandCell.self, for: indexPath)
                    .configured(with: (expand: showAdvanced, title: Localizable.shared.strings.advanced.uppercased()))
                cell.delegate = self
                return cell
            }
            else  {
                let cell = tableView
                    .dequeueReusableCell(withType: BMAmountCell.self, for: indexPath).configured(with: (name: Localizable.shared.strings.request_amount, value: viewModel.amount))
                cell.delegate = self
                cell.contentView.backgroundColor = UIColor.main.marineThree
                return cell
            }
        case 4:
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
        case 1, 3:
            view.backgroundColor = UIColor.main.marineThree
        default:
            view.backgroundColor = UIColor.clear
        }

        return view
    }
    
    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        let view = UIView()
        switch section {
        case 1, 3:
            view.backgroundColor = UIColor.main.marineThree
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
        if let path = tableView.indexPath(for: sender) {
            if path.section == 1 {
                viewModel.address.label = text
            }
            else if path.section == 2 {
                viewModel.transactionComment = text
            }
            else if path.section == 3 {
                viewModel.amount = text
            }
        }
    }
    
    func textValueDidReturn(_ sender: UITableViewCell) {
        if let path = tableView.indexPath(for: sender) {
            if path.section == 1 {
                AppModel.sharedManager().setWalletComment(viewModel.address.label, toAddress: viewModel.address.walletId)
            }
        }
    }
    
    func onExpandCell(_ sender: UITableViewCell) {
        if let path = tableView.indexPath(for: sender)
        {
            if path.section == 1 {
                showEdit = !showEdit
                
                if showEdit {
                    self.tableView.insertRows(at: [IndexPath(row: 1, section: 1), IndexPath(row: 2, section: 1), IndexPath(row: 3, section: 1)], with: .fade)
                }
                else{
                    self.tableView.deleteRows(at: [IndexPath(row: 1, section: 1), IndexPath(row: 2, section: 1), IndexPath(row: 3, section: 1)], with: .fade)
                }
            }
            else{
                showAdvanced = !showAdvanced

                if showAdvanced {
                    self.tableView.insertRows(at: [IndexPath(row: 1, section: 3)], with: .fade)
                }
                else{
                    self.tableView.deleteRows(at: [IndexPath(row: 1, section: 3)], with: .fade)
                }
            }
        }
    }
    
    func onRightButton(_ sender: UITableViewCell) {
        self.view.endEditing(true)

        viewModel.onChangeAddress()
    }
    
    func onClickQRCode() {
        self.view.endEditing(true)

        viewModel.onQRCode()
    }
    
    func onClickShare() {
        self.view.endEditing(true)
        
        viewModel.onShare()
    }
    
    func onClickCopy() {
        self.view.endEditing(true)

        viewModel.isShared = true
    }
}
