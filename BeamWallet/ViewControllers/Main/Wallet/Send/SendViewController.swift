//
// SendViewController.swift
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

class SendViewController: BaseTableViewController {

    private lazy var searchTableView: UITableView = {
        let tableView = UITableView()
        tableView.backgroundColor = UIColor.main.marine
        tableView.separatorStyle = .none
        tableView.delegate = self
        tableView.dataSource = self
        tableView.isHidden = true
        return tableView
    }()
    
    private var isSearch = false {
        didSet {
            tableView.isScrollEnabled = !isSearch
            searchTableView.isHidden = !isSearch
            
            let rect = self.tableView.rectForRow(at: IndexPath(row: 0, section: 0))
            let y:CGFloat = gradientOffset + rect.size.height + 20
            
            searchTableView.frame = CGRect(x: 0, y: y, width: self.view.bounds.width, height: self.view.bounds.size.height - y)

        }
    }
    
    private var copyAddress:String?
    private var onSendAll = false
    private var isFocused = false

    private var showAdvanced = false
    
    private var toAddress:String = String.empty()
    private var amount:String = String.empty()
    private var fee = "10"
    private var comment:String = String.empty()
    private var selectedContact:BMContact?
    
    private var addressError:String?
    private var amountError:String?

    public var transaction: BMTransaction?

    private var contacts = [BMContact]()
    
