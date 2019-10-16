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
import Parchment

class SendViewController: BaseTableViewController {

    private var alreadyChanged = false
    private var cellHeights: [IndexPath : CGFloat] = [:]

    private var isSearch = false {
        didSet {
            tableView.isScrollEnabled = !isSearch
            pagingViewController.view.isHidden = !isSearch
            
            layoutSearchTableView()
        }
    }
    
    private lazy var footerView: UIView = {
        
        let view = UIView(frame: CGRect(x: 0, y: 0, width: UIScreen.main.bounds.size.width, height:0))

        let button = BMButton.defaultButton(frame: CGRect(x: (UIScreen.main.bounds.size.width-143)/2, y: 40, width: 143, height: 44), color: UIColor.main.heliotrope.withAlphaComponent(0.1))
        button.setImage(IconNextPink(), for: .normal)
        button.setTitle(Localizable.shared.strings.next.lowercased(), for: .normal)
        button.layer.borderWidth = 1
        button.layer.borderColor = UIColor.main.heliotrope.cgColor
        button.setTitleColor(UIColor.main.heliotrope, for: .normal)
        button.addTarget(self, action: #selector(onNext), for: .touchUpInside)
        view.addSubview(button)
        
        view.frame = CGRect(x: 0, y: 0, width: UIScreen.main.bounds.size.width, height:button.frame.origin.y + button.frame.size.height + 40)
        
        return view
    }()
    
    override var isUppercasedTitle: Bool {
        get{
            return true
        }
        set{
            super.isUppercasedTitle = true
        }
    }
    
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
    
    private var showAdvanced = false
    private var showEdit = false
    
    private let pagingViewController = BMPagingViewController()
    private var titles = [Localizable.shared.strings.contacts, Localizable.shared.strings.my_active_addresses]
    private var searchControlles = [SearchTableView(),SearchTableView()]
    
    
    override func viewDidLoad() {
        super.viewDidLoad()

        if let repeatTransaction = transaction {
            viewModel.transaction = repeatTransaction
        }
        
        tableView.register([BMFieldCell.self, SendAllCell.self, BMAmountCell.self, BMExpandCell.self, FeeCell.self, BMDetailCell.self, BMSearchAddressCell.self, BMAddressCell.self, BMPickedAddressCell.self])
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
        pagingView.options.menuInsets = UIEdgeInsets(top: 0, left: 5, bottom: 0, right: 5)

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
        
        Settings.sharedManager().addDelegate(self)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        self.view.endEditing(true)
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        
        Settings.sharedManager().removeDelegate(self)
        
        if isMovingFromParent {
            viewModel.revertOutgoingAddress()
        }
    }
    
    private func layoutSearchTableView () {
        let rect = self.tableView.rectForRow(at: IndexPath(row: 0, section: 0))
        let y:CGFloat = navigationBarOffset + rect.size.height + 20
        
        pagingViewController.view.frame = CGRect(x: 0, y: y, width: self.view.bounds.width, height: self.view.bounds.size.height - y)
    }
    
    private func didSelectAddress(value:String) {
        isSearch = false
        
        viewModel.toAddress = value
        
        tableView.reloadData()
        
        if viewModel.amount.isEmpty {
            if let cell = tableView.findCell(BMAmountCell.self) as? BMAmountCell {
                cell.beginEditing()
            }
        }
    }
    
    //MARK: - IBAction

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

extension SendViewController : UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let view = UIView()
        view.backgroundColor = (section == 5 || section == 6 || section == 7) ?  UIColor.main.marineThree : UIColor.clear
        return view
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        switch section {
        case 2:
            return Settings.sharedManager().isHideAmounts ? 0 : 30
        case 5, 7, 6:
            return 10
        default:
            return (section > 0 ) ? 30 : 10
        }
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if indexPath.section == 6 {
            if indexPath.row == 2 || indexPath.row == 3 {
                return 60
            }
        }
        else if indexPath.section == 1 && indexPath.row == 1 {
            return 17
        }
        return UITableView.automaticDimension
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        if indexPath.section == 6 {
            switch indexPath.row {
            case 2:
                self.onExpire()
            case 3:
                self.onCategory()
            default:
                return
            }
        }
    }
}


