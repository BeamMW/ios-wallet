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
    
    private var showAdvanced = false
    private var showEdit = false

    override var tableStyle: UITableView.Style {
        get {
            return .grouped
        }
        set {
            super.tableStyle = newValue
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
                
        setGradientTopBar(mainColor: UIColor.main.brightSkyBlue)
        
        title = Localizable.shared.strings.receive.uppercased()
        
        tableView.register([BMFieldCell.self, ReceiveAddressButtonsCell.self, BMAmountCell.self, BMExpandCell.self, BMDetailCell.self, ReceiveAddressOptionsCell.self, ReceiveAddressTokensCell.self])
        tableView.register(UINib(nibName: "BMPickerCell3", bundle: nil), forCellReuseIdentifier: "BMPickerCell3")
        tableView.keyboardDismissMode = .interactive
        tableView.contentInsetAdjustmentBehavior = .never
        tableView.tableHeaderView = UIView(frame: CGRect(x: 0.0, y: 0.0, width: 0.0, height: 10))
        tableView.tableHeaderView?.backgroundColor = UIColor.clear
        tableView.sectionHeaderHeight = 0.0
        tableView.sectionFooterHeight = 0.0
        
        viewModel.onDataChanged = { [weak self] in
            self?.tableView.reloadData()
        }
        
        viewModel.onShared = { [weak self] in
            self?.back()
        }
        
        viewModel.onAddressCreated = {[weak self]
            error in
            
            if let reason = error?.localizedDescription {
                self?.alert(title: Localizable.shared.strings.error, message: reason, handler: { (_ ) in
                    self?.back()
                })
            }
            else{
                self?.tableView.delegate = self
                self?.tableView.dataSource = self
                self?.tableView.reloadData()
            }
        }
        viewModel.createAddress()
        
        addCustomBackButton(target: self, selector: #selector(onBack))
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

    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        switch section {
        case 0:
            return 0
        case 1:
            return 5
        case 3:
            return showAdvanced ? 15 : 5
        default:
            return 20
        }
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        switch section {
        case 0:
            return 0
        case 1, 3:
            return 5
        case 2:
            return 20
        case 4:
            return 20
        default:
            return 30
        }
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if indexPath.section == 3 && indexPath.row == 2 {
            let amount = Double(viewModel.amount ?? "0") ?? 0
            if amount > 0 {
                return 17
            }
            else {
                return 0
            }
        }
        return UITableView.automaticDimension
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        switch indexPath.section {
        case 1:
            if indexPath.row == 2 {
                viewModel.onCategory()
            }
        default:
            return
        }
    }
}

extension ReceiveViewController : UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 5
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 1 {
            if viewModel.expire == .parmanent {
                return showEdit ? 3 : 1
            }
            return 0
        }
        else if section == 3 {
            return showAdvanced ? 3 : 1
        }
        else if section == 2 {
            return 1
        }
        else if section == 0 {
            return 2
        }
        return 1
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
       
        switch indexPath.section {
        case 0:
            if indexPath.row == 0 {
                let cell = tableView
                    .dequeueReusableCell(withType: ReceiveAddressOptionsCell.self, for: indexPath)
                cell.contentView.backgroundColor = UIColor.main.marineThree
                cell.configure(with: (oneTime: viewModel.expire == .oneTime, maxPrivacy: viewModel.transaction == .privacy, needReload: viewModel.needReloadButtons))
                cell.delegate = self
                return cell
            }
            else {
                let cell = tableView
                    .dequeueReusableCell(withType: ReceiveAddressTokensCell.self, for: indexPath)
                cell.contentView.backgroundColor = UIColor.main.marineThree
                cell.configure(with: (oneTime: viewModel.expire == .oneTime, maxPrivacy: viewModel.transaction == .privacy, address: viewModel.address))
                cell.delegate = self
                return cell
            }
        case 1:
            if indexPath.row == 0 {
                let cell = tableView
                    .dequeueReusableCell(withType: BMExpandCell.self, for: indexPath)
                    .configured(with: (expand: showEdit, title: Localizable.shared.strings.edit_token.uppercased()))
                cell.delegate = self
                cell.setColor(UIColor.white)
                return cell
            }
            else if indexPath.row == 1 {
                let cell = tableView
                    .dequeueReusableCell(withType: BMFieldCell.self, for: indexPath)
                    .configured(with: (name: Localizable.shared.strings.name.uppercased(), value: viewModel.address.label))
                cell.delegate = self
                cell.contentView.backgroundColor = UIColor.main.marineThree
                return cell
            }
            else{
                let cell = tableView
                    .dequeueReusableCell(withType: BMDetailCell.self, for: indexPath)
                cell.simpleConfigure(with: (title: Localizable.shared.strings.category.uppercased(), attributedValue: viewModel.address.categoriesName()))
                cell.space = 20
                return cell
            }
        case 2:
            let cell = tableView
                .dequeueReusableCell(withType: BMFieldCell.self, for: indexPath)
                .configured(with: (name: Localizable.shared.strings.comment.uppercased(), value: viewModel.transactionComment))
            cell.delegate = self
            cell.contentView.backgroundColor = UIColor.clear
            return cell
        case 3:
            if indexPath.row == 0 {
                let cell = tableView
                    .dequeueReusableCell(withType: BMExpandCell.self, for: indexPath)
                    .configured(with: (expand: showAdvanced, title: Localizable.shared.strings.advanced.uppercased()))
                cell.delegate = self
                cell.setColor(UIColor.white)
                return cell
            }
            else if indexPath.row == 1  {
                let cell = tableView
                    .dequeueReusableCell(withType: BMAmountCell.self, for: indexPath).configured(with: (name: Localizable.shared.strings.request_amount, value: viewModel.amount))
                cell.delegate = self
                cell.contentView.backgroundColor = UIColor.main.marineThree
                return cell
            }
            else {
                var cell = tableView.dequeueReusableCell(withIdentifier: "cell")
                
                if cell == nil {
                    cell = SecondCell(style: .default, reuseIdentifier: "cell")
                    
                    cell?.textLabel?.textColor = UIColor.main.blueyGrey
                    cell?.textLabel?.font = RegularFont(size: 14)
                    
                    cell?.backgroundColor = UIColor.clear
                    cell?.contentView.backgroundColor = UIColor.main.marineThree
                    cell?.selectionStyle = .none
                    cell?.separatorInset = UIEdgeInsets.zero
                    cell?.indentationLevel = 0
                }
                
                let amount = Double(viewModel.amount ?? "0") ?? 0
                let second = AppModel.sharedManager().exchangeValue(amount)
                
                if amount > 0 {
                    cell?.textLabel?.text = second
                }
                else {
                    cell?.textLabel?.text = nil
                }
                
                if Settings.sharedManager().isDarkMode {
                    cell?.textLabel?.textColor = UIColor.main.steel
                }
                
                return cell!
            }
        case 4:
            let cell = tableView
                .dequeueReusableCell(withType: ReceiveAddressButtonsCell.self, for: indexPath)
            cell.delegate = self
            cell.setMaxPrivacy(viewModel.transaction == .privacy)
            return cell
        default:
            return BaseCell()
        }
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let view = UIView()
        switch section {
        case 1, 3:
            view.backgroundColor = UIColor.main.marineThree
        default:
            view.backgroundColor = UIColor.clear
        }

        return view
    }
    
    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        let view = UIView()
        switch section {
        case 1, 3:
            view.backgroundColor = UIColor.main.marineThree
        default:
            view.backgroundColor = UIColor.clear
        }
        
        return view
    }
}

