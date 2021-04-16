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
    private var alreadyChanged = false
    private var cellHeights: [IndexPath: CGFloat] = [:]
    
    private var isSearch = false {
        didSet {
            tableView.isScrollEnabled = !isSearch
            pagingViewController.view.isHidden = !isSearch
            
            layoutSearchTableView()
        }
    }
    
    private let nextButton = BMButton.defaultButton(frame: CGRect(x: (UIScreen.main.bounds.size.width - 143) / 2, y: 40, width: 143, height: 44), color: UIColor.main.heliotrope.withAlphaComponent(0.1))
    
    
    private lazy var footerView: UIView = {
        let view = UIView(frame: CGRect(x: 0, y: 0, width: UIScreen.main.bounds.size.width, height: 0))
        
        let infoLabel = UILabel(frame: CGRect(x: 20, y: 25, width: UIScreen.main.bounds.width-40, height: 0))
        infoLabel.numberOfLines = 0
        infoLabel.text = Localizable.shared.strings.send_notice
        infoLabel.font = ItalicFont(size: 14)
        infoLabel.textAlignment = .center
        if Settings.sharedManager().isDarkMode {
            infoLabel.textColor = UIColor.main.steel;
        }
        else {
            infoLabel.textColor = UIColor.main.blueyGrey
        }
        infoLabel.adjustFontSize = true
        infoLabel.sizeToFit()
        view.addSubview(infoLabel)
        
        nextButton.y = infoLabel.frame.origin.y + infoLabel.frame.size.height + 30
        nextButton.setImage(IconNextPink(), for: .normal)
        nextButton.setTitle(Localizable.shared.strings.next.lowercased(), for: .normal)
        nextButton.layer.borderWidth = 1
        nextButton.layer.borderColor = UIColor.main.heliotrope.cgColor
        nextButton.setTitleColor(UIColor.main.heliotrope, for: .normal)
        nextButton.addTarget(self, action: #selector(onNext), for: .touchUpInside)
        view.addSubview(nextButton)
        
        view.frame = CGRect(x: 0, y: 0, width: UIScreen.main.bounds.size.width, height: nextButton.frame.origin.y + nextButton.frame.size.height + 40)
        
        return view
    }()
    
    override var tableStyle: UITableView.Style {
        get {
            return .grouped
        }
        set {
            super.tableStyle = newValue
        }
    }
    
    public var transaction: BMTransaction?
    private let viewModel = SendTransactionViewModel()
    
    private var showFee = false
    private var showComment = false
    
    private let pagingViewController = BMPagingViewController()
    private var titles = [Localizable.shared.strings.contacts, Localizable.shared.strings.my_active_addresses]
    private var searchControlles = [SearchTableView(), SearchTableView()]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        viewModel.onDataChanged = { [weak self] in
            guard let strongSelf = self else { return }
            
            if let cell = strongSelf.tableView.cellForRow(at: IndexPath(row: 0, section: 0)) as? BMSearchAddressCell {
                cell.error = strongSelf.viewModel.toAddressError
                cell.additionalError = strongSelf.viewModel.newVersionError
                cell.copyText = strongSelf.viewModel.copyAddress
                cell.setData(with: (name: Localizable.shared.strings.transaction_info.uppercased(), value: strongSelf.viewModel.toAddress))
                cell.contact = strongSelf.viewModel.selectedContact
                cell.addressType = BMAddressType(strongSelf.viewModel.addressType)
            }
        }
        
        viewModel.onFeeChanged = {[weak self] in
            guard let strongSelf = self else { return }
            
            for cell in strongSelf.tableView.visibleCells {
                if let feeCell = cell as? FeeCell {
                    feeCell.setMinFee(minFee: UInt64(strongSelf.viewModel.minFee) ?? 200)
                    feeCell.configure(with: Double(strongSelf.viewModel.fee) ?? 0)
                }
            }
            
            if strongSelf.tableView.cellForRow(at: IndexPath(row: 1, section: 1)) != nil {
                UIView.performWithoutAnimation {
                    strongSelf.tableView.reloadRows(at: [IndexPath(row: 1, section: 1)], with: .none)
                }
            }
        }
        
        viewModel.onContactChanged = { [weak self] _ in
            guard let strongSelf = self else { return }
            UIView.performWithoutAnimation {
                strongSelf.tableView.reloadRows(at: [IndexPath(row: 0, section: 0)], with: .none)
            }
        }
        
        if let repeatTransaction = transaction {
            if let ct = AppModel.sharedManager().getContactFromId(repeatTransaction.receiverAddress)
            {
                viewModel.selectedContact = ct
            }
            else if let address = AppModel.sharedManager().findAddress(byID: repeatTransaction.receiverAddress) {
                let contact = BMContact()
                contact.name = address.label
                contact.address = address
                viewModel.selectedContact = contact
            }
            viewModel.transaction = repeatTransaction
            
        }
        
        tableView.register([BMFieldCell.self, SendAllCell.self, BMAmountCell.self, BMExpandCell.self, FeeCell.self, BMSearchAddressCell.self, SendSaveAddressCell.self, BMMultiLinesCell.self, SendContactAddressCell.self])
        
        tableView.delegate = self
        tableView.dataSource = self
        tableView.keyboardDismissMode = .interactive
        tableView.tableFooterView = footerView
        tableView.contentInsetAdjustmentBehavior = .never
        tableView.tableHeaderView = UIView(frame: CGRect(x: 0.0, y: 0.0, width: 0.0, height: 1))
        tableView.tableHeaderView?.backgroundColor = UIColor.main.marine
        tableView.sectionHeaderHeight = 0.0
        tableView.sectionFooterHeight = 0.0
        
        let pagingView = pagingViewController.view as! PagingView
        pagingView.options.indicatorColor = UIColor.main.heliotrope
        pagingView.options.menuItemSpacing = 30
        
        pagingViewController.view.backgroundColor = view.backgroundColor
        pagingViewController.view.isHidden = true
        addChild(pagingViewController)
        view.addSubview(pagingViewController.view)
        pagingViewController.didMove(toParent: self)
        
        pagingViewController.dataSource = self
        pagingViewController.delegate = self
        
        setGradientTopBar(mainColor: UIColor.main.heliotrope)
        
        title = Localizable.shared.strings.send.uppercased()
        
        addRightButton(image: Settings.sharedManager().isHideAmounts ? IconShowBalance() : IconHideBalance(), target: self, selector: #selector(onHideAmounts))
        
        Settings.sharedManager().addDelegate(self)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        layoutSearchTableView()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        if viewModel.isNeedFocus {
            if let cell = tableView.findCell(BMSearchAddressCell.self) as? BMSearchAddressCell {
                cell.beginEditing(text: viewModel.copyAddress)
            }
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        view.endEditing(true)
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        
        
        if isMovingFromParent {
            Settings.sharedManager().removeDelegate(self)
        }
    }
    
    private func layoutSearchTableView() {
        let rect = tableView.rectForRow(at: IndexPath(row: 0, section: 0))
        let y: CGFloat = navigationBarOffset + rect.size.height + 20
        
        pagingViewController.view.frame = CGRect(x: 0, y: y, width: view.bounds.width, height: view.bounds.size.height - y)
    }
    
    private func didSelectAddress(value: String) {
        isSearch = false
        
        viewModel.toAddress = value
        
        tableView.reloadData()
        tableView.reloadSections(IndexSet(arrayLiteral: 0), with: .none)
        
        if viewModel.amount.isEmpty {
            if let cell = tableView.findCell(BMAmountCell.self) as? BMAmountCell {
                cell.beginEditing()
            }
        }
    }
    
    // MARK: - IBAction
    
    @objc private func onNext() {
        if !viewModel.canSend() {
            tableView.reloadData()
            tableView.scrollToRow(at: IndexPath(row: 0, section: 0), at: .top, animated: false)
        }
        else {
            let vc = SendConfirmViewController(viewModel: viewModel)
            pushViewController(vc: vc)
        }
    }
}

extension SendViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let view = UIView()
        view.backgroundColor = UIColor.clear
        return view
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 20
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
}

