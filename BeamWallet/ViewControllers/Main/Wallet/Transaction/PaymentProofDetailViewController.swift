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

class PaymentProofDetailViewController: BaseViewController {

    private var transaction: BMTransaction?
    private var paymentProof: BMPaymentProof?

    private var details = [[TransactionViewController.TransactionGeneralInfo]]()

    @IBOutlet private weak var tableView: UITableView!
    @IBOutlet private var headerView: UIView!
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
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = paymentProof == nil ? "Payment proof verification" : "Payment proof"
        
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
            
            SVProgressHUD.showSuccess(withStatus: "copied to clipboard")
            SVProgressHUD.dismiss(withDelay: 1.5)
        }
    }
    
    @IBAction func onCopyCode(sender :UIButton) {
        if let code = paymentProof?.code {
            UIPasteboard.general.string = code
            
            SVProgressHUD.showSuccess(withStatus: "copied to clipboard")
            SVProgressHUD.dismiss(withDelay: 1.5)
        }
    }
    
    private func fillTransactionInfo() {
        details.removeAll()

        if let paymentProof = self.paymentProof, let transaction = self.transaction {
            
            var section_1 = [TransactionViewController.TransactionGeneralInfo]()
            section_1.append(TransactionViewController.TransactionGeneralInfo(text: "Code:", detail: paymentProof.code, failed: false, canCopy:true, color: UIColor.white))
            
            var section_2 = [TransactionViewController.TransactionGeneralInfo]()
            section_2.append(TransactionViewController.TransactionGeneralInfo(text: "Sender:", detail: transaction.senderAddress, failed: false, canCopy:true, color: UIColor.white))
            section_2.append(TransactionViewController.TransactionGeneralInfo(text: "Receiver:", detail: transaction.receiverAddress, failed: false, canCopy:true, color: UIColor.white))
            section_2.append(TransactionViewController.TransactionGeneralInfo(text: "Amount:", detail: String.currency(value: transaction.realAmount) + " BEAM", failed: false, canCopy:true, color: UIColor.white))
            section_2.append(TransactionViewController.TransactionGeneralInfo(text: "Kernel ID:", detail: transaction.kernelId, failed: false, canCopy:true, color: UIColor.white))
            
            details.append(section_1)
            details.append(section_2)
            
            tableView.tableFooterView = footerView
        }
        else if let transaction = self.transaction {
            var section_2 = [TransactionViewController.TransactionGeneralInfo]()
            section_2.append(TransactionViewController.TransactionGeneralInfo(text: "Sender:", detail: transaction.senderAddress, failed: false, canCopy:true, color: UIColor.white))
            section_2.append(TransactionViewController.TransactionGeneralInfo(text: "Receiver:", detail: transaction.receiverAddress, failed: false, canCopy:true, color: UIColor.white))
            section_2.append(TransactionViewController.TransactionGeneralInfo(text: "Amount:", detail: String.currency(value: transaction.realAmount) + " BEAM", failed: false, canCopy:true, color: UIColor.white))
            section_2.append(TransactionViewController.TransactionGeneralInfo(text: "Kernel ID:", detail: transaction.kernelId, failed: false, canCopy:true, color: UIColor.white))
            
            details.append(section_2)
            
            buttonCode.isHidden = true
            
            buttonDetails.backgroundColor = UIColor.main.brightTeal
            buttonDetails.tintColor = UIColor.main.marine
            buttonDetails.setTitleColor(UIColor.main.marine, for: .normal)
            buttonDetails.setImage(UIImage(named: "iconCopyBlue"), for: .normal)
            buttonDetails.awakeFromNib()
            
            let w: CGFloat = (UIScreen.main.bounds.size.width - 180)/2
            footerRightOffset.constant = w
            footerLeftOffset.constant = w
            
            tableView.tableFooterView = footerView
        }
        else{
            tableView.tableFooterView = nil
        }
    }
}

extension PaymentProofDetailViewController : UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        if section == 1 {
            return 60
        }
        return 0
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
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        if section == 0 {
            return nil
        }
        else if section == 1 {
            return headerView
        }
        return nil
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
        if text == "\n" {
            textView.resignFirstResponder()
            return false
        }
        return true
    }
}