    private lazy var footerView: UIView = {
       
        let view = UIView(frame: CGRect(x: 0, y: 0, width: UIScreen.main.bounds.size.width, height: 95))
        
        let button = BMButton.defaultButton(frame: CGRect(x: (UIScreen.main.bounds.size.width-143)/2, y: 40, width: 143, height: 44), color: UIColor.main.heliotrope.withAlphaComponent(0.1))
        button.setImage(IconNextPink(), for: .normal)
        button.setTitle(LocalizableStrings.next, for: .normal)
        button.layer.borderWidth = 1
        button.layer.borderColor = UIColor.main.heliotrope.cgColor
        button.setTitleColor(UIColor.main.heliotrope, for: .normal)
        button.addTarget(self, action: #selector(onNext), for: .touchUpInside)
        view.addSubview(button)
        
        return view
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        isGradient = true
        
        setGradientTopBar(mainColor: UIColor.main.heliotrope)
        
        attributedTitle = LocalizableStrings.send.uppercased()
        
        addRightButton(image: Settings.sharedManager().isHideAmounts ? IconShowBalance() : IconHideBalance(), targer: self, selector: #selector(onHideAmounts))

        tableView.register([BMFieldCell.self, SendAllCell.self, BMAmountCell.self, BMExpandCell.self, FeeCell.self, BMDetailCell.self, SearchAddressCell.self, AddressCell.self])
        
        searchTableView.register([ContactCell.self, BMEmptyCell.self])
        searchTableView.keyboardDismissMode = .interactive

        tableView.delegate = self
        tableView.dataSource = self
        tableView.keyboardDismissMode = .interactive
        tableView.tableFooterView = footerView
        
        (self.navigationController as! BaseNavigationController).enableSwipeToDismiss = false
        self.sideMenuController?.isLeftViewSwipeGestureEnabled = false
        
        if let repeatTransaction = transaction {
            toAddress = repeatTransaction.receiverAddress
            amount = String.currency(value: repeatTransaction.realAmount)
            fee = String(repeatTransaction.realFee)
            comment = repeatTransaction.comment
        }
        
        view.addSubview(searchTableView)
        
       // hideKeyboardWhenTappedAround()
    }
    
    override func viewDidLayoutSubviews() {
        tableView.frame = CGRect(x: 0, y: gradientOffset, width: self.view.bounds.width, height: self.view.bounds.size.height - gradientOffset)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        if !isFocused && transaction == nil {
            isFocused = true
            
            if let address = UIPasteboard.general.string {
                if AppModel.sharedManager().isValidAddress(address)
                {
                    copyAddress = address
                    
                    if let cell = tableView.findCell(SearchAddressCell.self) as? SearchAddressCell {
                        cell.beginEditing(text: address)
                    }
                }
            }
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        Settings.sharedManager().addDelegate(self)
        
        self.navigationController?.isNavigationBarHidden = true
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        Settings.sharedManager().removeDelegate(self)

        if isMovingFromParent {
            self.navigationController?.isNavigationBarHidden = false
        }
    }
    
    private func didSelectAddress(value:String) {
        isSearch = false
        toAddress = value
        
        tableView.reloadData()
        
        if amount.isEmpty {
            if let cell = tableView.findCell(BMAmountCell.self) as? BMAmountCell {
                cell.beginEditing()
            }
        }
    }
    
    //MARK: - IBAction

    @objc private func onHideAmounts() {
        
        if !Settings.sharedManager().isHideAmounts {
            if Settings.sharedManager().isAskForHideAmounts {
                
                self.confirmAlert(title: LocalizableStrings.activate_security_title, message: LocalizableStrings.activate_security_text, cancelTitle: LocalizableStrings.cancel, confirmTitle: LocalizableStrings.activate, cancelHandler: { (_ ) in
                    
                }) { (_ ) in
                    Settings.sharedManager().isAskForHideAmounts = false
                    Settings.sharedManager().isHideAmounts = !Settings.sharedManager().isHideAmounts
                }
            }
            else{
                Settings.sharedManager().isHideAmounts = !Settings.sharedManager().isHideAmounts
            }
        }
        else{
            Settings.sharedManager().isHideAmounts = !Settings.sharedManager().isHideAmounts
        }
    }
    
    @objc private func onNext() {
        let _amount = Double(self.amount) ?? 0
        let _fee = Double(self.fee) ?? 0
        
        let valid = AppModel.sharedManager().isValidAddress(toAddress)
        let expired = AppModel.sharedManager().isExpiredAddress(toAddress)
        let canSend = AppModel.sharedManager().canSend(_amount, fee: _fee, to: toAddress)
        let isError = (!valid || expired || canSend != nil)
        
        if isError {
            amountError = nil
            addressError = nil
            
            if !valid {
                addressError = LocalizableStrings.incorrect_address
            }
            else if expired {
                addressError = LocalizableStrings.address_is_expired
            }
            
            if self.amount.isEmpty {
                amountError = LocalizableStrings.amount_empty
            }
            else if canSend != LocalizableStrings.incorrect_address {
                amountError = canSend
            }
            
            tableView.reloadData()
            tableView.scrollToRow(at: IndexPath(row: 0, section: 0), at: .top, animated: false)
        }
        else {
            let vc = SendConfirmViewController(toAddress: toAddress, amount: amount, fee: fee, comment: comment, contact: selectedContact)
            pushViewController(vc: vc)
        }
    }
    
    private func search() {
        if let contacts = AppModel.sharedManager().contacts as? [BMContact] {
            self.contacts = contacts
        }
        
        if !toAddress.isEmpty {
            for contact in self.contacts {
                if let category = AppModel.sharedManager().findCategory(byId: contact.address.category) {
                    contact.address.categoryName = category.name
                }
                else{
                    contact.address.categoryName = String.empty()
                }
            }
            
            let filterdObjects = self.contacts.filter {
                $0.name.lowercased().contains(toAddress.lowercased()) ||
                $0.address.label.lowercased().contains(toAddress.lowercased()) ||
                $0.address.categoryName.lowercased().contains(toAddress.lowercased()) ||
                $0.address.walletId.lowercased().contains(toAddress.lowercased())
            }
            self.contacts.removeAll()
            self.contacts.append(contentsOf: filterdObjects)
        }
        
        self.searchTableView.reloadData()
    }
}

extension SendViewController : UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        
        if tableView == searchTableView {
            let header = BMTableHeaderTitleView.init(title: LocalizableStrings.contacts.uppercased(), bold: true)
            header.letterSpacing = 2
            return header
        }
        
        let view = UIView()
        view.backgroundColor = section == 5 ?  UIColor.main.marineTwo.withAlphaComponent(0.35) : UIColor.clear
        return view
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        
        if tableView == searchTableView {
            return BMTableHeaderTitleView.boldHeight
        }
        
        switch section {
        case 2:
            return Settings.sharedManager().isHideAmounts ? 0 : 30
        case 5:
            return 10
        default:
            return (section > 0 ) ? 30 : 10
        }
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if tableView == searchTableView && contacts.count == 0 {
            return ContactCell.height()
        }
        return UITableView.automaticDimension
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        if tableView == searchTableView && contacts.count > 0 {
            selectedContact = contacts[indexPath.row]
            didSelectAddress(value: contacts[indexPath.row].address.walletId)
        }
    }
}


extension SendViewController : UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        
        if tableView == searchTableView {
            return 1
        }
        