extension SendViewController: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return 4
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0:
            return 1
        case 1:
            return Settings.sharedManager().isHideAmounts ? 1 : 2
        case 2:
            return showComment ? 2 : 1
        case 3:
            return showFee ? 2 : 1
        default:
            return 1
        }
    }
    
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch indexPath.section {
        case 0:
            if viewModel.addressType != BMAddressTypeUnknown && viewModel.selectedContact == nil {
                let cell = tableView
                    .dequeueReusableCell(withType: SendSaveAddressCell.self, for: indexPath)
                cell.configure(with: (token: viewModel.toAddress, addressType: BMAddressType(viewModel.addressType), name: viewModel.saveContactName))
                cell.delegate = self
                return cell
            }
            else if viewModel.selectedContact != nil {
                let cell = tableView
                    .dequeueReusableCell(withType: SendContactAddressCell.self, for: indexPath)
                cell.configure(with: (contact: viewModel.selectedContact, addressType: BMAddressType(viewModel.addressType)))
                cell.delegate = self
                return cell
            }
            else {
                let cell = tableView
                    .dequeueReusableCell(withType: BMSearchAddressCell.self, for: indexPath)
                cell.delegate = self
                cell.error = viewModel.toAddressError
                cell.additionalError = viewModel.newVersionError
                cell.copyText = viewModel.copyAddress
                cell.configure(with: (name: Localizable.shared.strings.send_to.uppercased(), value: viewModel.toAddress, rightIcons: [IconAddressBookSmall(), IconScanQr()]))
                cell.contact = viewModel.selectedContact
                cell.addressType = BMAddressType(viewModel.addressType)
                cell.nameLabelTopOffset.constant = 20
                cell.titleColor = UIColor.white
                cell.placeholder = Localizable.shared.strings.search_or_paste
                
                if(viewModel.selectedContact == nil && cell.addressType == BMAddressTypeUnknown) {
                    cell.stackBotOffset.constant = 25
                }
                else if(viewModel.selectedContact != nil && cell.addressType == BMAddressTypeRegular) {
                    cell.stackBotOffset.constant = 15
                }
                else {
                    cell.stackBotOffset.constant = 20
                }
                return cell
            }
        case 1:
            if indexPath.row == 0 {
                let cell = tableView
                    .dequeueReusableCell(withType: BMAmountCell.self, for: indexPath).configured(with: (name: Localizable.shared.strings.amount.uppercased(), value: viewModel.inputAmount))
                cell.delegate = self
                cell.error = viewModel.amountError
                cell.fee = Double(viewModel.fee) ?? 0
                cell.currency = viewModel.selectedCurrencyString
                cell.contentView.backgroundColor = UIColor.main.marineThree
                cell.setSecondAmount(amount: viewModel.secondAmount)
                cell.topNameOffset.constant = 20
                cell.titleColor = UIColor.white
                return cell
            }
            else {
                let amount = AppModel.sharedManager().walletStatus?.realAmount ?? 0
                let isAll = (amount > 0.0 ? viewModel.sendAll : true)
                let cell = tableView
                    .dequeueReusableCell(withType: SendAllCell.self, for: indexPath)
                cell.configure(with: (realAmount:amount , isAll: isAll, type: 0))
                cell.delegate = self
                cell.contentView.backgroundColor = UIColor.main.marineThree
                cell.bottomOffset.constant = 20
                return cell
            }
        case 2:
            if indexPath.row == 0 {
                let cell = tableView
                    .dequeueReusableCell(withType: BMExpandCell.self, for: indexPath)
                    .configured(with: (expand: showFee, title: Localizable.shared.strings.comment.uppercased()))
                cell.delegate = self
                return cell
            }
            else {
                let cell = tableView
                    .dequeueReusableCell(withType: BMFieldCell.self, for: indexPath)
                    .configured(with: (name: Localizable.shared.strings.comment.uppercased(), value: viewModel.comment))
                cell.delegate = self
                cell.placholder = Localizable.shared.strings.local_comment.capitalizingFirstLetter()
                cell.isItalicPlacholder = true
                cell.contentView.backgroundColor = UIColor.main.marineThree
               // cell.topOffset?.constant = 20
                cell.titleTextColor = UIColor.white
                cell.hideNameLabel = true
                return cell
            }
        case 3:
            if indexPath.row == 0 {
                let cell = tableView
                    .dequeueReusableCell(withType: BMExpandCell.self, for: indexPath)
                    .configured(with: (expand: showFee, title: Localizable.shared.strings.transaction_fee.uppercased()))
                cell.delegate = self
                return cell
            }
            else {
                let cell = tableView
                    .dequeueReusableCell(withType: FeeCell.self, for: indexPath)
                cell.delegate = self
                cell.setMinFee(minFee: UInt64(viewModel.minFee) ?? 200)
                cell.configure(with: Double(viewModel.fee) ?? 0)
                return cell
            }
        default:
            return BaseCell()
        }
    }
}

