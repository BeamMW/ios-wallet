//
// ReceiveViewController.swift
// BeamWallet
//
// Copyright 2026 Beam Development
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
    
    private let isNewAddressStyle = true
    
    override func viewDidLoad() {
        super.viewDidLoad()

        setGradientTopBar(mainColor: UIColor.main.brightSkyBlue)

        title = Localizable.shared.strings.receive.uppercased()

        AppModel.sharedManager().loadFullAssetsList()
        
        tableView.register([BMFieldCell.self, ReceiveTransactionTypeCell.self, BMExpandCell.self, BMAmountCell.self, ReceiveAddressButtonsCell.self])
        tableView.register(ReceiveTokenCell.self, forCellReuseIdentifier: ReceiveTokenCell.reuseIdentifier)
        tableView.register(UINib(nibName: "BMPickerCell3", bundle: nil), forCellReuseIdentifier: "BMPickerCell3")
        tableView.register(UINib(nibName: "BMPickerCell", bundle: nil), forCellReuseIdentifier: "BMPickerCell")

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
        
        viewModel.onAddressCreated = {[weak self] error in
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
                    if self?.viewModel.isSavedAddress == true {
                        self?.viewModel.isShared = true
                        
                        let isOwn = AppModel.sharedManager().checkIsOwnNode()
                        if isOwn {
                            let token = AppModel.sharedManager().isToken(self?.viewModel.address.address ?? "")
                            if token {
                                let params = AppModel.sharedManager().getTransactionParameters(self?.viewModel.address.address ?? "")
                                if params.newAddressType == BMAddressTypeMaxPrivacy {
                                    self?.viewModel.selectedTokenType = .maxPrivacy
                                }
                            }
                        }
                    }
                    
                    self?.tableView.delegate = self
                    self?.tableView.dataSource = self
                    self?.tableView.reloadData()
                }
            }
        }
        
        viewModel.onAddressUpdate = {[weak self] _ in
            UIView.performWithoutAnimation {
                guard let strongSelf = self else { return }

                strongSelf.tableView.beginUpdates()
                for cell in strongSelf.tableView.visibleCells {
                    if let amoutnCell = cell as? BMAmountCell {
                        amoutnCell.setSecondAmount(amount: strongSelf.viewModel.secondAmount ?? "")
                    }
                    else if let tokenCell = cell as? ReceiveTokenCell {
                        let token = strongSelf.viewModel.currentToken
                        tokenCell.configure(with: token, title: strongSelf.tokenCellTitle(), sbbsAddress: strongSelf.tokenCellSbbsAddress(for: token), showHint: false)
                    }
                }
                strongSelf.tableView.endUpdates()
            }
        }
        
        if let a = address {
            viewModel.isSavedAddress = true
            viewModel.address = a
            viewModel.isShared = true
            viewModel.generateTokens()
            viewModel.transactionComment = a.label
            tableView.delegate = self
            tableView.dataSource = self
            
            if AppModel.sharedManager().isToken(a.address) {
                let params = AppModel.sharedManager().getTransactionParameters(a.address ?? "")
                if params.assetId != 0 {
                    viewModel.selectedAssetId = Int(params.assetId)
                }
                
                if params.amount > 0 {
                    viewModel.amount = String.currency(value: params.amount).replacingOccurrences(of: " BEAM", with: "")
                }
            }
            
            tableView.reloadData()
        }
        else {
            viewModel.createAddress()
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
    
    private func sbbsAddress(for token: String) -> String? {
        guard !token.isEmpty, AppModel.sharedManager().isToken(token) else { return nil }
        let params = AppModel.sharedManager().getTransactionParameters(token)
        let sbbs = params.address ?? ""
        return sbbs.isEmpty ? nil : sbbs
    }

    fileprivate func tokenCellTitle() -> String {
        let base = Localizable.shared.strings.address.uppercased()
        if viewModel.selectedTokenType == .maxPrivacy {
            return "\(base) (\(Localizable.shared.strings.maximum_anonymity.lowercased()))"
        }
        return base
    }

    fileprivate func tokenCellSbbsAddress(for token: String) -> String? {
        if !AppModel.sharedManager().checkIsOwnNode() { return nil }
        return sbbsAddress(for: token)
    }

    @objc private func onBack() {
        let state = viewModel.isNeedAskToSave()
        if state != .none {
            self.confirmAndSkipAlert(title: state == .new ? Localizable.shared.strings.save_address_title : Localizable.shared.strings.save_changes, message: state == .new ? Localizable.shared.strings.save_address_text : Localizable.shared.strings.save_edit_address_text, cancelTitle: Localizable.shared.strings.not_save, confirmTitle: Localizable.shared.strings.save, cancelHandler: { [weak self] _ in
                self?.back()
            }, confirmHandler: { [weak self] _ in
                self?.viewModel.isShared = true
                self?.back()
            })
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
        else if section == 2 && isNewAddressStyle {
            return 0
        }
        return 20
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)

        if indexPath.section == 3 && indexPath.row == 1 && AppModel.sharedManager().checkIsOwnNode() {
            let picker = BMDataPickerViewController(type: .address_type, selectedValue: viewModel.selectedTokenType.rawValue)
            picker.completion = { [weak self] selected in
                guard let self = self,
                      let raw = selected as? Int,
                      let type = ReceiveAddressViewModel.ReceiveTokenType(rawValue: raw) else { return }
                self.view.endEditing(true)
                self.viewModel.selectedTokenType = type
                self.viewModel.generateTokens()
                self.tableView.reloadSections(IndexSet([3, 4]), with: .fade)
            }
            pushViewController(vc: picker)
        }
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
            if isNewAddressStyle {
                return 0
            } else {
                return showComment ? 2 : 1
            }
        }
        else if section == 3 {
            if !showAdvanced { return 1 }
            return viewModel.selectedTokenType.supportsVouchers ? 3 : 2
        }
        return 1
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        if indexPath.section == 0 {
            let cell = tableView
                .dequeueReusableCell(withType: ReceiveTokenCell.self, for: indexPath)
            cell.contentView.backgroundColor = UIColor.main.marineThree
            cell.delegate = self
            let token = viewModel.currentToken
            cell.configure(with: token, title: tokenCellTitle(), sbbsAddress: tokenCellSbbsAddress(for: token), showHint: false)
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
                cell.allowAllAssets = true
                cell.selectedAssetId = viewModel.selectedAssetId
                cell.contentView.backgroundColor = UIColor.main.marineThree
                cell.setSecondAmount(amount: viewModel.secondAmount ?? "")
                
                let isOwn = AppModel.sharedManager().checkIsOwnNode()
                if !isOwn  {
                    cell.disable()
                    cell.isUserInteractionEnabled = false
                } else {
                    cell.enable()
                }
                
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
                let isOwn = AppModel.sharedManager().checkIsOwnNode()
                
                let cell = tableView
                    .dequeueReusableCell(withType: BMFieldCell.self, for: indexPath)
                    .configured(with: (name: Localizable.shared.strings.comment.uppercased(), value: viewModel.transactionComment))
                cell.delegate = self
                cell.placholder = Localizable.shared.strings.local_comment
                cell.isItalicPlacholder = true
                cell.hideNameLabel = true
                cell.contentView.backgroundColor = UIColor.main.marineThree
                
                if !isOwn  {
                    cell.alpha = 0.5
                    cell.isUserInteractionEnabled = false
                } else {
                    cell.alpha = 1
                    cell.isUserInteractionEnabled = true
                }
                
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
                let isOwn = AppModel.sharedManager().checkIsOwnNode()
                let detail: String? = isOwn ? viewModel.selectedTokenType.localizedName : Localizable.shared.strings.connect_node_offline

                let cell = tableView
                    .dequeueReusableCell(withIdentifier: "BMPickerCell", for: indexPath) as! BMPickerCell
                cell.configure(data: BMPickerData(title: Localizable.shared.strings.address_type, detail: detail, titleColor: UIColor.white, arrowType: BMPickerData.ArrowType.selected, unique: 0, multiplie: false, isSwitch: false))

                if !isOwn {
                    cell.titleLabel.alpha = 0.5
                    cell.isUserInteractionEnabled = false
                } else {
                    cell.titleLabel.alpha = 1
                    cell.isUserInteractionEnabled = true
                }
                cell.botOffset?.constant = 20
                cell.backgroundColor = UIColor.clear
                cell.mainView.backgroundColor = UIColor.main.marineThree
                cell.contentView.backgroundColor = UIColor.main.marine

                return cell
            }
            else if indexPath.row == 2 {
                let isOwn = AppModel.sharedManager().checkIsOwnNode()

                let cell = tableView
                    .dequeueReusableCell(withType: BMFieldCell.self, for: indexPath)
                    .configured(with: (name: Localizable.shared.strings.vouchers_count.uppercased(), value: "\(viewModel.vouchersCount)"))
                cell.delegate = self
                cell.keyboardType = .numberPad
                cell.contentView.backgroundColor = UIColor.main.marineThree
                cell.info = String(format: Localizable.shared.strings.vouchers_count_hint, ReceiveAddressViewModel.maxVouchersCount)

                if !isOwn {
                    cell.alpha = 0.5
                    cell.isUserInteractionEnabled = false
                } else {
                    cell.alpha = 1
                    cell.isUserInteractionEnabled = true
                }

                return cell
            }
        }
        else if indexPath.section == 4 {
            let cell = tableView
                .dequeueReusableCell(withType: ReceiveAddressButtonsCell.self, for: indexPath)
            cell.delegate = self
            if viewModel.selectedTokenType == .maxPrivacy {
                var text = "\n\n" + Localizable.shared.strings.max_privacy_fee
                let locValue = Settings.sharedManager().currentMaxPrivacyLockValue()

                if locValue.hours == 0 {
                    text = Localizable.shared.strings.transaction_indefinitely + text
                }
                else {
                    text = String(format: Localizable.shared.strings.transaction_time, locValue.title) + text
                }

                cell.setText(text: text)
            }
            else if viewModel.selectedTokenType.supportsOnlineReceive {
                let isOwn = AppModel.sharedManager().checkIsOwnNode()
                if viewModel.selectedTokenType == .sbbs || !isOwn {
                    cell.setText(text: Localizable.shared.strings.receive_description_2)
                }
                else {
                    cell.setText(text: Localizable.shared.strings.receive_description)
                }
            }
            else if viewModel.selectedTokenType == .publicOffline {
                cell.setText(text: Localizable.shared.strings.public_offline_address_info)
            }
            else {
                cell.setText(text: "")
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
                            let token = viewModel.currentToken
                            tokenCell.configure(with: token, title: tokenCellTitle(), sbbsAddress: tokenCellSbbsAddress(for: token), showHint: viewModel.selectedTokenType != .maxPrivacy)
                        }
                    }
                    tableView.endUpdates()
                }
            }
            else if path.section == 3 && path.row == 2 {
                guard let fieldCell = sender as? BMFieldCell else { return }
                let trimmed = text.trimmingCharacters(in: .whitespaces)
                if trimmed.isEmpty {
                    fieldCell.error = nil
                    return
                }
                if let value = Int(trimmed), (1...ReceiveAddressViewModel.maxVouchersCount).contains(value) {
                    fieldCell.error = nil
                    viewModel.vouchersCount = value
                } else {
                    fieldCell.error = String(format: Localizable.shared.strings.vouchers_count_error, ReceiveAddressViewModel.maxVouchersCount)
                }
            }
        }
    }

    func textValueDidReturn(_ sender: UITableViewCell) {
        if let path = tableView.indexPath(for: sender), path.section == 3 && path.row == 2,
           let fieldCell = sender as? BMFieldCell {
            fieldCell.error = nil
            fieldCell.setText("\(viewModel.vouchersCount)")
        }
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
                self.tableView.reloadSections(IndexSet(integer: 3), with: .fade)
            }
        }
    }
    

    
    func onClickCopy() {
        self.view.endEditing(true)

        viewModel.isShared = true
    }
    
    
    func onRightButton(_ sender: UITableViewCell) {
        guard tableView.indexPath(for: sender) != nil, sender is BMAmountCell else { return }
        view.endEditing(true)

        let picker = AssetSearchViewController(selectedAssetId: viewModel.selectedAssetId ?? 0)
        picker.completion = { [weak self] asset in
            guard let self = self else { return }
            self.viewModel.selectedAssetId = Int(asset.assetId)
            self.viewModel.amount = nil
            self.tableView.reloadData()
        }
        let nav = BaseNavigationController.navigationController(rootViewController: picker)
        nav.modalPresentationStyle = .fullScreen
        present(nav, animated: true, completion: nil)
    }
}