        return (showAdvanced ? 6 : 5)
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        if tableView == searchTableView {
            return contacts.count == 0 ? 1 : contacts.count
        }
        
        switch section {
        case 2:
            return Settings.sharedManager().isHideAmounts ? 0 : 1
        default:
            return 1
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        if tableView == searchTableView {
            if contacts.count == 0 {
                let cell = tableView
                    .dequeueReusableCell(withType: BMEmptyCell.self, for: indexPath)
                    .configured(with: LocalizableStrings.not_found)
                cell.backgroundView?.backgroundColor = UIColor.main.marineTwo.withAlphaComponent(0.35)
                return cell
            }
            else {
                let cell =  tableView
                    .dequeueReusableCell(withType: ContactCell.self, for: indexPath)
                    .configured(with: (row: indexPath.row, contact: contacts[indexPath.row]))
                return cell
            }
        }
        
        switch indexPath.section {
        case 0:
            let cell = tableView
                .dequeueReusableCell(withType: SearchAddressCell.self, for: indexPath)
            cell.delegate = self
            cell.error = addressError
            cell.copyText = copyAddress
            cell.configure(with: (name: LocalizableStrings.paste_enter_address, value: toAddress, rightIcon:IconScanQr()))
            cell.contact = selectedContact
            return cell
        case 1:
            let cell = tableView
                .dequeueReusableCell(withType: BMAmountCell.self, for: indexPath).configured(with: (name: LocalizableStrings.enter_amount   , value: amount))
            cell.delegate = self
            cell.error = amountError
            cell.fee = Double(fee) ?? 0
            return cell
        case 2:
            var total = LocalizableStrings.zero
            if let status = AppModel.sharedManager().walletStatus {
                total = String.currency(value: status.realAmount)
            }
            let cell = tableView
                .dequeueReusableCell(withType: SendAllCell.self, for: indexPath).configured(with: total)
            cell.delegate = self
            return cell
        case 3:
            let cell = tableView
                .dequeueReusableCell(withType: BMFieldCell.self, for: indexPath)
                .configured(with: (name: LocalizableStrings.local_annotation_not_shared, value: comment, rightIcon:nil))
            cell.delegate = self
            return cell
        case 4:
            let cell = tableView
                .dequeueReusableCell(withType: BMExpandCell.self, for: indexPath)
                .configured(with: (expand: showAdvanced, title: LocalizableStrings.advanced.uppercased()))
            cell.delegate = self
            return cell
        case 5:
            let cell = tableView
                .dequeueReusableCell(withType: FeeCell.self, for: indexPath)
                .configured(with: Double(fee) ?? 0)
            cell.delegate = self
            return cell
        default:
            return BaseCell()
        }
    }
}

extension SendViewController : BMCellProtocol {
    
    func textValueDidBegin(_ sender: UITableViewCell) {
        if let path = tableView.indexPath(for: sender)  {
            tableView.scrollToRow(at: path, at: .middle, animated: true)
        }
    }
    
    func textValueDidChange(_ sender: UITableViewCell, _ text: String, _ input:Bool) {
        if let path = tableView.indexPath(for: sender)  {
            if path.section == 0 {
                addressError = nil
                selectedContact = nil
                
                toAddress = text
                
                if input && !text.isEmpty {
                    isSearch = true
                    search()
                }
                else{
                    isSearch = false
                }
            }
            else if path.section == 1 {
                onSendAll = false
                amountError = nil
                amount = text
            }
            else if path.section == 3 {
                comment = text
            }
        }
        
        UIView.performWithoutAnimation {
            tableView.beginUpdates()
            tableView.endUpdates()
        }
    }
    