extension SendViewController: BMCellProtocol {
    
    func textDidChangeStatus(_ sender: UITableViewCell) {
        
    }
    
    func textValueDidBegin(_ sender: UITableViewCell) {
        if let path = tableView.indexPath(for: sender) {
            
            if path.section == 0 {
                isSearch = true
                
                searchControlles[0].contacts = viewModel.searchForContacts(searchIndex: 0)
                searchControlles[1].contacts = viewModel.searchForContacts(searchIndex: 1)
                
                for vc in searchControlles {
                    vc.reload()
                }
            }
        }
    }
    
    func textValueDidChange(_ sender: UITableViewCell, _ text: String, _ input: Bool) {
        var isNeedReload = true
        
        if let path = tableView.indexPath(for: sender) {
            if path.section == 0 {
                if sender is SendSaveAddressCell {
                    viewModel.saveContactName = text
                }
                else {
                    viewModel.toAddress = text
                    
                    if input {
                        isSearch = true
                        
                        searchControlles[0].contacts = viewModel.searchForContacts(searchIndex: 0)
                        searchControlles[1].contacts = viewModel.searchForContacts(searchIndex: 1)
                        
                        for vc in searchControlles {
                            vc.reload()
                        }
                    }
                    else {
                        tableView.reloadData()
                        isSearch = false
                    }
                }
            }
            else if path.section == 1 {
                if input {
                    viewModel.sendAll = false
                    if let cell = tableView.findCell(SendAllCell.self) as? SendAllCell {
                        let amount = AppModel.sharedManager().walletStatus?.realAmount ?? 0
                        let isAll = (amount > 0.0 ? viewModel.sendAll : true)
                        cell.configure(with: (realAmount: AppModel.sharedManager().walletStatus?.realAmount ?? 0, isAll: isAll, type: 0))
                    }
                }
                viewModel.amount = text
                
                UIView.performWithoutAnimation {
                    tableView.beginUpdates()
                    for cell in tableView.visibleCells {
                        if let amoutnCell = cell as? BMAmountCell {
                            amoutnCell.setSecondAmount(amount: viewModel.secondAmount)
                        }
                    }
                    tableView.endUpdates()
                }
                
            }
            else if path.section == 3 {
                isNeedReload = false
                viewModel.comment = text
            }
        }
        
        if isNeedReload {
            UIView.performWithoutAnimation {
                tableView.beginUpdates()
                
                if let cell = tableView.cellForRow(at: IndexPath(row: 0, section: 0)) as? BMSearchAddressCell {
                    cell.error = viewModel.toAddressError
                    cell.additionalError = viewModel.newVersionError
                    cell.copyText = viewModel.copyAddress
                    cell.setData(with: (name: Localizable.shared.strings.send_to.uppercased(), value: viewModel.toAddress))
                    cell.contact = viewModel.selectedContact
                    cell.addressType = BMAddressType(viewModel.addressType)
                }
                
                tableView.endUpdates()
                
                if isSearch {
                    layoutSearchTableView()
                }
            }
        }
    }
    
