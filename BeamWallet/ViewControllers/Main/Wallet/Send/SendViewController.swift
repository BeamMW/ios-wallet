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
    private var infoLabel = UILabel()
    
    private var isSearch = false {
        didSet {
            tableView.isScrollEnabled = !isSearch
            pagingViewController.view.isHidden = !isSearch
            
            layoutSearchTableView()
        }
    }
    
    private let nextButton = BMButton.defaultButton(frame: CGRect(x: (UIScreen.main.bounds.size.width - 180) / 2, y: 40, width: 180, height: 44), color: UIColor.main.heliotrope.withAlphaComponent(0.1))
    
    
    private func footerView()-> UIView {
        let view = UIView(frame: CGRect(x: 0, y: 0, width: UIScreen.main.bounds.size.width, height: 0))
        
        infoLabel.frame = CGRect(x: 20, y: 25, width: UIScreen.main.bounds.width-40, height: 0)
        infoLabel.numberOfLines = 0
        if viewModel.addressType == BMAddressTypeMaxPrivacy {
            infoLabel.text = Localizable.shared.strings.send_notice_max_privacy
        }
        else if viewModel.isSendOffline || viewModel.addressType == BMAddressTypeOfflinePublic {
            infoLabel.text = Localizable.shared.strings.senf_offline_notice
        }
        else {
            infoLabel.text = Localizable.shared.strings.send_notice
        }
        infoLabel.font = ItalicFont(size: 16)
        infoLabel.textAlignment = .center
        if Settings.sharedManager().isDarkMode {
            infoLabel.textColor = UIColor.main.steel;
        }
        else {
            infoLabel.textColor = UIColor.main.blueyGrey
        }
        infoLabel.adjustFontSize = true
        infoLabel.sizeToFit()
        infoLabel.frame = CGRect(x: 20, y: 25, width: UIScreen.main.bounds.width-40, height: infoLabel.frame.size.height)

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
    }
    
    override var tableStyle: UITableView.Style {
        get {
            return .grouped
        }
        set {
            super.tableStyle = newValue
        }
    }
    
    public var assetId = 0
    public var transaction: BMTransaction?
    private let viewModel = SendTransactionViewModel()
    
    private var showFee = false
    private var showComment = false
    
    private let pagingViewController = BMPagingViewController()
    private var titles = [Localizable.shared.strings.contacts, Localizable.shared.strings.my_active_addresses]
    private var searchControlles = [SearchTableView(), SearchTableView()]
    
    private var isAppear = false
    override func viewDidLoad() {
        super.viewDidLoad()
        
        viewModel.onTokensCountChanged = {[weak self] obj in
            guard let strongSelf = self else { return }
            if let cell = strongSelf.tableView.cellForRow(at: IndexPath(row: 0, section: 0)) as? BMSearchAddressCell {
                cell.setAddressType(BMAddressType(strongSelf.viewModel.addressType), strongSelf.viewModel.isSendOffline, strongSelf.viewModel.tokensLeft)
            }
        }
        
        viewModel.onDataChanged = { [weak self] in
            guard let strongSelf = self else { return }
            
            if let cell = strongSelf.tableView.cellForRow(at: IndexPath(row: 0, section: 0)) as? BMSearchAddressCell {
                cell.additionalError = strongSelf.viewModel.newVersionError
                cell.copyText = strongSelf.viewModel.copyAddress
                cell.setData(with: (name: Localizable.shared.strings.transaction_info.uppercased(), value: strongSelf.viewModel.toAddress))
                cell.contact = strongSelf.viewModel.selectedContact
                cell.setAddressType(BMAddressType(strongSelf.viewModel.addressType), strongSelf.viewModel.isSendOffline, strongSelf.viewModel.tokensLeft)
                cell.error = strongSelf.viewModel.toAddressError
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
            if strongSelf.isAppear {
                strongSelf.reloadInutCell()
            }
        }
        
        viewModel.onAmountMaxError = { [weak self]  in
            guard let strongSelf = self else { return }
            if strongSelf.isAppear {
                strongSelf.tableView.reloadData()
            }
        }
        
        viewModel.onAddressTypeChanged = { [weak self] _ in
            guard let strongSelf = self else { return }
            UIView.performWithoutAnimation {
                strongSelf.tableView.reloadSections(IndexSet(integer: 1), with: .none)
            }
        }
        
        if let repeatTransaction = transaction {
            viewModel.selectedAssetId = Int(repeatTransaction.assetId)
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
        else if assetId > 0 {
            viewModel.selectedAssetId = assetId
        }
            
        tableView.register([BMFieldCell.self, SendAllCell.self, BMAmountCell.self, BMExpandCell.self, FeeCell.self, BMSearchAddressCell.self, SendSaveAddressCell.self, BMMultiLinesCell.self, SendContactAddressCell.self, SendTransactionTypeCell.self])
        
        tableView.delegate = self
        tableView.dataSource = self
        tableView.keyboardDismissMode = .interactive
        tableView.tableFooterView = footerView()
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
        
        self.isAppear = true
        
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
            viewModel.revertOutgoingAddress()
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
        if section == 1 && !viewModel.isNeedDisplaySegmentCell {
            return nil
        }
        let view = UIView()
        view.backgroundColor = UIColor.clear
        return view
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        if section == 1 && !viewModel.isNeedDisplaySegmentCell {
            return 0
        }
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
        case 1:
            return viewModel.isNeedDisplaySegmentCell ? 1 : 0
        case 2:
            return Settings.sharedManager().isHideAmounts ? 1 : 2
        case 3:
            return showComment ? 2 : 1
        case 4:
            return showFee ? 2 : 1
        default:
            return 1
        }
    }
    
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch indexPath.section {
        case 0:
            let cell = tableView
                .dequeueReusableCell(withType: BMSearchAddressCell.self, for: indexPath)
            cell.delegate = self
            cell.additionalError = viewModel.newVersionError
            cell.copyText = viewModel.copyAddress
            cell.configure(with: (name: Localizable.shared.strings.send_to.uppercased(), value: viewModel.toAddress, rightIcons: [IconScanQr()])) //IconAddressBookSmall(),
            cell.contact = viewModel.selectedContact
            cell.setAddressType(BMAddressType(viewModel.addressType), viewModel.isSendOffline, viewModel.tokensLeft)
            cell.nameLabelTopOffset.constant = 20
            cell.titleColor = UIColor.white
            cell.placeholder = Localizable.shared.strings.send_address_placholder
            
            if(viewModel.selectedContact == nil && cell.addressType == BMAddressTypeUnknown) {
                cell.stackBotOffset.constant = 25
            }
            else if(viewModel.selectedContact != nil && cell.addressType == BMAddressTypeRegular) {
                cell.stackBotOffset.constant = 15
            }
            else {
                cell.stackBotOffset.constant = 20
            }
            cell.error = viewModel.toAddressError

            return cell
        case 1:
            let cell = tableView
                .dequeueReusableCell(withType: SendTransactionTypeCell.self, for: indexPath)
            cell.delegate = self
            cell.selectedIndex = viewModel.isSendOffline ? 1 : 0
            cell.contentView.backgroundColor = UIColor.main.marineThree
            return cell
        case 2:
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
                cell.maxAmountError = viewModel.maxAmountError
                return cell
            }
            else {
                let amount = AssetsManager.shared().getRealAvailableAmount(Int32(viewModel.selectedAssetId))
                let isAll = (amount > 0.0 ? viewModel.sendAll : true)
                let cell = tableView
                    .dequeueReusableCell(withType: SendAllCell.self, for: indexPath)
                cell.configure(with: (realAmount:amount, assetId:viewModel.selectedAssetId, isAll: isAll, type: 0))
                cell.delegate = self
                cell.contentView.backgroundColor = UIColor.main.marineThree
                cell.bottomOffset.constant = 20
                return cell
            }
        case 3:
            if indexPath.row == 0 {
                let cell = tableView
                    .dequeueReusableCell(withType: BMExpandCell.self, for: indexPath)
                    .configured(with: (expand: showFee, title: Localizable.shared.strings.comment.uppercased()))
                cell.delegate = self
                cell.nameLabel.textColor = .white
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
        case 4:
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
                    viewModel.selectedContact = nil
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
            else if path.section == 2 {
                if input {
                    viewModel.sendAll = false
                    if let cell = tableView.findCell(SendAllCell.self) as? SendAllCell {
                        let amount = AssetsManager.shared().getRealAvailableAmount(Int32(self.viewModel.selectedAssetId))
                        let isAll = (amount > 0.0 ? viewModel.sendAll : true)
                        cell.configure(with: (realAmount: amount, assetId:viewModel.selectedAssetId, isAll: isAll, type: 0))
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
              
                self.reloadInutCell()
                
                if isSearch {
                    layoutSearchTableView()
                }
            }
        }
    }
    
    func textValueDidReturn(_ sender: UITableViewCell) {
        if let path = tableView.indexPath(for: sender) {
            if path.section == 2 {
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
            if path.section == 2 {
                if path.row == 1 {
                    view.endEditing(true)
                    viewModel.sendAll = true
                    viewModel.checkFeeError()
                    tableView.reloadData()
                }
                else {
                    if tableView.indexPath(for: sender) != nil, let cell = sender as? BMAmountCell {
                        var menu = [BMPopoverMenu.BMPopoverMenuItem]()
                        
                        for asset in AssetsManager.shared().getAssetsWithBalanceWithBeam() as! [BMAsset] {
                            let m = BMPopoverMenu.BMPopoverMenuItem(name: asset.unitName, icon: nil, action: .asset, selected:  self.viewModel.selectedAssetId == Int(asset.assetId))
                            m.id = Int(asset.assetId)
                            menu.append(m)
                        }
                        
                        BMPopoverMenu.showForSenderAssets(sender: cell.currencyView, with: menu) { item in
                            let asset = AssetsManager.shared().getAsset(Int32(item?.id ?? 0))
                            let selected = asset?.assetId ?? 0

                            let old = self.viewModel.selectedAssetId
                            self.viewModel.selectedAssetId = Int(asset?.assetId ?? 0)

                            if selected != old {
                                self.viewModel.sendAll = false
                                self.viewModel.amount = ""
                            }

                            self.viewModel.checkAmountError()
                            self.tableView.reloadData()

                        } cancel: {
                            self.tableView.reloadData()
                        }
                    }
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
            if path.section == 4 {
                showFee = !showFee
                
                if showFee {
                    tableView.insertRows(at: [IndexPath(row: 1, section: path.section)], with: .fade)
                }
                else {
                    tableView.deleteRows(at: [IndexPath(row: 1, section: path.section)], with: .fade)
                }
            }
            else if path.section == 3 {
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
    
    private func reloadInutCell() {
        UIView.performWithoutAnimation {
            tableView.beginUpdates()
            
            if let cell = tableView.cellForRow(at: IndexPath(row: 0, section: 0)) as? BMSearchAddressCell {
                cell.additionalError = viewModel.newVersionError
                cell.copyText = viewModel.copyAddress
                cell.setData(with: (name: Localizable.shared.strings.transaction_info.uppercased(), value: viewModel.toAddress))
                cell.contact = viewModel.selectedContact
                cell.setAddressType(BMAddressType(viewModel.addressType), viewModel.isSendOffline, viewModel.tokensLeft)
                cell.error = viewModel.toAddressError
            }
            
            tableView.tableFooterView = footerView()

            tableView.endUpdates()
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
                let amount = AssetsManager.shared().getRealAvailableAmount(Int32(self.viewModel.selectedAssetId))
                let isAll = (amount > 0.0 ? viewModel.sendAll : true)
                if let cell = tableView.findCell(SendAllCell.self) as? SendAllCell {
                    cell.configure(with: (realAmount: amount, assetId:self.viewModel.selectedAssetId, isAll: isAll, type: 0))
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
            tableView.deleteRows(at: [IndexPath(row: 1, section: 2)], with: .none)
        }
        else {
            tableView.insertRows(at: [IndexPath(row: 1, section: 2)], with: .none)
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

extension SendViewController: SendTransactionTypeCellDelegate {
    
    func onDidSelectTrasactionType(maxPrivacy: Bool) {
        viewModel.isSendOffline = maxPrivacy
        if viewModel.addressType == BMAddressTypeMaxPrivacy {
            infoLabel.text = Localizable.shared.strings.send_notice_max_privacy
        }
        else if viewModel.addressType == BMAddressTypeOfflinePublic {
            infoLabel.text = Localizable.shared.strings.senf_offline_notice
        }
        else if viewModel.isSendOffline {
            infoLabel.text = Localizable.shared.strings.send_offline_hint
        }
        else {
            infoLabel.text = Localizable.shared.strings.send_notice
        }
        
        if let cell = self.tableView.cellForRow(at: IndexPath(row: 0, section: 0)) as? BMSearchAddressCell {
            UIView.performWithoutAnimation {
                self.tableView.beginUpdates()
                cell.setAddressType(BMAddressType(self.viewModel.addressType), self.viewModel.isSendOffline, self.viewModel.tokensLeft)
                self.tableView.endUpdates()
            }
        }
    }
}
