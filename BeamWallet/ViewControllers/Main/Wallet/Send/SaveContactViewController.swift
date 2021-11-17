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
    private var isAddContact = true
    private var copyAddress:String?
    
    public var isFromSendScreen = false
    
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
            self.isAddContact = false

            if(AppModel.sharedManager().isToken(address!)) {
                let params = AppModel.sharedManager().getTransactionParameters(address!)
                self.address.walletId = address!//params.address
                self.address.identity = params.identity
                self.address.address = address
            }
            else {
                self.address.walletId = address!
            }
            
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
        
        if isAddContact && !isFromSendScreen {
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
    }
    
    @objc private func onSave() {
        var walletId = address.walletId
        var shouldSaveToken = false
        let token = address.address
        
        if(token?.isEmpty == false) {
            shouldSaveToken = true
            walletId = token!
        }
        else if(AppModel.sharedManager().isToken(address.walletId)) {
            walletId = address.walletId
            shouldSaveToken = true
        }
        
        if isAddContact {            
            if !AppModel.sharedManager().isValidAddress(walletId) {
                addressError = Localizable.shared.strings.incorrect_address
                tableView.reloadData()
                return
            }
            
            let isContactFound = (AppModel.sharedManager().getContactFromId(walletId) != nil)
            let isMyAddress = AppModel.sharedManager().isMyAddress(walletId, identity: address.identity)
            
            if isContactFound {
                alert(title: Localizable.shared.strings.error, message: Localizable.shared.strings.address_already_exist_1, handler: nil)
                return;
            }
            
            if isMyAddress {
                alert(title: Localizable.shared.strings.error, message: Localizable.shared.strings.address_already_exist_2, handler: nil)
                return;
            }
        }
        
        AppModel.sharedManager().addContact(walletId, address: shouldSaveToken ? walletId : nil, name: address.label, identidy: address.identity)
        
        goBack()
    }
    
    @objc private func onBack() {
        if self.isFromSendScreen {
            onSave()
            let token = address.address ?? address._id
            AppModel.sharedManager().addIgnoredContact(token)
        }
        else {
            goBack()
        }
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
        return 0
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
}

extension SaveContactViewController : UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        switch indexPath.section {
        case 0:
            if isAddContact {
                let trim = self.address.walletId.count > 0 ? "\(self.address.walletId.prefix(6))...\(self.address.walletId.suffix(6))" : "";

                let cell = tableView
                    .dequeueReusableCell(withType: BMSearchAddressCell.self, for: indexPath)
                cell.delegate = self
                cell.contact = nil
                cell.configure(with: (name: Localizable.shared.strings.address.uppercased(), value: trim, rightIcons: isFromSendScreen ? nil : [IconScanQr()]))
                cell.backgroundColor = UIColor.clear
                cell.contentView.backgroundColor = UIColor.clear
                cell.copyText = copyAddress
                cell.validateAddress = true
                cell.error = addressError
                return cell
            }
            else{
                let trim = "\(self.address.walletId.prefix(6))...\(self.address.walletId.suffix(6))";

                let item = BMMultiLineItem(title: Localizable.shared.strings.address.uppercased(), detail: trim, detailFont: RegularFont(size: 16), detailColor: UIColor.white)
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
    func didScanQRCode(value:String, amount:String?, privacy: Bool?, offline: Bool?) {
        addressError = nil
        address.walletId = value
        tableView.reloadData()
    }
}