    func textValueDidReturn(_ sender: UITableViewCell) {
        if let path = tableView.indexPath(for: sender) {
            if path.section == 1 {
                viewModel.checkAmountError()
                
                UIView.performWithoutAnimation {
                    tableView.beginUpdates()
                    if let cell = tableView.findCell(BMAmountCell.self) as? BMAmountCell {
                        cell.error = viewModel.amountError
                    }
                    tableView.endUpdates()
                }
            }
            else if path.section == 0 {
                if !viewModel.toAddress.isEmpty {
                    if !AppModel.sharedManager().isValidAddress(viewModel.toAddress) {
                        viewModel.toAddressError = Localizable.shared.strings.incorrect_address
                    }
                }
                
                let contact = AppModel.sharedManager().getContactFromId(viewModel.toAddress)
                if contact != nil {
                    viewModel.selectedContact = contact
                }
                else {
                    let address = AppModel.sharedManager().findAddress(byID: viewModel.toAddress)
                    if let finded = address {
                        let ncontact = BMContact()
                        ncontact.name = finded.label
                        ncontact.address = finded
                        viewModel.selectedContact = ncontact
                    }
                }
                
                if isSearch {
                    isSearch = false
                    tableView.reloadData()
                }
                else {
                    tableView.reloadRows(at: [path], with: .none)
                }
                
                if viewModel.amount.isEmpty, !viewModel.toAddress.isEmpty {
                    if let cell = tableView.findCell(BMAmountCell.self) as? BMAmountCell {
                        cell.beginEditing()
                    }
                }
            }
        }
    }
    
    func onRightButton(_ sender: UITableViewCell) {
        
        if let path = tableView.indexPath(for: sender) {
            if path.section == 1 {
                if path.row == 1 {
                    view.endEditing(true)
                    viewModel.sendAll = true
                    viewModel.checkFeeError()
                    tableView.reloadData()
                }
                else {
                    let vc = BMDataPickerViewController(type: .sendCurrency)
                    vc.selectedValue = viewModel.selectedCurrency
                    vc.isAutoSelect = false
                    vc.completion = { [weak self] obj in
                        self?.viewModel.selectedCurrency = Int(obj as! BMCurrencyType)
                        self?.tableView.reloadData()
                    }
                    pushViewController(vc: vc)
                }
            }
            else if path.section == 0 {
                if sender is SendContactAddressCell || sender is SendSaveAddressCell {
                    self.viewModel.toAddress = ""
                    self.viewModel.selectedContact = nil
                    self.view.endEditing(true)
                }
                else {
                    let vc = QRScannerViewController()
                    vc.delegate = self
                    pushViewController(vc: vc)
                }
            }
        }
    }
    
