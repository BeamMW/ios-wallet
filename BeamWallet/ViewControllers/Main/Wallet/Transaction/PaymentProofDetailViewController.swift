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

    private var details = [[GeneralInfo]]()

    @IBOutlet private var footerView: UIView!
    @IBOutlet private weak var buttonDetails: UIButton!
    @IBOutlet private weak var buttonCode: UIButton!
    @IBOutlet private weak var codeInputView: UIView!
    @IBOutlet private weak var codeInputField: BMTextView!
    @IBOutlet private weak var codeInputLabel: UILabel!
    @IBOutlet private weak var footerRightOffset: NSLayoutConstraint!
    @IBOutlet private weak var footerLeftOffset: NSLayoutConstraint!

    init(transaction:BMTransaction?, paymentProof:BMPaymentProof?) {
        super.init(nibName: nil, bundle: nil)
        
        self.transaction = transaction
        self.paymentProof = paymentProof
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError(LocalizableStrings.fatalInitCoderError)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = paymentProof == nil ? LocalizableStrings.payment_proof_verefication : LocalizableStrings.payment_proof
        
        tableView.delegate = self
        tableView.dataSource = self
        
        tableView.register(GeneralInfoCell.self)
        
        fillTransactionInfo()
        
        buttonDetails.backgroundColor = UIColor.main.marineTwo;
        buttonDetails.awakeFromNib()
        
        tableView.tableHeaderView = paymentProof == nil ? codeInputView : nil
        tableView.keyboardDismissMode = .interactive
        
        hideKeyboardWhenTappedAround()
        
        if paymentProof == nil {
            codeInputField.becomeFirstResponder()
        }
    }

    
    @IBAction func onCopyCodeDetails(sender :UIButton) {
        if let transactionDetail = transaction?.details() {
            UIPasteboard.general.string = transactionDetail
            
            ShowCopiedProgressHUD()
        }
    }
    
    @IBAction func onCopyCode(sender :UIButton) {
        if let code = paymentProof?.code {
            UIPasteboard.general.string = code
            
            ShowCopiedProgressHUD()
        }
    }
    
    private func fillTransactionInfo() {
        details.removeAll()

        if let paymentProof = self.paymentProof {
            
            var section_1 = [GeneralInfo]()
            section_1.append(GeneralInfo(text: LocalizableStrings.code, detail: paymentProof.code, failed: false, canCopy:true, color: UIColor.white))

            details.append(section_1)
            
            tableView.tableFooterView = footerView
        }
        
        if let transaction = self.transaction {
            
            var section_2 = [GeneralInfo]()
            section_2.append(GeneralInfo(text: LocalizableStrings.sender, detail: transaction.senderAddress, failed: false, canCopy:true, color: UIColor.white))
            section_2.append(GeneralInfo(text: LocalizableStrings.receiver, detail: transaction.receiverAddress, failed: false, canCopy:true, color: UIColor.white))
            section_2.append(GeneralInfo(text: LocalizableStrings.amount, detail: String.currency(value: transaction.realAmount) + LocalizableStrings.beam, failed: false, canCopy:true, color: UIColor.white))
            section_2.append(GeneralInfo(text: LocalizableStrings.kernel_id, detail: transaction.kernelId, failed: false, canCopy:true, color: UIColor.white))
            
            details.append(section_2)
            
            if self.paymentProof == nil {
                buttonCode.isHidden = true
                
                buttonDetails.backgroundColor = UIColor.main.brightTeal
                buttonDetails.tintColor = UIColor.main.marine
                buttonDetails.setTitleColor(UIColor.main.marine, for: .normal)
                buttonDetails.setImage(IconCopyBlue(), for: .normal)
                buttonDetails.awakeFromNib()
                
                let w: CGFloat = (UIScreen.main.bounds.size.width - 180)/2
                footerRightOffset.constant = w
                footerLeftOffset.constant = w
                
                tableView.tableFooterView = footerView
            }
        }
       
        if self.transaction == nil && self.paymentProof == nil {
            
            tableView.tableFooterView = nil
        }
    }
}

extension PaymentProofDetailViewController : UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return section == 1 ? BMTableHeaderTitleView.boldHeight : 0
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }
    
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
}

extension PaymentProofDetailViewController : UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return details.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return details[section].count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView
            .dequeueReusableCell(withType: GeneralInfoCell.self, for: indexPath)
            .configured(with: details[indexPath.section][indexPath.row])
        cell.delegate = self
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        switch section {
        case 0:
            return nil
        case 1:
            return BMTableHeaderTitleView(title: LocalizableStrings.details, bold: true)
        default:
            return nil
        }
    }
}


extension PaymentProofDetailViewController : UITextViewDelegate {
   
    func textViewShouldBeginEditing(_ textView: UITextView) -> Bool {
        textView.inputAccessoryView = nil
        
        if let text = UIPasteboard.general.string {
            if text.lengthOfBytes(using: .utf8) >= 330
            {
                let inputBar = BMInputCopyBar(frame: CGRect(x: 0, y: 0, width: view.frame.size.width, height: 44), copy:text)
                inputBar.completion = {
                    (obj : String?) -> Void in
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
        let tr = AppModel.sharedManager().validatePaymentProof(textView.text)

        if tr == nil {
            transaction = nil
            
            codeInputLabel.alpha = 1
            codeInputLabel.textColor = UIColor.main.red
            codeInputField.textColor = UIColor.main.red
            codeInputField.lineColor = UIColor.main.red
        }
        else{
            transaction = tr
            
            codeInputLabel.alpha = 0
            codeInputField.lineColor = UIColor.main.marineTwo
            codeInputField.textColor = UIColor.white
        }
        
        fillTransactionInfo()
        tableView.reloadData()
    }
    
    func textViewDidChange(_ textView: UITextView) {
        let text = textView.text
        
        let tr = AppModel.sharedManager().validatePaymentProof(text)
        
        if tr != nil {
            textView.resignFirstResponder()
        }
        else if transaction != nil && tr == nil {
            transaction = nil
            
            if textView.text.isEmpty {
                codeInputLabel.alpha = 0
                codeInputField.lineColor = UIColor.main.marineTwo
                codeInputField.textColor = UIColor.white
            }
            else{
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
                codeInputField.lineColor = UIColor.main.marineTwo
                codeInputField.textColor = UIColor.white
            }
            else{
                codeInputLabel.alpha = 1
                codeInputLabel.textColor = UIColor.main.red
                codeInputField.textColor = UIColor.main.red
                codeInputField.lineColor = UIColor.main.red
            }
        }
    }
    
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        if text == LocalizableStrings.new_line {
            textView.resignFirstResponder()
            return false
        }
        return true
    }
}

extension PaymentProofDetailViewController : GeneralInfoCellDelegate {
    func onClickToCell(cell: UITableViewCell) {
        if let path = tableView.indexPath(for: cell)
        {
            if details[path.section][path.row].text == LocalizableStrings.kernel_id, let transaction = self.transaction {
                let kernelId = transaction.kernelId!
                let link = Settings.sharedManager().explorerAddress + "block?kernel_id=" + kernelId
                if let url = URL(string: link) {
                    openUrl(url: url)
                }
            }
        }
    }
}