extension ReceiveViewController : BMCellProtocol {
    
    func textValueDidBegin(_ sender: UITableViewCell) {
        if let path = tableView.indexPath(for: sender)  {
            tableView.scrollToRow(at: path, at: .middle, animated: true)
        }
    }
    
    func textValueDidChange(_ sender: UITableViewCell, _ text: String, _ input:Bool) {
        if let path = tableView.indexPath(for: sender) {
            if path.section == 1 {
                viewModel.address.label = text
            }
            else if path.section == 2 {
                viewModel.transactionComment = text
            }
            else if path.section == 3 {
                viewModel.amount = text
                tableView.reloadRows(at: [IndexPath(row: 2, section: 3)], with: .none)
                tableView.reloadRow(ReceiveAddressOptionsCell.self, animated: false)
            }
        }
    }
    
    func textValueDidReturn(_ sender: UITableViewCell) {
        if let path = tableView.indexPath(for: sender) {
            if path.section == 1 {
                AppModel.sharedManager().setWalletComment(viewModel.address.label, toAddress: viewModel.address.walletId)
            }
            else if path.section == 3 {
                
            }
        }
    }
    
    func onExpandCell(_ sender: UITableViewCell) {
        if let path = tableView.indexPath(for: sender)
        {
            if path.section == 1 {
                showEdit = !showEdit
                
                if showEdit {
                    self.tableView.insertRows(at: [IndexPath(row: 1, section: 1), IndexPath(row: 2, section: 1)], with: .fade)
                }
                else{
                    self.tableView.deleteRows(at: [IndexPath(row: 1, section: 1), IndexPath(row: 2, section: 1)], with: .fade)
                }
            }
            else{
                showAdvanced = !showAdvanced

                if showAdvanced {
                    self.tableView.insertRows(at: [IndexPath(row: 1, section: 3), IndexPath(row: 2, section: 3)], with: .fade)
                }
                else{
                    self.tableView.deleteRows(at: [IndexPath(row: 1, section: 3), IndexPath(row: 2, section: 3)], with: .fade)
                }
            }
        }
    }
    

    func onClickShare() {
        self.view.endEditing(true)
        
        viewModel.onShare()
    }
    
    func onClickCopy() {
        self.view.endEditing(true)

        viewModel.isShared = true
    }
}

extension ReceiveViewController : ReceiveAddressTokensCellDelegate {
    
    @objc func onSwitchToPool() {
        viewModel.transaction = .regular
        viewModel.expire = .parmanent
        viewModel.needReloadButtons = true
        self.tableView.reloadData()
    }
    
    @objc func onShowToken(token: String) {
        let vc = ShowTokenViewController(token: token, send: false)
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
            modalViewController.modalPresentationStyle = .overFullScreen
            modalViewController.modalTransitionStyle = .crossDissolve
            top.present(modalViewController, animated: true, completion: nil)
        }
    }
}

extension ReceiveViewController : ReceiveAddressOptionsCellDelegate {
    @objc func onRegular() {
        viewModel.transaction = .regular
        viewModel.needReloadButtons = false
        self.tableView.reloadData()
    }
    
    @objc func onMaxPrivacy() {
        viewModel.transaction = .privacy
        viewModel.needReloadButtons = false
        self.tableView.reloadData()
    }
    
    @objc func onOneTime() {
        viewModel.expire = .oneTime
        viewModel.needReloadButtons = false
        self.tableView.reloadData()
    }
    
    @objc func onPermament() {
        viewModel.expire = .parmanent
        viewModel.needReloadButtons = false
        self.tableView.reloadData()
    }
}