extension SendViewController : UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return (showAdvanced ? 8 : 5)
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 1:
            return (viewModel.sendAll ? 2 : 1)
        case 2:
            return Settings.sharedManager().isHideAmounts ? 0 : 1
        case 5:
            return (viewModel.outgoindAdderss == nil) ? 0 : 1
        case 6:
            return (viewModel.outgoindAdderss == nil) ? 0 : (showEdit ? 4 : 1)
        default:
            return 1
        }
    }
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        cellHeights[indexPath] = cell.frame.size.height
    }
    
    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        return cellHeights[indexPath] ?? UITableView.automaticDimension
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch indexPath.section {
        case 0:
            let cell = tableView
                .dequeueReusableCell(withType: BMSearchAddressCell.self, for: indexPath)
            cell.delegate = self
            cell.error = viewModel.toAddressError
            cell.copyText = viewModel.copyAddress
            cell.configure(with: (name: Localizable.shared.strings.send_to, value: viewModel.toAddress, rightIcon:IconScanQr()))
            cell.contact = viewModel.selectedContact
            return cell
        case 1:
            if indexPath.row == 0 {
                let cell = tableView
                    .dequeueReusableCell(withType: BMAmountCell.self, for: indexPath).configured(with: (name: Localizable.shared.strings.amount.uppercased(), value: viewModel.amount))
                cell.delegate = self
                cell.error = viewModel.amountError
                cell.fee = Double(viewModel.fee) ?? 0
                return cell
            }
            else{
                var cell = tableView.dequeueReusableCell(withIdentifier: "cell")
                
                if cell == nil {
                    cell = UITableViewCell(style: .default, reuseIdentifier: "cell")
                    
                    cell?.textLabel?.textColor = UIColor.main.blueyGrey
                    cell?.textLabel?.font = RegularFont(size: 14)
                    
                    cell?.backgroundColor = UIColor.clear
                    cell?.selectionStyle = .none
                    cell?.separatorInset = UIEdgeInsets.zero
                    cell?.indentationLevel = 0
                }
                
                cell?.textLabel?.text = "+ \(viewModel.fee) GROTH " + Localizable.shared.strings.transaction_fee.lowercased()
                
                return cell!
            }
        case 2:
            var total = Localizable.shared.strings.zero
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
                .configured(with: (name: Localizable.shared.strings.transaction_comment, value: viewModel.comment))
            cell.delegate = self
            return cell
        case 4:
            let cell = tableView
                .dequeueReusableCell(withType: BMExpandCell.self, for: indexPath)
                .configured(with: (expand: showAdvanced, title: Localizable.shared.strings.advanced.uppercased()))
            cell.delegate = self
            return cell
        case 5:
            var title = (viewModel.pickedOutgoingAddress == nil ? Localizable.shared.strings.outgoing : Localizable.shared.strings.outgoing_address.uppercased())
            
            if viewModel.pickedOutgoingAddress != nil {
                if viewModel.pickedOutgoingAddress?.walletId == viewModel.startedAddress?.walletId {
                    title = Localizable.shared.strings.outgoing
                }
            }
            
            let cell = tableView
                .dequeueReusableCell(withType: BMPickedAddressCell.self, for: indexPath)
                .configured(with: (hideLine: true, address: viewModel.outgoindAdderss, title: title))
            cell.delegate = self
            cell.contentView.backgroundColor = UIColor.main.marineThree
            return cell
        case 6:
            if indexPath.row == 0 {
                let cell = tableView
                    .dequeueReusableCell(withType: BMExpandCell.self, for: indexPath)
                    .configured(with: (expand: showEdit, title: Localizable.shared.strings.edit_address.uppercased()))
                cell.delegate = self
                return cell
            }
            else if indexPath.row == 2 {
                let cell = tableView
                    .dequeueReusableCell(withType: BMDetailCell.self, for: indexPath)
                    .configured(with: (title: Localizable.shared.strings.expires.uppercased(), value: (viewModel.outgoindAdderss!.duration > 0 ? Localizable.shared.strings.hours_24 : Localizable.shared.strings.never), valueColor: UIColor.white))
                return cell
            }
            else if indexPath.row == 3 {
                let cell = tableView
                    .dequeueReusableCell(withType: BMDetailCell.self, for: indexPath)
                cell.simpleConfigure(with: (title: Localizable.shared.strings.category.uppercased(), attributedValue: viewModel.outgoindAdderss!.categoriesName()))
                return cell
            }
            else{
                let cell = tableView
                    .dequeueReusableCell(withType: BMFieldCell.self, for: indexPath)
                    .configured(with: (name: Localizable.shared.strings.name.uppercased(), value: viewModel.outgoindAdderss!.label))
                cell.delegate = self
                cell.contentView.backgroundColor = UIColor.main.marineThree
                cell.topOffset?.constant = 20
                return cell
            }
        case 7:
            let cell = tableView
                .dequeueReusableCell(withType: FeeCell.self, for: indexPath)
                .configured(with: Double(viewModel.fee) ?? 0)
            cell.delegate = self
            return cell
        default:
            return BaseCell()
        }
    }
}

