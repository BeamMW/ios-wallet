//
// SaveContactViewController.swift
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

class SaveContactViewController: BaseTableViewController {

    private var addressError:String?
    
    private var address:BMAddress!
    private var isAddContact = false
    private var copyAddress:String?
    
    private lazy var footerView: UIView = {
        let view = UIView(frame: CGRect(x: 0, y: 0, width: UIScreen.main.bounds.size.width, height: 110))
        
        let mainView = UIView(frame: CGRect(x: (UIScreen.main.bounds.size.width-(Device.isLarge ? 320 : 300))/2, y: 60, width: (Device.isLarge ? 320 : 300), height: 44))
        
        let buttonCancel = BMButton.defaultButton(frame: CGRect(x:0, y: 0, width: 143, height: 44), color: UIColor.main.marineThree)
        buttonCancel.setImage(IconCancel(), for: .normal)
        buttonCancel.setTitle((isAddContact ? Localizable.shared.strings.cancel.lowercased() : Localizable.shared.strings.not_save.lowercased()), for: .normal)
        buttonCancel.setTitleColor(UIColor.white, for: .normal)
        buttonCancel.setTitleColor(UIColor.white.withAlphaComponent(0.5), for: .highlighted)
        buttonCancel.addTarget(self, action: #selector(onBack), for: .touchUpInside)
        mainView.addSubview(buttonCancel)
        
        let buttonSave = BMButton.defaultButton(frame: CGRect(x: mainView.frame.size.width - 143, y: 0, width: 143, height: 44), color: (self.isAddContact ? UIColor.main.brightTeal : UIColor.main.heliotrope))
        buttonSave.setImage(IconDoneBlue(), for: .normal)
        buttonSave.setTitle(Localizable.shared.strings.save.lowercased(), for: .normal)
        buttonSave.setTitleColor(UIColor.main.marineOriginal, for: .normal)
        buttonSave.setTitleColor(UIColor.main.marineOriginal.withAlphaComponent(0.5), for: .highlighted)
        buttonSave.addTarget(self, action: #selector(onSave), for: .touchUpInside)
        mainView.addSubview(buttonSave)
        
        view.addSubview(mainView)
        
        return view
    }()
    
    init(address:String?) {
        super.init(nibName: nil, bundle: nil)
        
        self.address = BMAddress.empty()
        if address != nil {
            self.address.walletId = address!
        }
        else{
            self.isAddContact = true
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError(Localizable.shared.strings.fatalInitCoderError)
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setGradientTopBar(mainColor: isGradient ? UIColor.main.heliotrope : UIColor.main.peacockBlue, addedStatusView: isAddContact)

        title = address.walletId.isEmpty ? Localizable.shared.strings.add_contact.uppercased() : Localizable.shared.strings.save_address_title.uppercased()
        
        tableView.register([BMFieldCell.self, BMMultiLinesCell.self, BMDetailCell.self, BMSearchAddressCell.self])
        
        addCustomBackButton(target: self, selector: #selector(onBack))

        tableView.delegate = self
        tableView.dataSource = self
        tableView.keyboardDismissMode = .interactive
        tableView.tableFooterView = footerView        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        if isAddContact {
            if let address = UIPasteboard.general.string {
                if AppModel.sharedManager().isValidAddress(address)
                {
                    if let cell = tableView.findCell(BMSearchAddressCell.self) as? BMSearchAddressCell {
                        copyAddress = address
                        cell.beginEditing(text: copyAddress)
                    }
                }
            }
        }
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        if isAddContact {
            tableView.y = tableView.y + 25
            tableView.h = tableView.h - 25
        }
    }
    
    @objc private func onSave() {
        if isAddContact {
            if !AppModel.sharedManager().isValidAddress(address.walletId) {
                addressError = Localizable.shared.strings.incorrect_address
                tableView.reloadData()
                return
            }
            
            let isContactFound = (AppModel.sharedManager().getContactFromId(address.walletId) != nil)
            let isMyAddress = AppModel.sharedManager().isMyAddress(address.walletId)
            
            if isContactFound {
                alert(title: Localizable.shared.strings.error, message: Localizable.shared.strings.address_already_exist_1, handler: nil)
                return;
            }
            
            if isMyAddress {
                alert(title: Localizable.shared.strings.error, message: Localizable.shared.strings.address_already_exist_2, handler: nil)
                return;
            }
        }
        
        AppModel.sharedManager().addContact(address.walletId, name: address.label, categories: address.categories as! [Any])
        
        goBack()
    }
    
    @objc private func onBack() {
        if self.isAddContact == false {
            for tr in AppModel.sharedManager().preparedTransactions as! [BMPreparedTransaction] {
                tr.saveContact = false
            }
            AppModel.sharedManager().deleteAddress(address.walletId)
        }
        
        goBack()
    }
    
    @objc private func goBack() {
        if let viewControllers = self.navigationController?.viewControllers{
            for vc in viewControllers {
                if vc is WalletViewController {
                    self.navigationController?.popToViewController(vc, animated: true)
                    return
                }
                else if vc is AddressViewController {
                    self.navigationController?.popToViewController(vc, animated: true)
                    return
                }
            }
        }
        
        self.navigationController?.popToRootViewController(animated: true)
    }
}

extension SaveContactViewController : UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let view = UIView()
        view.backgroundColor = UIColor.clear
        return view
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        switch section {
        case 0:
            return 10
        case 2:
            return 40
        default:
            return 30
        }
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        if indexPath.section == 2 {
            if AppModel.sharedManager().categories.count == 0 {
                let vc = CategoryEditViewController(category: nil)
                vc.completion = {[weak self]
                    obj in
                    guard let strongSelf = self else { return }
                    if let category = obj {
                        strongSelf.address.categories = [String(category.id)]
                        strongSelf.tableView.reloadData()
                    }
                }
                pushViewController(vc: vc)
            }
            else{
                let vc = BMDataPickerViewController(type: .category, selectedValue: self.address.categories as? [String])
                vc.completion = {[weak self]
                    obj in
                    guard let strongSelf = self else { return }
                    
                    if let categories = (obj as? [String]) {
                        strongSelf.address.categories = NSMutableArray(array: categories)
                        strongSelf.tableView.reloadData()
                    }
                }
                pushViewController(vc: vc)
            }
        }
    }
}

extension SaveContactViewController : UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 3
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        switch indexPath.section {
        case 0:
            if isAddContact {
                let cell = tableView
                    .dequeueReusableCell(withType: BMSearchAddressCell.self, for: indexPath)
                cell.delegate = self
                cell.error = addressError
                cell.contact = nil
                cell.configure(with: (name: Localizable.shared.strings.address.uppercased(), value: address.walletId, rightIcon: nil))
                cell.backgroundColor = UIColor.clear
                cell.contentView.backgroundColor = UIColor.clear
                cell.copyText = copyAddress
                cell.validateAddress = true
                return cell
            }
            else{
                let item = BMMultiLineItem(title: Localizable.shared.strings.address.uppercased(), detail: self.address.walletId, detailFont: RegularFont(size: 16), detailColor: UIColor.white)
                let cell =  tableView
                    .dequeueReusableCell(withType: BMMultiLinesCell.self, for: indexPath)
                    .configured(with: item)
                return cell
            }
        case 1:
            let cell = tableView
                .dequeueReusableCell(withType: BMFieldCell.self, for: indexPath)
                .configured(with: (name: Localizable.shared.strings.name.uppercased(), value: self.address.label))
            cell.delegate = self
            return cell
        case 2:
            let cell = tableView
                .dequeueReusableCell(withType: BMDetailCell.self, for: indexPath)
            cell.simpleConfigure(with: (title: Localizable.shared.strings.category.uppercased(), attributedValue: self.address.categoriesName()))
            cell.contentView.backgroundColor = UIColor.clear
            return cell
        default:
            return BaseCell()
        }
    }
}

