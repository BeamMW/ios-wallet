//
//  WalletSendViewController.swift
//  BeamWallet
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
import AVFoundation

class WalletSendViewController: BaseViewController {

    @IBOutlet weak private var mainViewHeight: NSLayoutConstraint!
    @IBOutlet weak private var mainViewWidth: NSLayoutConstraint!

    @IBOutlet weak private var mainStack: UIStackView!
    @IBOutlet weak private var scrollView: UIScrollView!
    
    @IBOutlet weak private var toAddressField: BMField!
    @IBOutlet weak private var toAddressErrorLabel: UILabel!
    
    @IBOutlet weak private var amountField: BMField!
    @IBOutlet weak private var amountErrorLabel: UILabel!
    
    @IBOutlet weak private var feeField: BMField!

    @IBOutlet weak private var commentField: BMField!

    @IBOutlet weak private var amountStack: UIStackView!
    @IBOutlet weak private var feeStack: UIStackView!

    private var focused = false
    
    public var transaction: BMTransaction?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        title = "Send"
        
        hideKeyboardWhenTappedAround()
                        
        if (Device.screenType == .iPhone_XR || Device.screenType == .iPhones_X_XS)
        {
            mainStack.spacing = 45;
        }
        else if (Device.screenType == .iPhones_Plus || Device.screenType == .iPhone_XSMax)
        {
            mainStack.spacing = 55;
        }
        
        mainViewWidth.constant = UIScreen.main.bounds.width
        
        if let repeatTransaction = transaction {
            toAddressField.text = repeatTransaction.receiverAddress
            amountField.text = String.currency(value: repeatTransaction.realAmount)
            feeField.text = String(repeatTransaction.realFee)
            commentField.text = repeatTransaction.comment
        }
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        updateLayout()
    }
    
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: UIResponder.keyboardWillHideNotification, object: nil)
        
        if !focused && transaction == nil {
            focused = true
            
            if let text = UIPasteboard.general.string {
                if AppModel.sharedManager().isValidAddress(text)
                {
                    toAddressField.becomeFirstResponder()
                }
            }
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillShowNotification , object: nil)
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillHideNotification , object: nil)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }
    
    private func updateLayout() {
        mainViewHeight.constant = mainStack.frame.height + mainStack.frame.origin.y + 20
    }
    
//MARK: - IBAction
    
    @IBAction func onSend(sender :UIButton) {
        self.view.endEditing(true)
        
        let amount = Double(amountField.text?.replacingOccurrences(of: ",", with: ".") ?? "0")
        let fee = Double(feeField.text?.replacingOccurrences(of: ",", with: ".") ?? "0")
        
        let valid = AppModel.sharedManager().isValidAddress(toAddressField.text)
        let expired = AppModel.sharedManager().isExpiredAddress(toAddressField.text)

        if !valid {
            toAddressErrorLabel.text = "Incorrect address"
            toAddressErrorLabel.textColor = UIColor.main.red
            toAddressField.status = BMField.Status.error
        }
        else if expired {
            toAddressErrorLabel.text = "Can't send to the expired address"
            toAddressErrorLabel.textColor = UIColor.main.red
            toAddressField.status = BMField.Status.error
        }
        else if let canSend = AppModel.sharedManager().canSend(amount ?? 0, fee: fee ?? 0, to: toAddressField.text) {
            
            amountErrorLabel.isHidden = false
            amountErrorLabel.textColor = UIColor.main.red
            
            if amountField.text?.isEmpty ?? true {
                amountErrorLabel.text = "Amount field can't be empty"
            }
            else{
                amountErrorLabel.text = canSend
            }
        }
        else if let toAddress = toAddressField.text {
            if Settings.sharedManager().isNeedaskPasswordForSend {
                let modalViewController = WalletConfirmSendViewController(amount: amount ?? 0, fee: fee ?? 0, toAddress: toAddress)
                modalViewController.delegate = self
                modalViewController.modalPresentationStyle = .overFullScreen
                modalViewController.modalTransitionStyle = .crossDissolve
                present(modalViewController, animated: true, completion: nil)
            }
            else{
                onConfirmSend(amount: amount ?? 0, fee: fee ?? 0, toAddress: toAddress)
            }
        }
        
        updateLayout()
    }
    
    
    @IBAction func onScan(sender :UIButton) {
        let vc = WalletQRCodeScannerViewController()
        vc.delegate = self
        pushViewController(vc: vc)
    }
}


// MARK: TextField Actions

extension WalletSendViewController : UITextFieldDelegate {
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        
        if textField == toAddressField {
            toAddressErrorLabel.text = "Input or scan the recipient's address"
            toAddressErrorLabel.textColor = UIColor.main.blueyGrey
        }
        else if textField == amountField {
            amountErrorLabel.isHidden = true
            amountField.lineColor = UIColor.main.darkSlateBlue
            amountField.textColor = UIColor.main.heliotrope
        }
        
