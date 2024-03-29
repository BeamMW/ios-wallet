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
    
    private lazy var mainView = UIView(frame: CGRect(x: (UIScreen.main.bounds.size.width-(Device.isLarge ? 320 : 300))/2, y: 60, width: (Device.isLarge ? 320 : 300), height: 44))
    private lazy var buttonSave = BMButton.defaultButton(frame: CGRect(x: mainView.frame.size.width - 143, y: 0, width: 143, height: 44), color: UIColor.main.brightTeal)

    private lazy var footerView: UIView = {
        let view = UIView(frame: CGRect(x: 0, y: 0, width: UIScreen.main.bounds.size.width, height: 110))
        
        let buttonCancel = BMButton.defaultButton(frame: CGRect(x:0, y: 0, width: 143, height: 44), color: UIColor.main.marineThree)
        buttonCancel.setImage(IconCancel(), for: .normal)
        buttonCancel.setTitle(Localizable.shared.strings.cancel.lowercased(), for: .normal)
        buttonCancel.setTitleColor(UIColor.white, for: .normal)
        buttonCancel.setTitleColor(UIColor.white.withAlphaComponent(0.5), for: .highlighted)
        buttonCancel.addTarget(self, action: #selector(onBack), for: .touchUpInside)
        mainView.addSubview(buttonCancel)
        
        buttonSave.setImage(IconDoneBlue(), for: .normal)
        buttonSave.setTitle(Localizable.shared.strings.save.lowercased(), for: .normal)
        buttonSave.setTitleColor(UIColor.main.marineOriginal, for: .normal)
        buttonSave.setTitleColor(UIColor.main.marineOriginal.withAlphaComponent(0.5), for: .highlighted)
        buttonSave.addTarget(self, action: #selector(onSave), for: .touchUpInside)
        buttonSave.isEnabled = expireChanged || canSave
        mainView.addSubview(buttonSave)

        view.addSubview(mainView)
        
        return view
    }()
    
  
    
    init(address:BMAddress) {
        super.init(nibName: nil, bundle: nil)
        
        self.viewModel = EditAddressViewModel(address: address)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError(Localizable.shared.strings.fatalInitCoderError)
    }
    
    private var addressOptions = [String]()
    private var canExtend = false
    private var canSave = false
    private var expireChanged = false
    private var isNeverExpired = false
    private var hasActiveTransactions = false

    override func viewDidLoad() {
        super.viewDidLoad()
        
        setGradientTopBar(mainColor: UIColor.main.peacockBlue, addedStatusView: true)
        
        viewModel.onDataChanged = { [weak self] in
            self?.tableView.reloadData()
        }
        
        title = (viewModel.isContact ? Localizable.shared.strings.edit_contact : Localizable.shared.strings.edit_address)

        tableView.delegate = self
        tableView.dataSource = self
        tableView.keyboardDismissMode = .interactive
        tableView.tableFooterView = footerView
        
        tableView.register([AddressExpiresCell.self, BMMultiLinesCell.self, BMFieldCell.self, BMDetailCell.self, BMGroupedCell.self])
        
        viewModel.onDataDeleted = { [weak self]
            indexPath, address in
            
            AppModel.sharedManager().prepareDelete(address, removeTransactions: address.isNeedRemoveTransactions)
            
            self?.navigationController?.popViewControllers(viewsToPop: 2)
        }
        
        if viewModel.newAddress.duration == 0 {
            isNeverExpired = true
            canExtend = false
        }
        else if !viewModel.newAddress.isExpired() && viewModel.newAddress.duration != 0 {
            canExtend = true
        }
        
        
        fillAddressOptions()
    }
    
    @objc private func onBack() {
        back()
    }
    
    @objc private func onSave() {
        viewModel.saveChages()
        
        back()
    }
    
    @objc private func fillAddressOptions() {
        hasActiveTransactions = AppModel.sharedManager().hasActiveTransactions(from: self.viewModel.address!)
        
        addressOptions.removeAll()
        
        if canExtend {
            addressOptions.append(Localizable.shared.strings.extend)
        }
        if viewModel.newAddress.isExpired() || viewModel.newAddress.isNowExpired {
            addressOptions.append(Localizable.shared.strings.active_address)
        }
        else if !viewModel.newAddress.isExpired() || viewModel.newAddress.isNowActive {
            addressOptions.append(Localizable.shared.strings.expire_now)
        }
        
        if !hasActiveTransactions {
            addressOptions.append(Localizable.shared.strings.delete_address)
        }
    }
}

extension EditAddressViewController : UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return (section == 2 ? 30 : 0)
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        if (indexPath.section == 0 && indexPath.row == 2) {

        }
        else if indexPath.row == addressOptions.count {

        }
        else if indexPath.section == 2 {
            if viewModel.isContact {
                viewModel.onDeleteAddress(address: viewModel.address!, indexPath: nil)
            }
            else{
                expireChanged = true
                
                let title = addressOptions[indexPath.row]
                
                if title == Localizable.shared.strings.delete_address {
                    viewModel.onDeleteAddress(address: viewModel.address!, indexPath: nil)
                }
                else if title == Localizable.shared.strings.expire_now {
                    canExtend = false
                    
                    viewModel.newAddress.isNowExpired = true
                    viewModel.newAddress.isNowActive = false
                }
                else if title == Localizable.shared.strings.active_address || title == Localizable.shared.strings.extend {
                    canExtend = false

                    if isNeverExpired {
                        viewModel.newAddress.createTime = UInt64(Date().timeIntervalSince1970)
                        viewModel.newAddress.duration = 0
                        viewModel.newAddress.isNowActiveDuration = 0
                        viewModel.newAddress.isNowActive = true
                        viewModel.newAddress.isNowExpired = false
                    }
                    else {
                        viewModel.newAddress.createTime = UInt64(Date().timeIntervalSince1970)
                        viewModel.newAddress.duration = UInt64(Settings.sharedManager().maxAddressDurationSeconds)
                        viewModel.newAddress.isNowActive = true
                        viewModel.newAddress.isNowExpired = false
                    }
                }
                
                buttonSave.isEnabled = expireChanged || canSave

                fillAddressOptions()
                tableView.reloadData()
            }
        }
    }
}