extension ReceiveViewController : ReceiveAddressTokensCellDelegate {
    
    @objc func onSwitchToPool() {
        viewModel.selectedTokenType = .regular
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
            modalViewController.isMaxPrivacy = viewModel.selectedTokenType == .maxPrivacy
            modalViewController.isSbbsOnly = viewModel.selectedTokenType == .sbbs
            modalViewController.isPublicOffline = viewModel.selectedTokenType == .publicOffline
            
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
        onShareToken(token: viewModel.currentToken)
    }

    func onClickCopyAndClose() {
        let token = viewModel.currentToken
        guard !token.isEmpty else { return }
        UIPasteboard.general.string = token
        viewModel.isShared = true
        ShowCopied(text: Localizable.shared.strings.address_copied)
        back()
    }
}

extension ReceiveViewController : ReceiveTransactionTypeCellDelegate {

    func onDidSelectTrasactionType(type: ReceiveAddressViewModel.TransactionOptions) {
        viewModel.selectedTokenType = (type == .privacy) ? .maxPrivacy : .regular
        viewModel.generateTokens()

        UIView.performWithoutAnimation {
            self.tableView.reloadRow(ReceiveTokenCell.self, animated: false)
            self.tableView.reloadRow(ReceiveAddressButtonsCell.self, animated: false)
        }
    }

    func onShareToken() {
        viewModel.isShared = true
    }
}


extension ReceiveViewController: SearchTableViewDelegate {
    func didSelectContact(contact: BMContact) {
        isSearch = false
    }
}