extension SaveContactViewController : BMCellProtocol {
    
    func textValueDidReturn(_ sender: UITableViewCell) {
        if let path = tableView.indexPath(for: sender)  {
            if path.section == 0 {
                if !address.walletId.isEmpty {
                    if !AppModel.sharedManager().isValidAddress(address.walletId) {
                        addressError = Localizable.shared.strings.incorrect_address
                    }
                }
                
                tableView.reloadRows(at: [path], with: .none)
            }
        }
    }
    
    func textValueDidBegin(_ sender: UITableViewCell) {
        if let path = tableView.indexPath(for: sender)  {
            tableView.scrollToRow(at: path, at: .middle, animated: true)
        }
    }
    
    func textValueDidChange(_ sender: UITableViewCell, _ text: String, _ input:Bool) {
        
        if let path = tableView.indexPath(for: sender)  {
            if path.section == 0 {
                self.addressError = nil
                
                self.address.walletId = text
            }
            else{
                self.address.label = text
            }
        }
        
        UIView.performWithoutAnimation {
            tableView.beginUpdates()
            tableView.endUpdates()
        }
    }
    
    func onRightButton(_ sender: UITableViewCell) {
        if let path = tableView.indexPath(for: sender) {
            if path.section == 0 {
                let vc = QRScannerViewController()
                vc.delegate = self
                pushViewController(vc: vc)
            }
        }
    }
}

extension SaveContactViewController : QRScannerViewControllerDelegate
{
    func didScanQRCode(value:String, amount:String?, privacy: Bool?) {
        addressError = nil
        address.walletId = value
        tableView.reloadData()
    }
}