extension EditAddressViewController : UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 3
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            return (viewModel.isContact ? 2 : 3)
        }
        else if section == 2 {
            if viewModel.isContact {
                return 1
            }
            if hasActiveTransactions {
                return addressOptions.count + 1
            }
            return addressOptions.count
        }
        else if section == 1 {
            return 0
        }
        return 1
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        if indexPath.section == 0 {
            switch (indexPath.row) {
            case 0:
                let displayAddress = viewModel.address!.displayAddress ?? viewModel.address!.walletId
                let cell = tableView
                    .dequeueReusableCell(withType: BMMultiLinesCell.self, for: indexPath)
                    .configured(with: BMMultiLineItem(title: Localizable.shared.strings.address.uppercased(), detail:displayAddress, detailFont: RegularFont(size: 16), detailColor: UIColor.white))
                cell.increaseSpace = true
                return cell
            case 1:
                let cell = tableView
                    .dequeueReusableCell(withType: BMFieldCell.self, for: indexPath)
                    .configured(with: (name: Localizable.shared.strings.name.uppercased(), value: viewModel.newAddress!.label))
                cell.delegate = self
                cell.topOffset?.constant = 20
                return cell
            case 2:
                
                var detail = viewModel.newAddress.formattedDate()
                
                if viewModel.newAddress.isExpired() || viewModel.newAddress.isNowExpired {
                    detail = Localizable.shared.strings.this_address_expired
                }
                
                let cell = tableView
                    .dequeueReusableCell(withType: BMMultiLinesCell.self, for: indexPath)
                    .configured(with: BMMultiLineItem(title: Localizable.shared.strings.expires_on.uppercased(), detail:detail, detailFont: RegularFont(size: 16), detailColor: UIColor.white))
                cell.increaseSpace = true
                return cell
            default:
                return BaseCell()
            }
        }
        else if indexPath.section == 2 {
            if viewModel.isContact {
                let cell = tableView
                    .dequeueReusableCell(withType: BMGroupedCell.self, for: indexPath)
                    .configured(with: (text: Localizable.shared.strings.delete_contact, position: BMGroupedCell.BMGroupedCellPosition.one))
                cell.titleColor = UIColor.main.red
                return cell
            }
            else {
                if indexPath.row == addressOptions.count {
                    let cell = UITableViewCell(style: .default, reuseIdentifier: "Cell")
                    cell.textLabel?.textColor = UIColor.white.withAlphaComponent(0.5)
                    cell.textLabel?.text = Localizable.shared.strings.address_expire_active_transaction
                    cell.textLabel?.font = ItalicFont(size: 14)
                    cell.textLabel?.numberOfLines = 0
                    cell.contentView.backgroundColor = .clear
                    cell.backgroundColor = .clear
                    cell.isUserInteractionEnabled = false
                    return cell
                }
                else {
                    var color = UIColor.main.red
                    
                    let title = addressOptions[indexPath.row]
                    
                    if title != Localizable.shared.strings.delete_address
                        && title != Localizable.shared.strings.expire_now {
                        color = UIColor.main.brightTeal
                    }
                    
                    
                    let cell = tableView
                        .dequeueReusableCell(withType: BMGroupedCell.self, for: indexPath)
                        .configured(with: (text: addressOptions[indexPath.row], position: BMGroupedCell.BMGroupedCellPosition.bottom))
                    cell.titleColor = color
                    cell.isUserInteractionEnabled = true
                    
                    if title == Localizable.shared.strings.expire_now {
                        if hasActiveTransactions {
                            cell.isUserInteractionEnabled = false
                            cell.titleColor = color.withAlphaComponent(0.5)
                        }
                    }
                    
                    return cell
                }
            }
        }
        
        let cell = BaseCell()
        return cell
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        return (section == 2 ? UIView() : nil)
    }
}

extension EditAddressViewController : BMCellProtocol {
    func textValueDidChange(_ sender: UITableViewCell, _ text: String, _ input: Bool) {
        viewModel.newAddress.label = text
        
        if viewModel.address?.label != text {
            canSave = true
        }
        
        buttonSave.isEnabled = expireChanged || canSave
    }
}


