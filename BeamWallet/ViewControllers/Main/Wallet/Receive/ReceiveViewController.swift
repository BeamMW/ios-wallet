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
    public var address: BMAddress?

    private var showRequestAmount = false
    private var showComment = false
    private var showAdvanced = false

    private var searchTableView = SearchTableView()
    private var isSearch = false {
        didSet {
            tableView.isScrollEnabled = !isSearch
            searchTableView.view.isHidden = !isSearch
            
            layoutSearchTableView()
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
    
    public var assetId = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()
                
        setGradientTopBar(mainColor: UIColor.main.brightSkyBlue)
        
        title = Localizable.shared.strings.receive.uppercased()
        
        tableView.register([BMFieldCell.self, ReceiveTransactionTypeCell.self, ReceiveTokenCell.self, BMExpandCell.self, BMAmountCell.self, ReceiveAddressButtonsCell.self])
        tableView.register(UINib(nibName: "BMPickerCell3", bundle: nil), forCellReuseIdentifier: "BMPickerCell3")

        tableView.keyboardDismissMode = .interactive
        tableView.contentInsetAdjustmentBehavior = .never
        tableView.tableHeaderView = UIView(frame: CGRect(x: 0.0, y: 0.0, width: 0.0, height: 10))
        tableView.tableHeaderView?.backgroundColor = UIColor.clear
        tableView.sectionHeaderHeight = 0.0
        tableView.sectionFooterHeight = 0.0
        
        searchTableView.view.isHidden = !isSearch
        searchTableView.tableView.contentInsetAdjustmentBehavior = .never
        searchTableView.view.backgroundColor = self.view.backgroundColor
        searchTableView.delegate = self
        searchTableView.displayEmpty = false
        searchTableView.tableView.contentInset = tableView.contentInset
        self.view.addSubview(searchTableView.view)
        
        viewModel.onDataChanged = { [weak self] in
            self?.tableView.reloadData()
        }
        
        viewModel.onShared = { [weak self] in
            self?.back()
        }
        
        viewModel.onAddressCreated = {[weak self]
            error in
            DispatchQueue.main.async {
                if let reason = error?.localizedDescription {
                    self?.alert(title: Localizable.shared.strings.error, message: reason, handler: { (_ ) in
                        self?.back()
                    })
                }
                else{
                    if self?.assetId != 0 && self?.assetId != self?.viewModel.selectedAssetId {
                        self?.viewModel.selectedAssetId = self?.assetId ?? 0
                    }
                    self?.tableView.delegate = self
                    self?.tableView.dataSource = self
                    self?.tableView.reloadData()
                }
            }
        }
        
        viewModel.onAddressUpdate = {[weak self]
            error in
            UIView.performWithoutAnimation {
                guard let strongSelf = self else { return }

                strongSelf.tableView.beginUpdates()
                for cell in strongSelf.tableView.visibleCells {
                    if let amoutnCell = cell as? BMAmountCell {
                        amoutnCell.setSecondAmount(amount: strongSelf.viewModel.secondAmount ?? "")
                    }
                    else if let tokenCell = cell as? ReceiveTokenCell {
                        if strongSelf.viewModel.transaction == .regular {
                            tokenCell.configure(with: strongSelf.viewModel.address.offlineToken ?? "", title: Localizable.shared.strings.address.uppercased())
                        }
                        else {
                            tokenCell.configure(with: strongSelf.viewModel.address.maxPrivacyToken ?? "", title: "\(Localizable.shared.strings.address.uppercased()) (\(Localizable.shared.strings.maximum_anonymity.lowercased())")
                        }
                    }
                }
                strongSelf.tableView.endUpdates()
            }
        }
        
        if let a = address {
            viewModel.isShared = true
            viewModel.address = a
            viewModel.generateTokens()
            tableView.delegate = self
            tableView.dataSource = self
            tableView.reloadData()
        }
        else {
            viewModel.createAddress()

            if self.assetId == 0 {
            }
            else {
            }
        }
        
        
        addCustomBackButton(target: self, selector: #selector(onBack))
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        layoutSearchTableView()
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
    
    private func layoutSearchTableView() {
        let rect = tableView.rectForRow(at: IndexPath(row: 0, section: 0))
        let y: CGFloat = navigationBarOffset + rect.size.height + 20
        
        searchTableView.view.frame = CGRect(x: 0, y: y, width: view.bounds.width, height: view.bounds.size.height - y)
    }
    
    @objc private func onBack() {
        let state = viewModel.isNeedAskToSave()
        if state != .none {
            self.confirmAndSkipAlert(title: state == .new ? Localizable.shared.strings.save_address_title : Localizable.shared.strings.save_changes, message: state == .new ? Localizable.shared.strings.save_address_text : Localizable.shared.strings.save_edit_address_text, cancelTitle: Localizable.shared.strings.not_save, confirmTitle: Localizable.shared.strings.save, cancelHandler: { [weak self] (_ ) in
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
        if section == 0 {
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

extension ReceiveViewController : UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 5
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            return 1
        }
        else if section == 1 {
            return showRequestAmount ? 2 : 1
        }
        else if section == 2 {
            return showComment ? 2 : 1
        }
        else if section == 3 {
            return showAdvanced ? 2 : 1
        }
        return 1
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        if indexPath.section == 0 {
            let cell = tableView
                .dequeueReusableCell(withType: ReceiveTokenCell.self, for: indexPath)
            cell.contentView.backgroundColor = UIColor.main.marineThree
            cell.delegate = self
            if viewModel.transaction == .regular {
                if !AppModel.sharedManager().checkIsOwnNode() {
                    cell.configure(with: viewModel.address.walletId, title: Localizable.shared.strings.address.uppercased())
                }
                else {
                    cell.configure(with: viewModel.address.offlineToken ?? "", title: Localizable.shared.strings.address.uppercased())
                }
            }
            else {
                cell.configure(with: viewModel.address.maxPrivacyToken ?? "", title: "\(Localizable.shared.strings.address.uppercased()) (\(Localizable.shared.strings.maximum_anonymity.lowercased()))")
            }
            return cell
        }
        else if indexPath.section == 1  {
            if indexPath.row == 0 {
                let cell = tableView
                    .dequeueReusableCell(withType: BMExpandCell.self, for: indexPath)
                    .configured(with: (expand: showRequestAmount, title: "\(Localizable.shared.strings.requested_amount.uppercased()) (\(Localizable.shared.strings.optional.lowercased()))"))
                cell.delegate = self
                cell.setColor(UIColor.white)
                cell.topOffset?.constant = 15
                cell.botOffset?.constant = 15
                return cell
            }
            else if indexPath.row == 1  {
                let cell = tableView
                    .dequeueReusableCell(withType: BMAmountCell.self, for: indexPath).configured(with: (name: String.empty(), value: viewModel.amount))
                cell.delegate = self
                cell.hideNameLabel = true
                cell.currency = viewModel.selectedCurrencyString
                cell.contentView.backgroundColor = UIColor.main.marineThree
                cell.setSecondAmount(amount: viewModel.secondAmount ?? "")
                return cell
            }
        }
        else if indexPath.section == 2  {
            if indexPath.row == 0 {
                let cell = tableView
                    .dequeueReusableCell(withType: BMExpandCell.self, for: indexPath)
                    .configured(with: (expand: showComment, title: Localizable.shared.strings.comment.uppercased()))
                cell.delegate = self
                cell.setColor(UIColor.white)
                cell.topOffset?.constant = 15
                cell.botOffset?.constant = 15
                return cell
            }
            else if indexPath.row == 1  {
                let cell = tableView
                    .dequeueReusableCell(withType: BMFieldCell.self, for: indexPath)
                    .configured(with: (name: Localizable.shared.strings.comment.uppercased(), value: viewModel.transactionComment))
                cell.delegate = self
                cell.placholder = Localizable.shared.strings.local_comment
                cell.isItalicPlacholder = true
                cell.hideNameLabel = true
                cell.contentView.backgroundColor = UIColor.main.marineThree
                return cell
            }
        }
        else if indexPath.section == 3  {
            if indexPath.row == 0 {
                let cell = tableView
                    .dequeueReusableCell(withType: BMExpandCell.self, for: indexPath)
                    .configured(with: (expand: showAdvanced, title: Localizable.shared.strings.advanced.uppercased()))
                cell.delegate = self
                cell.setColor(UIColor.white)
                cell.topOffset?.constant = 15
                cell.botOffset?.constant = 15
                return cell
            }
            else if indexPath.row == 1  {
                let detail = !AppModel.sharedManager().checkIsOwnNode() ? Localizable.shared.strings.connect_node_offline : nil
                
                let cell = tableView
                    .dequeueReusableCell(withIdentifier: "BMPickerCell3", for: indexPath) as! BMPickerCell
                cell.configure(data: BMPickerData(title: Localizable.shared.strings.maximum_anonymity_set, detail: nil, titleColor: UIColor.white, arrowType: viewModel.transaction == .privacy ? BMPickerData.ArrowType.selected : BMPickerData.ArrowType.unselected, unique: 0, multiplie: false, isSwitch: true))
                
                if detail != nil {
                    cell.titleLabel.alpha = 0.5
                    cell.switchView.alpha = 0.5
                    cell.isUserInteractionEnabled = false
                }
                cell.botOffset?.constant = 20
                cell.delegate = self
                
                return cell
            }
        }
        else if indexPath.section == 4 {
            let cell = tableView
                .dequeueReusableCell(withType: ReceiveAddressButtonsCell.self, for: indexPath)
            cell.delegate = self
            if viewModel.transaction == .privacy {
                var text = "\n\n" + Localizable.shared.strings.max_privacy_fee
                let locValue = Settings.sharedManager().currentMaxPrivacyLockValue()
                
                if locValue.hours == 0 {
                    text = Localizable.shared.strings.transaction_indefinitely + text
                }
                else {
                    text = String(format: Localizable.shared.strings.transaction_time, locValue.name) + text
                }
                
                cell.setText(text: text)
            }
            else {
                if !AppModel.sharedManager().checkIsOwnNode() {
                    cell.setText(text: Localizable.shared.strings.receive_description_2)
                }
                else {
                    cell.setText(text: Localizable.shared.strings.receive_description)
                }
            }
            return cell
        }

        return BaseCell()
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let view = UIView()
        view.backgroundColor = UIColor.clear
        return view
    }
}

extension ReceiveViewController : BMCellProtocol {
    
    func textValueDidBegin(_ sender: UITableViewCell) {
        if let path = tableView.indexPath(for: sender) {
            
            if path.section == 0 {
//                isSearch = true
//
//                searchTableView.contacts = viewModel.searchForContacts()
//                if searchTableView.contacts.count == 0 {
//                    isSearch = false
//                }
//                else {
//                    isSearch = true
//                    searchTableView.reload()
//                }
            }
        }
    }
    
    func textValueDidChange(_ sender: UITableViewCell, _ text: String, _ input:Bool) {
        if let path = tableView.indexPath(for: sender) {
             if path.section == 2 {
                viewModel.transactionComment = text
            }
            else if path.section == 1 {
                viewModel.amount = text
                
                UIView.performWithoutAnimation {
                    tableView.beginUpdates()
                    for cell in tableView.visibleCells {
                        if let amoutnCell = cell as? BMAmountCell {
                            amoutnCell.setSecondAmount(amount: viewModel.secondAmount ?? "")
                        }
                        else if let tokenCell = cell as? ReceiveTokenCell {
                            if viewModel.transaction == .regular {
                                tokenCell.configure(with: viewModel.address.offlineToken ?? "", title: Localizable.shared.strings.address.uppercased())
                            }
                            else {
                                tokenCell.configure(with: viewModel.address.maxPrivacyToken ?? "", title: "\(Localizable.shared.strings.address.uppercased()) (\(Localizable.shared.strings.maximum_anonymity.lowercased())")
                            }
                        }
                    }
                    tableView.endUpdates()
                }
            }
        }
    }
    
    func textValueDidReturn(_ sender: UITableViewCell) {

    }
    
    func onExpandCell(_ sender: UITableViewCell) {
        if let path = tableView.indexPath(for: sender) {
            if path.section == 2 {
                showComment = !showComment
                
                if showComment {
                    self.tableView.insertRows(at: [IndexPath(row: 1, section: 2)], with: .fade)
                }
                else{
                    self.tableView.deleteRows(at: [IndexPath(row: 1, section: 2)], with: .fade)
                }
            }
            else if path.section == 1 {
                showRequestAmount = !showRequestAmount

                if showRequestAmount {
                    self.tableView.insertRows(at: [IndexPath(row: 1, section: 1)], with: .fade)
                }
                else{
                    self.tableView.deleteRows(at: [IndexPath(row: 1, section: 1)], with: .fade)
                }
            }
            else if path.section == 3 {
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
    

    
    func onClickCopy() {
        self.view.endEditing(true)

        viewModel.isShared = true
    }
    
    
    func onRightButton(_ sender: UITableViewCell) {
        if tableView.indexPath(for: sender) != nil, let cell = sender as? BMAmountCell {
            var menu = [BMPopoverMenu.BMPopoverMenuItem]()
            
            for asset in AssetsManager.shared().getAssetsWithBalanceWithBeam() as! [BMAsset] {
                var m = BMPopoverMenu.BMPopoverMenuItem(name: asset.unitName, icon: nil, action: .asset, selected:  self.viewModel.selectedAssetId == Int(asset.assetId))
                m.id = Int(asset.assetId)
                menu.append(m)
            }
            
            BMPopoverMenu.showForSenderAssets(sender: cell.currencyLabel, with: menu) { item in
                let itemName = item?.name ?? ""
                let asset = AssetsManager.shared().getAsset(Int32(item?.id ?? 0))
                self.viewModel.selectedAssetId = Int(asset?.assetId ?? 0)
                self.viewModel.amount = nil
                self.tableView.reloadData()
                
            } cancel: {
                self.tableView.reloadData()
            }
        }
    }
}

extension ReceiveViewController : ReceiveAddressTokensCellDelegate {
    
    @objc func onSwitchToPool() {
        viewModel.transaction = .regular
       // viewModel.expire = .parmanent
        viewModel.needReloadButtons = true
        self.tableView.reloadData()
    }
    
    @objc func onShowToken(token: String) {
        let vc = ShowTokenViewController(token: token, send: false)
        vc.isNewStyle = true
        vc.didCopyToken = { [weak self] in
            self?.viewModel.isShared = true
        }
        vc.isMiningPool = false
        self.pushViewController(vc: vc)
    }
    
    @objc func onShowQR(token: String) {
        if let top = UIApplication.getTopMostViewController() {
            viewModel.isShared = true
            
            let qrString = AppModel.sharedManager().generateQRCodeString(token, amount: nil)

            let modalViewController = QRCodeSmallViewController(qrString: qrString)
            modalViewController.onShared = { [weak self] in
                self?.onBack()
            }
            modalViewController.isMaxPrivacy = viewModel.transaction == ReceiveAddressViewModel.TransactionOptions.privacy
            
            modalViewController.modalPresentationStyle = .overFullScreen
            modalViewController.modalTransitionStyle = .crossDissolve
            top.present(modalViewController, animated: true, completion: nil)
        }
    }
    
    func onCopyToken(token: String) {
        UIPasteboard.general.string = token

        viewModel.isShared = true

        ShowCopied(text: Localizable.shared.strings.address_copied)
    }
    
    func onShareToken(token: String) {
        viewModel.onShare(token: token)
    }
    
    func onClickShare() {
        if viewModel.transaction == .privacy {
            onShareToken(token: viewModel.address.maxPrivacyToken ?? "")
        }
        else {
            if !AppModel.sharedManager().checkIsOwnNode() {
                onShareToken(token: viewModel.address.walletId)
            }
            else {
                onShareToken(token: viewModel.address.offlineToken ?? "")
            }
        }
    }
}

extension ReceiveViewController : ReceiveTransactionTypeCellDelegate, BMPickerCellDelegate {
    
    func onDidSelectTrasactionType(type: ReceiveAddressViewModel.TransactionOptions) {
        viewModel.transaction = type
        
        UIView.performWithoutAnimation {
            self.tableView.reloadRow(ReceiveTokenCell.self, animated: false)
            self.tableView.reloadRow(ReceiveAddressButtonsCell.self, animated: false)
        }
    }
    
    func onShareToken() {
        viewModel.isShared = true
    }
    
    func onClickSwitch(value: Bool, cell: BMPickerCell) {
        if value {
            viewModel.transaction = .privacy
        }
        else {
            viewModel.transaction = .regular
        }
        
        UIView.performWithoutAnimation {
            self.tableView.reloadData()
        }
    }
}


extension ReceiveViewController: SearchTableViewDelegate {
    func didSelectContact(contact: BMContact) {
        isSearch = false
    }
}