    func textValueDidReturn(_ sender: UITableViewCell) {
        if let path = tableView.indexPath(for: sender)  {
            if path.section == 0 {
                if !toAddress.isEmpty {
                    if !AppModel.sharedManager().isValidAddress(toAddress) {
                        addressError = LocalizableStrings.incorrect_address
                    }
                }
            }
            
            if path.section == 0 && isSearch {
                isSearch = false
                tableView.reloadData()
            }
            else{
                tableView.reloadRows(at: [path], with: .none)
            }
            
            if path.section == 0 && amount.isEmpty && !toAddress.isEmpty {
                if let cell = tableView.findCell(BMAmountCell.self) as? BMAmountCell {
                    cell.beginEditing()
                }
            }
        }
    }
    
    func onRightButton(_ sender: UITableViewCell) {
        if let path = tableView.indexPath(for: sender) {
            if path.section == 0 {
                let vc = QRScannerViewController()
                vc.delegate = self
                vc.isGradient = true
                pushViewController(vc: vc)
            }
            else if path.section == 2 {
                let all = AppModel.sharedManager().allAmount(Double(fee) ?? 0)
                
                amountError = nil
                amount = all
                onSendAll = true
                
                if let cell = tableView.findCell(BMAmountCell.self) as? BMAmountCell {
                    cell.configure(with: (name: LocalizableStrings.enter_amount, value: amount))
                    cell.error = amountError
                    cell.fee = Double(fee) ?? 0
                }
                else{
                    tableView.reloadData()
                }
              
                UIView.performWithoutAnimation {
                    tableView.beginUpdates()
                    tableView.endUpdates()
                }
            }
        }
    }
    
    func onExpandCell(_ sender: UITableViewCell) {
        if let path = tableView.indexPath(for: sender)
        {
            if path.section == 4 {
                showAdvanced = !showAdvanced
                
                if showAdvanced {
                    self.tableView.insertSections(IndexSet(integer:5), with: .fade)
                }
                else{
                    self.tableView.deleteSections(IndexSet(integer:5), with: .fade)
                }
            }
        }
    }
    
    func onDidChangeFee(value: Double) {
        fee = String(value)
        
        if onSendAll {
            let all = AppModel.sharedManager().allAmount(Double(fee) ?? 0)
            
            amountError = nil
            amount = all
            
            if let cell = tableView.findCell(BMAmountCell.self) as? BMAmountCell {
                cell.configure(with: (name: LocalizableStrings.enter_amount, value: amount))
                cell.error = amountError
                cell.fee = Double(fee) ?? 0
            }
        }
    }
}

extension SendViewController : QRScannerViewControllerDelegate
{
    func didScanQRCode(value:String, amount:String?) {
        selectedContact = nil
        
        if let a = amount {
            self.amount = a
        }
        
        didSelectAddress(value: value)
    }
}

extension SendViewController : SettingsModelDelegate {
    func onChangeHideAmounts() {
        addRightButton(image: Settings.sharedManager().isHideAmounts ? IconShowBalance() : IconHideBalance(), targer: self, selector: #selector(onHideAmounts))

        if Settings.sharedManager().isHideAmounts {
            tableView.deleteRows(at: [IndexPath(row: 0, section: 2)], with: .fade)
        }
        else{
            tableView.insertRows(at: [IndexPath(row: 0, section: 2)], with: .fade)
        }
    }
}

extension SendViewController {
    
    override func keyboardWillShow(_ notification: Notification) {
        super.keyboardWillShow(notification)
        
        searchTableView.contentInset = tableView.contentInset
    }
    
    override func keyboardWillHide(notification: NSNotification) {
        super.keyboardWillHide(notification: notification)
        
        searchTableView.contentInset = tableView.contentInset
    }
}
