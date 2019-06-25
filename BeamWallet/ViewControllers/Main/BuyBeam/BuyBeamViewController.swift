//
// BuyBeamViewController.swift
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

import Foundation

class BuyBeamViewController: BaseTableViewController {
    
    private let viewModel = BuyBeamViewModel()
    private var showEdit = false

    private lazy var footerView: UIView = {
        
        let text = Localizables.shared.strings.star_transaction_notice
        let range = (text as NSString).range(of: String(Localizables.shared.strings.terms_of_use))
        
        let titleParagraphStyle = NSMutableParagraphStyle()
        titleParagraphStyle.alignment = .center
        
        let attributedString = NSMutableAttributedString(string:text)
        attributedString.addAttribute(NSAttributedString.Key.foregroundColor, value: UIColor.main.brightTeal.withAlphaComponent(0.6) , range: range)
        attributedString.addAttribute(NSAttributedString.Key.paragraphStyle, value: titleParagraphStyle, range: NSMakeRange(0, text.count))

        let label = UILabel(frame: CGRect(x: defaultX, y: 30, width: defaultWidth, height: 0))
        label.font = ItalicFont(size: 16)
        label.textColor = UIColor.white
        label.attributedText = attributedString
        label.numberOfLines = 0
        label.textAlignment = .center
        label.isUserInteractionEnabled = true
        label.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(titleLabelTapGestureAction(_:))))
        label.sizeToFit()
        label.frame = CGRect(x: defaultX, y: 30, width: defaultWidth, height: label.frame.size.height);
        
        let view = UIView(frame: CGRect(x: 0, y: 0, width: UIScreen.main.bounds.size.width, height:0))
        view.addSubview(label)
        
        let button = BMButton.defaultButton(frame: CGRect(x: (UIScreen.main.bounds.size.width-200)/2, y: label.frame.origin.y + label.frame.size.height + 30, width: 200, height: 44), color: UIColor.main.heliotrope.withAlphaComponent(0.1))
        button.setImage(IconNextPink(), for: .normal)
        button.setTitle(Localizables.shared.strings.start_transaction.lowercased(), for: .normal)
        button.layer.borderWidth = 1
        button.layer.borderColor = UIColor.main.heliotrope.cgColor
        button.setTitleColor(UIColor.main.heliotrope, for: .normal)
        button.addTarget(self, action: #selector(onNext), for: .touchUpInside)
        view.addSubview(button)
        
        view.frame = CGRect(x: 0, y: 0, width: UIScreen.main.bounds.size.width, height:button.frame.origin.y + button.frame.size.height + 30)
        
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
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        isGradient = true
        
        setGradientTopBar(mainColor: UIColor.main.heliotrope, addedStatusView: false)
        
        title = Localizables.shared.strings.buy_beam.uppercased()
        
        tableView.register([BMFieldCell.self, BMAmountCell.self, BuyGetCell.self, BMPickedAddressCell.self, BMSearchAddressCell.self, BMExpandCell.self, BMDetailCell.self])
        
        tableView.delegate = self
        tableView.dataSource = self
        tableView.keyboardDismissMode = .interactive
        tableView.tableFooterView = footerView
        
        subscribeToChages()
        
        viewModel.createAddress()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        self.view.endEditing(true)
        
        if isMovingFromParent {
            viewModel.revertChanges()
        }
    }
    
    private func subscribeToChages() {
        viewModel.onDataChanged = {
            [weak self] in
            
            guard let strongSelf = self else { return }

            strongSelf.tableView.reloadData()
        }
        
        viewModel.onCalculationChange = {
            [weak self] in

            guard let strongSelf = self else { return }

            if let cell = strongSelf.tableView.cellForRow(at: IndexPath(row: 1, section: 0)) {
                if strongSelf.viewModel.loading {
                    cell.textLabel?.text = Localizables.shared.strings.min_amount_loading
                }
                else{
                    cell.textLabel?.text = strongSelf.viewModel.minimumAmount
                }
            }
            
            if let cell = strongSelf.tableView.cellForRow(at: IndexPath(row: 0, section: 1)) as? BuyGetCell {
                cell.configure(with: strongSelf.viewModel.receiveAmount)
                cell.isLoading = strongSelf.viewModel.loading
            }
        }
        
        viewModel.onAddressCreated = {[weak self]
            error in
            
            guard let strongSelf = self else { return }

            if let reason = error?.localizedDescription {
                strongSelf.alert(title: Localizables.shared.strings.error, message: reason, handler: { (_ ) in
                    strongSelf.back()
                })
            }
            else{
                strongSelf.tableView.reloadData()
            }
        }
    }
    
    @objc private func onNext() {
        if viewModel.onCanSend() {
            
            SVProgressHUD.show()

            viewModel.submitOrder {[weak self] (response, error) in
                
                SVProgressHUD.dismiss()

                guard let strongSelf = self else { return }                

                if let reason = error?.localizedDescription {
                    strongSelf.alert(message: reason)
                }
                else if let reason = response?.error {
                    strongSelf.alert(message: reason)
                }
                else if response != nil {
                    let vc = BuyBeamOrderViewController(order: response!, amount: strongSelf.viewModel.amount!, currency: strongSelf.viewModel.currency, receiveAmount: strongSelf.viewModel.receiveAmount)
                    strongSelf.pushViewController(vc: vc)
                }
            }
        }
        else{
            tableView.reloadData()
        }
    }
    
    @objc private func titleLabelTapGestureAction(_ sender: UITapGestureRecognizer) {
        let label = sender.view as! UILabel
        
        if let text = label.attributedText {
            let title = NSString(string: text.string)
            
            let tapRange = title.range(of: Localizables.shared.strings.terms_of_use)
            
            if tapRange.location != NSNotFound {
                let tapLocation = sender.location(in: label)
                let tapIndex = label.indexOfAttributedTextCharacterAtPoint(point: tapLocation)
                
                if let ranges = label.attributedText?.rangesOf(subString: Localizables.shared.strings.terms_of_use) {
                    for range in ranges {
                        if tapIndex > range.location && tapIndex < range.location + range.length {
                            self.openUrl(url: CryptoWolfManager.sharedManager.termsUrl)
                            return
                        }
                    }
                }
            }
        }
    }
}