extension SendViewController : BMCellProtocol {
    
    func textDidChangeStatus(_ sender: UITableViewCell) {
//        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
//            if let path = self.tableView.indexPath(for: sender)  {
//                UIView.performWithoutAnimation {
//                    self.tableView.beginUpdates()
//                    self.tableView.reloadRows(at: [path], with: .none)
//                    self.tableView.endUpdates()
//                }
//            }
//        }
//        if !alreadyChanged {
//            alreadyChanged = true//
//        }
    }
    
    func textValueDidBegin(_ sender: UITableViewCell) {
        if let path = tableView.indexPath(for: sender)  {
            tableView.scrollToRow(at: path, at: .middle, animated: true)
            
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
    
    func textValueDidChange(_ sender: UITableViewCell, _ text: String, _ input:Bool) {
        var removeGrothNotice = false
        var isNeedReload = true
        
        if let path = tableView.indexPath(for: sender)  {
            if path.section == 0 {
                viewModel.toAddress = text

                if viewModel.selectedContact != nil {
                    viewModel.selectedContact = nil
                    
                    if let cell = tableView.cellForRow(at: IndexPath(row: 0, section: 0)) as? BMSearchAddressCell {
                        cell.contact = nil
                    }
                }
                
                if input {
                    isSearch = true
                    
                    searchControlles[0].contacts = viewModel.searchForContacts(searchIndex: 0)
                    searchControlles[1].contacts = viewModel.searchForContacts(searchIndex: 1)
                    
                    for vc in searchControlles {
                        vc.reload()
                    }
                }
                else{
                    isSearch = false
                }
            }
            else if path.section == 1 {
                if input {
                    if viewModel.sendAll {
                        removeGrothNotice = true
                    }
                    viewModel.sendAll = false
                }
                viewModel.amount = text
            }
            else if path.section == 3 {
                isNeedReload = false
                viewModel.comment = text
            }
            else if path.section == 6 {
                isNeedReload = false
                viewModel.outgoindAdderss!.label = text
            }
        }
        
        if isNeedReload {
            UIView.performWithoutAnimation {
                tableView.beginUpdates()
                if removeGrothNotice {
                    tableView.deleteRows(at: [IndexPath(row: 1, section: 1)], with: .none)
                }
                tableView.endUpdates()
                if isSearch {
                    layoutSearchTableView()
                }
            }
        }
    }
    
    func textValueDidReturn(_ sender: UITableViewCell) {
        if let path = tableView.indexPath(for: sender)  {
            if path.section == 6 {
                AppModel.sharedManager().setWalletComment(viewModel.outgoindAdderss!.label, toAddress: viewModel.outgoindAdderss!.walletId)
            }
            else if path.section == 1 {
                viewModel.checkAmountError()
                if  viewModel.amountError != nil {
                    tableView.reloadRows(at: [IndexPath(row: 0, section: 1)], with: .none)
                }
            }
            else{
                if path.section == 0 {
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
                }
                
                if path.section == 0 && isSearch {
                    isSearch = false
                    tableView.reloadData()
                }
                else{
                    tableView.reloadRows(at: [path], with: .none)
                }
                
                if path.section == 0 && viewModel.amount.isEmpty && !viewModel.toAddress.isEmpty {
                    if let cell = tableView.findCell(BMAmountCell.self) as? BMAmountCell {
                        cell.beginEditing()
                    }
                }
            }
        }
    }
    
    func onRightButton(_ sender: UITableViewCell) {
        if let path = tableView.indexPath(for: sender) {
            if path.section == 0 {
                let vc = QRScannerViewController()
                vc.delegate = self
                pushViewController(vc: vc)
            }
            else if path.section == 2 {
                view.endEditing(true)
                viewModel.sendAll = true
                viewModel.checkFeeError()
                tableView.reloadData()
            }
            else if path.section == 5 {
                let vc = ReceiveListViewController()
                vc.completion = {[weak self]
                    obj in
                    
                    guard let strongSelf = self else { return }

                    strongSelf.viewModel.outgoindAdderss = obj
                    strongSelf.viewModel.pickedOutgoingAddress = BMAddress.fromAddress(obj)

                    strongSelf.tableView.reloadData()
                }
                vc.excepted = viewModel.startedAddress
                vc.currenltyPicked = viewModel.outgoindAdderss
                pushViewController(vc: vc)
            }
        }
    }
    
    func onExpandCell(_ sender: UITableViewCell) {
        if let path = tableView.indexPath(for: sender)
        {
            if path.section == 4 {
                showAdvanced = !showAdvanced
                
                if showAdvanced {
                    self.tableView.insertSections([5,6,7], with: .fade)
                }
                else{
                    self.tableView.deleteSections([5,6,7], with: .fade)
                }
            }
            else if path.section == 6 {
                showEdit = !showEdit

                if showEdit {
                    self.tableView.insertRows(at: [IndexPath(row: 1, section: path.section), IndexPath(row: 2, section: path.section), IndexPath(row: 3, section: path.section)], with: .fade)
                }
                else{
                    self.tableView.deleteRows(at: [IndexPath(row: 1, section: path.section), IndexPath(row: 2, section: path.section), IndexPath(row: 3, section: path.section)], with: .fade)
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

extension SendViewController : QRScannerViewControllerDelegate
{
    func didScanQRCode(value:String, amount:String?) {
        viewModel.selectedContact = nil
        
        if let a = amount {
            if Double(a) ?? 0 > 0 {
                viewModel.amount = a
                viewModel.sendAll = false
            }
        }
        
        didSelectAddress(value: value)
        
    }
}

extension SendViewController : SettingsModelDelegate {
    func onChangeHideAmounts() {
        addRightButton(image: Settings.sharedManager().isHideAmounts ? IconShowBalance() : IconHideBalance(), target: self, selector: #selector(onHideAmounts))

        if Settings.sharedManager().isHideAmounts {
            tableView.deleteRows(at: [IndexPath(row: 0, section: 2)], with: .fade)
        }
        else{
            tableView.insertRows(at: [IndexPath(row: 0, section: 2)], with: .fade)
        }
    }
}

extension SendViewController {
    
    private func onExpire() {
        let vc = BMDataPickerViewController(type: .address_expire)
        vc.completion = { [weak self]
            obj in
            
            guard let strongSelf = self else { return }

            let selected = obj as! Int32
            
            strongSelf.viewModel.outgoindAdderss!.duration = selected == 24 ? 86400 : 0
            
            AppModel.sharedManager().setExpires(Int32(selected), toAddress: strongSelf.viewModel.outgoindAdderss!.walletId)
            
            strongSelf.tableView.reloadRows(at: [IndexPath(row: 2, section: 6)], with: .fade)
        }
        pushViewController(vc: vc)
    }
    
    private func onCategory() {
        if AppModel.sharedManager().categories.count == 0 {
            let vc = CategoryEditViewController(category: nil)
            vc.completion = { [weak self]
                obj in
                guard let strongSelf = self else { return }
                
                if let category = obj {
                    strongSelf.didSelectCategory(categories: [String(category.id)])
                }
            }
            pushViewController(vc: vc)
        }
        else{
            let vc = CategoryPickerViewController(categories: viewModel.outgoindAdderss!.categories as? [String])
            vc.completion = { [weak self]
                obj in
                
                guard let strongSelf = self else { return }

                if let categories = obj {
                    strongSelf.didSelectCategory(categories: categories)
                }
            }
            pushViewController(vc: vc)
        }
    }
    
    private func didSelectCategory(categories:[String]) {
        viewModel.outgoindAdderss!.categories = NSMutableArray(array: categories)
        
        AppModel.sharedManager().setWalletCategories(viewModel.outgoindAdderss!.categories, toAddress: viewModel.outgoindAdderss!.walletId)
        
        tableView.reloadRows(at: [IndexPath(row: 3, section: 6)], with: .fade)
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
    
    func numberOfViewControllers<T>(in: PagingViewController<T>) -> Int{
        return titles.count
    }
}

extension SendViewController: SearchTableViewDelegate {
    func didSelectContact(contact: BMContact) {
        viewModel.selectedContact = contact
        didSelectAddress(value: contact.address.walletId)
    }
}
