//
// PaymentProofDetailViewController.swift
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

class PaymentProofDetailViewController: BaseTableViewController {
    private var transaction: BMTransaction?
    private var paymentProof: BMPaymentProof?
    private var paymentInfo: BMPaymentInfo?

    private var details = [[BMMultiLineItem]]()
    
    private var detailsExpand = true
    
    @IBOutlet private weak var footerView: UIView!
    @IBOutlet private weak var codeInputView: UIView!
    @IBOutlet private weak var codeInputField: BMTextView!
    @IBOutlet private weak var codeInputLabel: UILabel!
    @IBOutlet private weak var inputFieldHeight: NSLayoutConstraint!
    @IBOutlet private weak var headerdHeight: NSLayoutConstraint!
    @IBOutlet private weak var keyKodeTitle: UILabel!
    
    
    override var tableStyle: UITableView.Style {
        get {
            return .grouped
        }
        set {
            super.tableStyle = newValue
        }
    }
    
    init(transaction: BMTransaction?, paymentProof: BMPaymentProof?) {
        super.init(nibName: nil, bundle: nil)
        
        self.transaction = transaction
        self.paymentProof = paymentProof
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError(Localizable.shared.strings.fatalInitCoderError)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setGradientTopBar(mainColor: UIColor.main.peacockBlue, addedStatusView: true)
        
        title = Localizable.shared.strings.payment_proof
        
        keyKodeTitle.text = Localizable.shared.strings.key_code.uppercased()
        keyKodeTitle.letterSpacing = 1.5
        
        codeInputField.placholderFont = ItalicFont(size: 16)
        codeInputField.placeholder = Localizable.shared.strings.paste_payment_proof
        
        tableView.register(BMMultiLinesCell.self)
        tableView.tableHeaderView = paymentProof == nil ? codeInputView : UIView(frame: CGRect(x: 0.0, y: 0.0, width: 0.0, height: 1))
         tableView.keyboardDismissMode = .interactive
        tableView.delegate = self
        tableView.dataSource = self
        
        fillTransactionInfo()
         
        hideKeyboardWhenTappedAround()
        
        if paymentProof == nil {
            _ = codeInputField.becomeFirstResponder()
        }
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
    }
    
    @IBAction func onCopyCodeDetails(sender: UIButton) {
        if let transactionDetail = transaction?.details() {
            UIPasteboard.general.string = transactionDetail
            
            ShowCopied()
        }
    }
    
    @IBAction func onCopyCode(sender: UIButton) {
        if let code = paymentProof?.code {
            UIPasteboard.general.string = code
            
            ShowCopied()
        }
    }
    
    @objc private func onMoreDetails() {
        detailsExpand = !detailsExpand
        tableView.reloadSections(IndexSet(arrayLiteral: tableView.tableHeaderView == codeInputView ? 0 : 1), with: .fade)
    }
    
    private func fillTransactionInfo() {
        details.removeAll()
        
        if let paymentProof = self.paymentProof {
            var section_1 = [BMMultiLineItem]()
            section_1.append(BMMultiLineItem(title: Localizable.shared.strings.key_code.uppercased(), detail: paymentProof.code, detailFont: RegularFont(size: 16), detailColor: UIColor.white, copy: true))
            
            details.append(section_1)
            
            tableView.tableFooterView = footerView
        }
        
        if let info = AppModel.sharedManager().getPaymentProofInfo(self.paymentProof?.code ?? String.empty()){
            self.fillInfoFromPaymentInfo(info: info)
        }
        else {
            self.paymentInfo = nil
        }
        
        if transaction == nil, paymentProof == nil {
            tableView.tableFooterView = nil
        }
    }
    
    private func fillInfoFromPaymentInfo(info: BMPaymentInfo?) {
        if let info = info {
            self.paymentInfo = info
            
            var section_2 = [BMMultiLineItem]()
            section_2.append(BMMultiLineItem(title: Localizable.shared.strings.sender.uppercased(), detail: info.sender, detailFont: RegularFont(size: 16), detailColor: UIColor.white, copy: true))
            section_2.append(BMMultiLineItem(title: Localizable.shared.strings.receiver.uppercased(), detail: info.receiver, detailFont: RegularFont(size: 16), detailColor: UIColor.white, copy: true))
            section_2.append(BMMultiLineItem(title: Localizable.shared.strings.amount.uppercased(), detail: String.currency(value: info.realAmount) , detailFont: RegularFont(size: 16), detailColor: UIColor.main.heliotrope))
            section_2.append(BMMultiLineItem(title: Localizable.shared.strings.kernel_id.uppercased(), detail: info.kernelId, detailFont: RegularFont(size: 16), detailColor: UIColor.white, copy: true))
            
            details.append(section_2)
            
            tableView.tableFooterView = footerView
        }
    }
    
    private func resize() {
        var size = codeInputField.sizeThatFits(CGSize(width: codeInputField.width, height: 9999))
        if size.height < 40 {
            size.height = 40
        }
        inputFieldHeight.constant = size.height
        headerdHeight.constant = inputFieldHeight.constant + (codeInputLabel.alpha == 0 ? 65 : 90)
        
        codeInputView.frame = CGRect(x: 0, y: 0, width: UIScreen.main.bounds.size.width, height: headerdHeight.constant)
        
        tableView.beginUpdates()
        tableView.tableHeaderView = codeInputView
        tableView.tableHeaderView?.layoutIfNeeded()
        tableView.tableHeaderView?.layoutSubviews()
        tableView.endUpdates()
    }
}