extension BuyBeamViewController : UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        let view = UIView()
        view.backgroundColor = UIColor.clear
        return view
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let view = UIView()
        view.backgroundColor = (section <= 1) ? UIColor.clear : UIColor.main.marineTwo.withAlphaComponent(0.35)

        return view
    }
    
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return (section == 1) ? 30 : 0
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        switch section {
        case 4:
            return 10
        default:
            return (section == 2) ? 10 : 30
        }
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        switch indexPath.section {
        case 4:
            if indexPath.row == 2 || indexPath.row == 3 {
                return 60
            }
        case 0:
            if indexPath.row == 1 {
                return 17
            }
        default:
            return UITableView.automaticDimension
        }
        
        return UITableView.automaticDimension
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        if indexPath.section == 4 {
            switch indexPath.row {
            case 2:
                viewModel.onExpire()
            case 3:
                viewModel.onCategory()
            default:
                return
            }
        }
    }
}


extension BuyBeamViewController : UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 5
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            return 2
        }
        else if section == 4 {
            return (showEdit ? 4 : 1)
        }
        return 1
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        switch indexPath.section {
        case 0:
            if indexPath.row == 0 {
                let cell = tableView
                    .dequeueReusableCell(withType: BMAmountCell.self, for: indexPath).configured(with: (name: Localizables.shared.strings.you_send.uppercased(), value: viewModel.amount))
                cell.delegate = self
                cell.error = viewModel.amountError
                cell.currency = viewModel.currency
                return cell
            }
            else{
                let cell = UITableViewCell(style: .default, reuseIdentifier: Localizables.shared.strings.beam)
                cell.textLabel?.textColor = UIColor.main.blueyGrey
                cell.textLabel?.font = RegularFont(size: 14)
                if viewModel.loading {
                    cell.textLabel?.text = Localizables.shared.strings.min_amount_loading
                }
                else{
                    cell.textLabel?.text = viewModel.minimumAmount
                }
                cell.backgroundColor = UIColor.clear
                cell.selectionStyle = .none
                cell.separatorInset = UIEdgeInsets.zero
                cell.indentationLevel = 0
                return cell
            }
        case 1:
            let cell = tableView
                .dequeueReusableCell(withType: BuyGetCell.self, for: indexPath)
            cell.configure(with: viewModel.receiveAmount)
            cell.isLoading = viewModel.loading
            return cell
        case 2:
            let fullname = CryptoWolfManager.sharedManager.fullName(coin: viewModel.currency)

            let name = fullname + " " + Localizables.shared.strings.refund_address
            
            let cell = tableView
                .dequeueReusableCell(withType: BMFieldCell.self, for: indexPath)
                .configured(with: (name: name.uppercased() , value: viewModel.fromAddress, rightIcon:IconScanQr()))
            cell.delegate = self
            cell.error = viewModel.fromAddressError
            cell.contentView.backgroundColor = UIColor.main.marineTwo.withAlphaComponent(0.35)
            return cell
        case 3:
            var title = viewModel.pickedAddress == nil ? Localizables.shared.strings.beam_recepient_auto : Localizables.shared.strings.beam_recepient.uppercased()
            if viewModel.pickedAddress != nil {
                if viewModel.pickedAddress?.walletId == viewModel.startedAddress?.walletId {
                    title = Localizables.shared.strings.beam_recepient_auto.uppercased()
                }
            }
            let cell = tableView
                .dequeueReusableCell(withType: BMPickedAddressCell.self, for: indexPath)
                .configured(with: (hideLine: true, address: viewModel.address, title: title))
            cell.delegate = self
            cell.contentView.backgroundColor = UIColor.main.marineTwo.withAlphaComponent(0.35)
            return cell
        case 4:
            if indexPath.row == 0 {
                let cell = tableView
                    .dequeueReusableCell(withType: BMExpandCell.self, for: indexPath)
                    .configured(with: (expand: showEdit, title: Localizables.shared.strings.edit_address.uppercased()))
                cell.delegate = self
                return cell
            }
            else if indexPath.row == 1 {
                let cell = tableView
                    .dequeueReusableCell(withType: BMFieldCell.self, for: indexPath)
                    .configured(with: (name: Localizables.shared.strings.name.uppercased(), value: viewModel.address!.label, rightIcon:nil))
                cell.delegate = self
                cell.contentView.backgroundColor = UIColor.main.marineTwo.withAlphaComponent(0.35)
                cell.topOffset?.constant = 20
                return cell
            }
            else if indexPath.row == 2 {
                let cell = tableView
                    .dequeueReusableCell(withType: BMDetailCell.self, for: indexPath)
                    .configured(with: (title: Localizables.shared.strings.expires.uppercased(), value: (viewModel.address!.duration > 0 ? Localizables.shared.strings.hours_24 : Localizables.shared.strings.never), valueColor: UIColor.white))
                return cell
            }
            else if indexPath.row == 3 {
                var name = Localizables.shared.strings.none
                var color = UIColor.main.steelGrey
                
                if let category = AppModel.sharedManager().findCategory(byId: viewModel.address!.category) {
                    name = category.name
                    color = UIColor.init(hexString: category.color)
                }
                
                let cell = tableView
                    .dequeueReusableCell(withType: BMDetailCell.self, for: indexPath)
                    .configured(with: (title: Localizables.shared.strings.category.uppercased(), value: name, valueColor: color))
                return cell
            }
            else{
                return BaseCell()
            }
        default:
            return BaseCell()
        }
    }
}

extension BuyBeamViewController : BMCellProtocol {
    
    func textValueDidReturn(_ sender: UITableViewCell) {
        if let path = tableView.indexPath(for: sender)  {
            if path.section == 4 {
                AppModel.sharedManager().setWalletComment(viewModel.address!.label, toAddress: viewModel.address!.walletId)
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
                viewModel.amount = text
                viewModel.amountError = nil
                tableView.reloadRows(at: [IndexPath(row: 0, section: 1)], with: .none)
            }
            else if path.section == 2 {
                viewModel.fromAddress = text
            }
            else if path.section == 4 {
                viewModel.address.label = text
            }
        }
        
        UIView.performWithoutAnimation {
            tableView.beginUpdates()
            tableView.endUpdates()
        }
    }
    
    func onRightButton(_ sender: UITableViewCell) {
        if let path = tableView.indexPath(for: sender)  {
            if path.section == 0 {
                viewModel.onChangeCurrency()
            }
            else if path.section == 2{
                viewModel.onScanQRCode()
            }
            else if path.section == 3 {
                viewModel.onChangeAddress()
            }
        }
    }
    
    func onExpandCell(_ sender: UITableViewCell) {
        if let path = tableView.indexPath(for: sender)
        {
            if path.section == 4 {
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
}

