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

class EditAddressViewController: BaseTableViewController {
    
    private var viewModel:EditAddressViewModel!
    
    init(address:BMAddress) {
        super.init(nibName: nil, bundle: nil)
        
        self.viewModel = EditAddressViewModel(address: address)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError(Localizables.shared.strings.fatalInitCoderError)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        viewModel.onDataChanged = { [weak self] in
            self?.checkIsChanges()
            self?.tableView.reloadData()
        }
        
        title = (viewModel.isContact ? Localizables.shared.strings.edit_contact : Localizables.shared.strings.edit_address)

        tableView.delegate = self
        tableView.dataSource = self
        tableView.keyboardDismissMode = .interactive
    
        tableView.register([AddressSwitchCell.self, AddressExpiresCell.self,AddressExpiredCell.self, 
            AddressCommentCell.self, AddressCategoryCell.self])

        addRightButton(title:Localizables.shared.strings.save, target: self, selector: #selector(onSave), enabled: false)
    }
    
    @IBAction func onSave(sender : UIBarButtonItem) {
        viewModel.saveChages()
        
        back()
    }
    
    private func checkIsChanges(){
        enableRightButton(enabled: viewModel.checkIsChanges())
    }
}

extension EditAddressViewController : UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        
        if viewModel.isContact {
            if section < 3 {
                return 0
            }
        }
        
        if section == 2 && viewModel.newAddress.isNowActive && viewModel.newAddress.isExpired() {
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
            return viewModel.newAddress.isExpired() ? AddressExpiredCell.height() : AddressExpiresCell.height()
        case 1:
            return AddressSwitchCell.height()
        case 2:
            return (viewModel.newAddress.isNowActive && viewModel.newAddress.isExpired()) ? AddressExpiresCell.height() : 0
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
        
        if (indexPath.section == 0) || (indexPath.section == 2 && viewModel.newAddress.isNowActive && viewModel.newAddress.isExpired()) {
                viewModel.pickExpire()
        }
        else if indexPath.section == 3 {
            viewModel.pickCategory()
        }
    }
}

extension EditAddressViewController : UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 5
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if viewModel.isContact {
            if section < 3 {
                return 0
            }
        }
        return 1
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        if indexPath.section == 0 {
            if viewModel.newAddress.isExpired() {
                let cell = tableView
                    .dequeueReusableCell(withType: AddressExpiredCell.self, for: indexPath)
                    .configured(with: viewModel.newAddress)
                return cell
            }
            else{
                let cell = tableView
                    .dequeueReusableCell(withType: AddressExpiresCell.self, for: indexPath)
                    .configured(with: viewModel.newAddress)
                return cell
            }
        }
        else if indexPath.section == 1 {
            
            let text = viewModel.newAddress.isExpired() ? Localizables.shared.strings.active_address : Localizables.shared.strings.expire_now
            
            let selected = (viewModel.newAddress.isExpired()) ? viewModel.newAddress.isNowActive : viewModel.newAddress.isNowExpired
            
            let cell =  tableView
                .dequeueReusableCell(withType: AddressSwitchCell.self, for: indexPath)
                .configured(with: (text: text, selected: selected))
            cell.delegate = self
            
            return cell
        }
        else if indexPath.section == 2 && viewModel.newAddress.isNowActive && viewModel.newAddress.isExpired() {
            let cell = tableView
                .dequeueReusableCell(withType: AddressExpiresCell.self, for: indexPath)
                .configured(with: viewModel.newAddress)
            return cell
        }
        else if indexPath.section == 3 {
            let cell =  tableView
                .dequeueReusableCell(withType: AddressCategoryCell.self, for: indexPath)
                .configured(with: viewModel.newAddress)
            
            return cell
        }
        else if indexPath.section == 4 {
            let cell =  tableView
                .dequeueReusableCell(withType: AddressCommentCell.self, for: indexPath)
                .configured(with: viewModel.newAddress.label)
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
        if viewModel.newAddress.isExpired() {
            viewModel.newAddress.isNowActive = !viewModel.newAddress.isNowActive
            viewModel.newAddress.isNowExpired = false
        }
        else {
            viewModel.newAddress.isNowExpired = !viewModel.newAddress.isNowExpired
            viewModel.newAddress.isNowActive = false
        }
        
        checkIsChanges()
        
        tableView.reloadData()
    }
}

extension EditAddressViewController : AddressCommentCellDelegate {
    func onChangeComment(value: String) {
        viewModel.newAddress.label = value
        checkIsChanges()
    }
}

extension EditAddressViewController {
    @objc override func keyboardWillShow(_ notification: Notification) {
        super.keyboardWillShow(notification)
        
        tableView.scrollToRow(at: IndexPath(row: 0, section: 4), at: .top, animated: false)
    }
}

