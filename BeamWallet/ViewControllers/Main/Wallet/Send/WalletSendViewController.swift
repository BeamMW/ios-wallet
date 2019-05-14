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

    @IBOutlet weak private var balanceTotalLabel: UILabel!
    @IBOutlet weak private var balanceTotalIcon: UIImageView!
    @IBOutlet weak private var balanceTotalView: UIView!

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

    @IBOutlet weak private var sendAllButton: UIButton!

    
    private var focused = false
    private var isAll = false
    
    public var transaction: BMTransaction?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        title = "Send"
        
        balanceTotalIcon.image = UIImage.init(named: "iconSymbol")?.withRenderingMode(.alwaysTemplate)
        balanceTotalIcon.tintColor = UIColor.white
        
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
        
        if let status = AppModel.sharedManager().walletStatus {
            balanceTotalLabel.text = String.currency(value: status.realAmount)
        }
        
        rightButton()
        
        balanceTotalView.isHidden = Settings.sharedManager().isHideAmounts
        
        sendAllButton.setBackgroundColor(color: UIColor.main.marineTwo, forState: .normal)
        
        if !AppDelegate.isEnableNewFeatures {
            sendAllButton.isHidden = true
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
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            if self.amountErrorLabel.isHidden == false && (Device.screenType == .iPhones_6 || Device.screenType == .iPhones_5) && Settings.sharedManager().isHideAmounts == false {
                self.mainViewHeight.constant = self.mainViewHeight.constant + 25
            }
        }
    }
    
    private func rightButton() {
        updateLayout()
        
        let icon = Settings.sharedManager().isHideAmounts ? UIImage(named: "iconShowBalance") : UIImage(named: "iconHideBalance")
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(image: icon, style: .plain, target: self, action: #selector(onHideAmounts))
    }
    
//MARK: - IBAction
    
    @objc private func onHideAmounts() {
        if !Settings.sharedManager().isHideAmounts {
            
            if Settings.sharedManager().isAskForHideAmounts {
                let alert = UIAlertController(title: "Activate security mode", message: "All the balances will be hidden until the eye icon is tapped again", preferredStyle: .alert)
                
                alert.addAction(UIAlertAction(title: "Cancel", style: .default, handler:{ (UIAlertAction)in
                }))
                
                alert.addAction(UIAlertAction(title: "Activate", style: .default, handler:{ (UIAlertAction)in
                    
                    Settings.sharedManager().isHideAmounts = !Settings.sharedManager().isHideAmounts
                    Settings.sharedManager().isAskForHideAmounts = false

                    self.balanceTotalView.isHidden = Settings.sharedManager().isHideAmounts
                    
                    self.rightButton()
                }))
                
                self.present(alert, animated: true)
            }
            else{
                Settings.sharedManager().isHideAmounts = !Settings.sharedManager().isHideAmounts
                
                self.balanceTotalView.isHidden = Settings.sharedManager().isHideAmounts
                
                self.rightButton()
            }
        }
        else{
            Settings.sharedManager().isHideAmounts = !Settings.sharedManager().isHideAmounts
            
            balanceTotalView.isHidden = Settings.sharedManager().isHideAmounts
            
            rightButton()
        }
    }
    
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
            
            amountField.status = .error
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
                
                if Settings.sharedManager().isEnableBiometric && BiometricAuthorization.shared.canAuthenticate() {
                    
                    BiometricAuthorization.shared.authenticateWithBioMetrics(success: {
                        self.onConfirmSend(amount: amount ?? 0, fee: fee ?? 0, toAddress: toAddress)
                        
                    }, failure: {
                        
                    }, retry: {
                     
                    })
                }
                else{
                    
                    let modalViewController = WalletConfirmSendViewController(amount: amount ?? 0, fee: fee ?? 0, toAddress: toAddress)
                    modalViewController.delegate = self
                    modalViewController.modalPresentationStyle = .overFullScreen
                    modalViewController.modalTransitionStyle = .crossDissolve
                    present(modalViewController, animated: true, completion: nil)
                }
            }
            else{
                
                onConfirmSend(amount: amount ?? 0, fee: fee ?? 0, toAddress: toAddress)
            }
        }
        
        updateLayout()
    }
    
    @IBAction func onSendAll(sender :UIButton) {
        isAll = true
        
        fillAllAmount()
    }
    
    @IBAction func onScan(sender :UIButton) {
        let vc = WalletQRCodeScannerViewController()
        vc.delegate = self
        pushViewController(vc: vc)
    }
    
    private func fillAllAmount() {
        let fee = Double(feeField.text?.replacingOccurrences(of: ",", with: ".") ?? "0")
        
        let all = AppModel.sharedManager().allAmount(fee ?? 0)
        
        amountField.text = all
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
        
        updateLayout()

        let textFieldText: NSString = (textField.text ?? "") as NSString

        if textField == amountField || textField == feeField {
            
            let mainCount = (textField == amountField) ? 9 : 15
            let comaCount = 8

            let txtAfterUpdate = textFieldText.replacingCharacters(in: range, with: string).replacingOccurrences(of: ",", with: ".")
            
            if Double(txtAfterUpdate) == nil && !txtAfterUpdate.isEmpty {
                return false
            }
            
            if (!txtAfterUpdate.isDecimial()) {
                return false
            }
            
            if textField == feeField && txtAfterUpdate.contains(".") {
                return false
            }
            
            if !txtAfterUpdate.isEmpty {
                let split = txtAfterUpdate.split(separator: ".")
                if split[0].lengthOfBytes(using: .utf8) > mainCount {
                    return false
                }
                else if split.count > 1 {
                     if split[1].lengthOfBytes(using: .utf8) > comaCount {
                        return false
                    }
                     else if split[1].lengthOfBytes(using: .utf8) == comaCount && textField == amountField && Double(txtAfterUpdate) == 0 {
                        return false
                    }
                }
            }
            
            amountErrorLabel.isHidden = true

            if textField == amountField {
                isAll = false
                
                let fee = Double(feeField.text?.replacingOccurrences(of: ",", with: ".") ?? "0")
                let amount = Double(txtAfterUpdate.replacingOccurrences(of: ",", with: ".") )

                if AppModel.sharedManager().canReceive(amount ?? 00, fee: fee ?? 0) != nil {
                    return false
                }
            }
            else if textField == feeField {
                
                let fee = Double(txtAfterUpdate.replacingOccurrences(of: ",", with: ".") )
                let amount = Double(amountField.text?.replacingOccurrences(of: ",", with: ".") ?? "0")

                if AppModel.sharedManager().canReceive(amount ?? 00, fee: fee ?? 0) != nil {
                    return false
                }
            }
            
            textField.text = txtAfterUpdate
            
            if textField == feeField && isAll {
                fillAllAmount()
            }

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
    func didScanQRCode(value:String, amount:String?) {        
        self.toAddressErrorLabel.text = "Input or scan the recipient's address"
        self.toAddressErrorLabel.textColor = UIColor.main.blueyGrey
        self.toAddressField.text = value
        
        if amount != nil {
            self.amountField.text = amount
        }
        else{
            self.amountField.becomeFirstResponder()
        }
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