    func onExpandCell(_ sender: UITableViewCell) {
        if let path = tableView.indexPath(for: sender) {
            if path.section == 3 {
                showFee = !showFee
                
                if showFee {
                    tableView.insertRows(at: [IndexPath(row: 1, section: path.section)], with: .fade)
                }
                else {
                    tableView.deleteRows(at: [IndexPath(row: 1, section: path.section)], with: .fade)
                }
            }
            else if path.section == 2 {
                showComment = !showComment
                
                if showComment {
                    tableView.insertRows(at: [IndexPath(row: 1, section: path.section)], with: .fade)
                }
                else {
                    tableView.deleteRows(at: [IndexPath(row: 1, section: path.section)], with: .fade)
                }
            }
        }
    }
    
    func onDidChangeFee(value: Double) {
        viewModel.fee = String(Int(value))
        viewModel.checkAmountError()
        viewModel.checkFeeError()
        
        UIView.performWithoutAnimation {
            tableView.reloadData()
        }
    }
}

extension SendViewController: QRScannerViewControllerDelegate {
    func didScanQRCode(value: String, amount: String?, privacy:Bool?, offline: Bool?) {
        viewModel.selectedContact = nil
        
        if let a = amount {
            if Double(a) ?? 0 > 0 {
                viewModel.amount = a
                viewModel.sendAll = false
                let amount = AppModel.sharedManager().walletStatus?.realAmount ?? 0
                let isAll = (amount > 0.0 ? viewModel.sendAll : true)
                if let cell = tableView.findCell(SendAllCell.self) as? SendAllCell {
                    cell.configure(with: (realAmount: AppModel.sharedManager().walletStatus?.realAmount ?? 0, isAll: isAll, type: 0))
                }
            }
        }
        
        if privacy != nil && privacy == true {
            viewModel.requestedMaxPrivacy = true
            viewModel.maxPrivacy = true
        }
        else {
            viewModel.requestedMaxPrivacy = false
        }
        
        if offline != nil && offline == true {
            viewModel.requestedOffline = true
        }
        else {
            viewModel.requestedOffline = false
        }
        
        didSelectAddress(value: value)
    }
}

extension SendViewController: SettingsModelDelegate {
   
    func onChangeHideAmounts() {
        addRightButton(image: Settings.sharedManager().isHideAmounts ? IconShowBalance() : IconHideBalance(), target: self, selector: #selector(onHideAmounts))
        
        if Settings.sharedManager().isHideAmounts {
            tableView.deleteRows(at: [IndexPath(row: 1, section: 1)], with: .none)
        }
        else {
            tableView.insertRows(at: [IndexPath(row: 1, section: 1)], with: .none)
        }
    }
}

extension SendViewController: PagingViewControllerDelegate {
    func pagingViewController<T>(
        _ pagingViewController: PagingViewController<T>,
        widthForPagingItem pagingItem: T,
        isSelected: Bool) -> CGFloat? {
        let index = pagingItem as! PagingIndexItem
        let title = index.title
        let size = title.boundingWidth(with: pagingViewController.options.font, kern: 1.5)
        return size + 20
    }
}

extension SendViewController: PagingViewControllerDataSource {
    func pagingViewController<T>(_ pagingViewController: PagingViewController<T>, viewControllerForIndex index: Int) -> UIViewController {
        searchControlles[index].tableView.contentInsetAdjustmentBehavior = .never
        searchControlles[index].view.backgroundColor = UIColor.clear
        searchControlles[index].delegate = self
        searchControlles[index].tableView.contentInset = tableView.contentInset
        
        return searchControlles[index]
    }
    
    func pagingViewController<T>(_ pagingViewController: PagingViewController<T>, pagingItemForIndex index: Int) -> T {
        return PagingIndexItem(index: index, title: titles[index].uppercased()) as! T
    }
    
    func numberOfViewControllers<T>(in: PagingViewController<T>) -> Int {
        return titles.count
    }
}

extension SendViewController: SearchTableViewDelegate {
    func didSelectContact(contact: BMContact) {
        viewModel.selectedContact = contact
        didSelectAddress(value: contact.address.walletId)
    }
}

