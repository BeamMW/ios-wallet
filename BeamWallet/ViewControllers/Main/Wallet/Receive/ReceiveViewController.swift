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
        
        title = LocalizableStrings.receive.uppercased()
        
        tableView.register([BMFieldCell.self, ReceiveAddressButtonsCell.self, BMAmountCell.self, BMExpandCell.self, BMPickedAddressCell.self, BMDetailCell.self])
        tableView.keyboardDismissMode = .interactive
        
        viewModel.onDataChanged = { [weak self] in
            self?.tableView.reloadData()
        }
        
        viewModel.onShared = { [weak self] in
            self?.navigationController?.popViewController(animated: true)
        }
        
        viewModel.onAddressCreated = {[weak self]
            error in
            
            if let reason = error?.localizedDescription {
                self?.alert(title: LocalizableStrings.error, message: reason, handler: { (_ ) in
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

        if isMovingFromParent {
            viewModel.revertChanges()
        }
    }
    
    @objc private func onBack() {
        let state = viewModel.isNeedAskToSave()
        if state != .none {
            self.confirmAlert(title: state == .new ? LocalizableStrings.save_address_title : LocalizableStrings.save_changes, message: state == .new ? LocalizableStrings.save_address_text : LocalizableStrings.save_edit_address_text, cancelTitle: LocalizableStrings.not_save, confirmTitle: LocalizableStrings.save, cancelHandler: { [weak self] (_ ) in
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
            viewModel.onExpire()
        case 4:
            viewModel.onCategory()
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
            var title = viewModel.pickedAddress == nil ? LocalizableStrings.auto_address : LocalizableStrings.address.uppercased()
            if viewModel.pickedAddress != nil {
                if viewModel.pickedAddress?.walletId == viewModel.startedAddress?.walletId {
                    title = LocalizableStrings.auto_address
                }
            }
            let cell = tableView
                .dequeueReusableCell(withType: BMPickedAddressCell.self, for: indexPath)
                .configured(with: (hideLine: true, address: viewModel.address, title: title))
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
                .configured(with: (title: LocalizableStrings.expires.uppercased(), value: (viewModel.address.duration > 0 ? LocalizableStrings.hours_24 : LocalizableStrings.never), valueColor: UIColor.white))
            return cell
        case 4:
            var name = LocalizableStrings.none
            var color = UIColor.main.steelGrey
            
            if let category = AppModel.sharedManager().findCategory(byId: viewModel.address.category) {
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
                .configured(with: (name: LocalizableStrings.name.uppercased(), value: viewModel.address.label, rightIcon:nil))
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
                .dequeueReusableCell(withType: BMAmountCell.self, for: indexPath).configured(with: (name: LocalizableStrings.request_amount, value: viewModel.amount))
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
            viewModel.address.label = text
        }
        else if sender is BMAmountCell {
            viewModel.amount = text
        }
    }
    
    func textValueDidReturn(_ sender: UITableViewCell) {
        if sender is BMFieldCell {
            AppModel.sharedManager().setWalletComment(viewModel.address.label, toAddress: viewModel.address.walletId)
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
}