        updateLayout()

        let textFieldText: NSString = (textField.text ?? "") as NSString

        if textField == amountField || textField == feeField {
            
            let count = (textField == amountField) ? 8 : 15
            
            let txtAfterUpdate = textFieldText.replacingCharacters(in: range, with: string).replacingOccurrences(of: ",", with: ".")
            
            if Double(txtAfterUpdate) == nil && !txtAfterUpdate.isEmpty {
                return false
            }
            
            let allowedCharacters = CharacterSet(charactersIn:".0123456789")
            let characterSet = CharacterSet(charactersIn: txtAfterUpdate)
            
            if (!allowedCharacters.isSuperset(of: characterSet)) {
                return false
            }
            
            if textField == feeField && txtAfterUpdate.contains(".") {
                return false
            }
            
            if !txtAfterUpdate.isEmpty {
                let split = txtAfterUpdate.split(separator: ".")
                if split[0].lengthOfBytes(using: .utf8) > count {
                    return false
                }
                else if split.count > 1 {
                     if split[1].lengthOfBytes(using: .utf8) > count {
                        return false
                    }
                }
            }
            
            textField.text = txtAfterUpdate
            
            return false
        }
        else if textField == toAddressField {
            let txtAfterUpdate = textFieldText.replacingCharacters(in: range, with: string)

            let allowedCharacters = CharacterSet(
                charactersIn:"0123456789qwertyuiopasdfghjklzxcvbnm")
            
            let characterSet = CharacterSet(charactersIn: txtAfterUpdate)
            
            if (!allowedCharacters.isSuperset(of: characterSet)) {
                return false
            }
        }
        

        return true
    }
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        let fieldPosition = textField.superview?.frame
        if let position = fieldPosition {
            scrollView.scrollRectToVisible(position, animated: true)
        }
        
        if textField == toAddressField {
            toAddressField.inputAccessoryView = nil
            
            if let text = UIPasteboard.general.string {
                if AppModel.sharedManager().isValidAddress(text)
                {
                    let inputBar = BMInputCopyBar(frame: CGRect(x: 0, y: 0, width: view.frame.size.width, height: 44), copy:text)
                    inputBar.completion = {
                        (obj : String?) -> Void in
                        if let text = obj {
                            self.toAddressField.text = text
                            self.amountField.becomeFirstResponder()
                        }
                    }
                    toAddressField.inputAccessoryView = inputBar
                }
            }
        }
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        scrollView.scrollRectToVisible(CGRect.zero, animated: true)

        if textField == feeField || textField == amountField {
            if let text = textField.text {
                if let v = Double(text) {
                    if v == 0 {
                        textField.text = "0"
                    }
                    else if textField == feeField {
                        textField.text = String(Int(v))
                    }
                }
                else{
                    textField.text = "0"
                }
            }
        }
        else if textField == toAddressField {
            if let text = textField.text {
                if !text.isEmpty {
                    let valid = AppModel.sharedManager().isValidAddress(text)
                    
                    if (!valid)
                    {
                        toAddressErrorLabel.text = "Incorrect address"
                        toAddressErrorLabel.textColor = UIColor.main.red
                        toAddressField.status = BMField.Status.error
                    }
                }
            }
        }
    }
}

// MARK: Keyboard Handling

extension WalletSendViewController {
    @objc func keyboardWillShow(_ notification: Notification) {
        if let keyboardFrame: NSValue = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue {
            let keyboardRectangle = keyboardFrame.cgRectValue
            let keyboardHeight = keyboardRectangle.height
            
            scrollView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: keyboardHeight, right: 0)
        }
    }
    
    @objc func keyboardWillHide(notification: NSNotification) {
        scrollView.contentInset = UIEdgeInsets.zero
    }
}

//MARK: - WalletQRCodeScannerViewControllerDelegate

extension WalletSendViewController : WalletQRCodeScannerViewControllerDelegate
{
    func didScanQRCode(value: String) {        
        self.toAddressErrorLabel.text = "Input or scan the recipient's address"
        self.toAddressErrorLabel.textColor = UIColor.main.blueyGrey
        self.toAddressField.text = value
        self.amountField.becomeFirstResponder()
    }
}

extension WalletSendViewController : WalletConfirmSendViewControllerDelegate {
    func onConfirmSend(amount: Double, fee: Double, toAddress: String) {
        AppModel.sharedManager().send(amount, fee:fee, to: toAddress, comment: commentField.text ?? "")
        
        if let viewControllers = self.navigationController?.viewControllers{
            for vc in viewControllers {
                if vc is WalletViewController {
                    self.navigationController?.popToViewController(vc, animated: true)
                    return
                }
                else if vc is AddressViewController {
                    self.navigationController?.popToViewController(vc, animated: true)
                    return
                }
            }
        }
        
        self.navigationController?.popViewController(animated: true)
    }
}