extension PaymentProofDetailViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        
        if section == 0 && tableView.tableHeaderView == codeInputView  {
            return BMTableHeaderTitleView.height
        }
        
        return section == 1 ? BMTableHeaderTitleView.height : 1
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
}

extension PaymentProofDetailViewController: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return details.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 1, !detailsExpand {
            return 0
        }
        else if section == 0, !detailsExpand, tableView.tableHeaderView == codeInputView {
            return 0
        }
        return details[section].count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView
            .dequeueReusableCell(withType: BMMultiLinesCell.self, for: indexPath)
            .configured(with: details[indexPath.section][indexPath.row])
        cell.delegate = self
        
        if tableView.tableHeaderView == codeInputView {
            cell.contentView.backgroundColor = UIColor.white.withAlphaComponent(0.05)
        }
        else{
            if indexPath.section == 1 {
                cell.contentView.backgroundColor = UIColor.white.withAlphaComponent(0.05)
            }
            else {
                cell.contentView.backgroundColor = UIColor.clear
            }
        }
                
        return cell
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        switch section {
        case 0:
            if tableView.tableHeaderView == codeInputView {
                return BMTableHeaderTitleView(title: Localizable.shared.strings.details.uppercased(), handler: #selector(onMoreDetails), target: self, expand: detailsExpand)
            }
            else{
                let view = UIView()
                view.backgroundColor = UIColor.clear
                return view
            }
        case 1:
            return BMTableHeaderTitleView(title: Localizable.shared.strings.details.uppercased(), handler: #selector(onMoreDetails), target: self, expand: detailsExpand)
        default:
            return nil
        }
    }
}

extension PaymentProofDetailViewController: UITextViewDelegate {
    func textViewDidBeginEditing(_ textView: UITextView) {
        resize()
    }
    
    func textViewShouldBeginEditing(_ textView: UITextView) -> Bool {
        textView.inputAccessoryView = nil
        
        if let text = UIPasteboard.general.string {
            if text.lengthOfBytes(using: .utf8) >= 330 {
                let inputBar = BMInputCopyBar(frame: CGRect(x: 0, y: 0, width: view.frame.size.width, height: 44), copy: text)
                inputBar.completion = {
                    (obj: String?) -> Void in
                    if let text = obj {
                        self.codeInputField.text = text
                        self.textViewDidChange(self.codeInputField)
                    }
                }
                textView.inputAccessoryView = inputBar
                textView.layoutIfNeeded()
                textView.layoutSubviews()
            }
        }
        
        return true
    }
    
    func textViewDidEndEditing(_ textView: UITextView) {
        let paymentInfo = AppModel.sharedManager().validatePaymentProof(textView.text)
        
        if paymentInfo == nil {
            transaction = nil
            
            codeInputLabel.alpha = 1
            codeInputLabel.textColor = UIColor.main.red
            codeInputField.textColor = UIColor.main.red
            codeInputField.lineColor = UIColor.main.red
        }
        else {
            codeInputLabel.alpha = 0
            codeInputField.lineColor = UIColor.white.withAlphaComponent(0.1)
            codeInputField.textColor = UIColor.white
        }
        
        resize()
        
        fillTransactionInfo()
        fillInfoFromPaymentInfo(info: paymentInfo)
        tableView.reloadData()
    }
    
    func textViewDidChange(_ textView: UITextView) {
        let text = textView.text
        
        let tr = AppModel.sharedManager().validatePaymentProof(text)
        
        if tr != nil {
            textView.resignFirstResponder()
        }
        else if paymentInfo != nil, tr == nil {
            paymentInfo = nil
            
            if textView.text.isEmpty {
                codeInputLabel.alpha = 0
                codeInputField.lineColor = UIColor.white.withAlphaComponent(0.1)
                codeInputField.textColor = UIColor.white
            }
            else {
                codeInputLabel.alpha = 1
                codeInputLabel.textColor = UIColor.main.red
                codeInputField.textColor = UIColor.main.red
                codeInputField.lineColor = UIColor.main.red
            }
            
            fillTransactionInfo()
            
            tableView.reloadData()
        }
        else if tr == nil {
            if textView.text.isEmpty {
                codeInputLabel.alpha = 0
                codeInputField.lineColor = UIColor.white.withAlphaComponent(0.1)
                codeInputField.textColor = UIColor.white
            }
            else {
                codeInputLabel.alpha = 1
                codeInputLabel.textColor = UIColor.main.red
                codeInputField.textColor = UIColor.main.red
                codeInputField.lineColor = UIColor.main.red
            }
        }
        
        resize()
    }
    
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        if text == Localizable.shared.strings.new_line {
            textView.resignFirstResponder()
            return false
        }
        return true
    }
}

extension PaymentProofDetailViewController: GeneralInfoCellDelegate {
    func onClickToCell(cell: UITableViewCell) {
        if let path = tableView.indexPath(for: cell) {
            if details[path.section][path.row].title == Localizable.shared.strings.kernel_id.uppercased(),
                let transaction = self.transaction {
                let kernelId = transaction.kernelId!
                let link = Settings.sharedManager().explorerAddress + kernelId
                if let url = URL(string: link) {
                    openUrl(url: url)
                }
            }
        }
    }
}
