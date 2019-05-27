//
// WalletConfirmSendViewController.swift
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

protocol WalletConfirmSendViewControllerDelegate: AnyObject {
    func onConfirmSend(amount:Double, fee:Double, toAddress:String)
}

class WalletConfirmSendViewController: BaseViewController {

    weak var delegate: WalletConfirmSendViewControllerDelegate?

    @IBOutlet weak private var scrollView: UIScrollView!
    @IBOutlet weak private var toAddressLabel: UILabel!
    @IBOutlet weak private var amountLabel: UILabel!
    @IBOutlet weak private var feeLabel: UILabel!
    @IBOutlet weak private var passwordField: BMField!
    @IBOutlet weak private var passwordErrorLabel: UILabel!
    @IBOutlet private weak var touchIdButton: UIButton!
    @IBOutlet private weak var mainHeight: NSLayoutConstraint!

    private var amount:Double!
    private var fee:Double!
    private var toAddress:String!

    
    init(amount:Double, fee:Double, toAddress:String) {
        super.init(nibName: nil, bundle: nil)

        self.amount = amount
        self.fee = fee
        self.toAddress = toAddress
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = UIColor.clear
        view.isOpaque = false
        
        toAddressLabel.text = toAddress
        amountLabel.text = String.currency(value: amount) + " BEAM"
        feeLabel.text = String.currency(value: fee) + " GROTH"

        addSwipeToDismiss()
        
        if Device.isZoomed || Device.screenType == .iPhones_5 {
            scrollView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 60, right: 0)
        }
        else{
            if BiometricAuthorization.shared.canAuthenticate() || Settings.sharedManager().isEnableBiometric {
                mainHeight.constant = 550
            }
        }
        
        if !BiometricAuthorization.shared.canAuthenticate() || !Settings.sharedManager().isEnableBiometric {
            touchIdButton.isHidden = true
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: UIResponder.keyboardWillHideNotification, object: nil)
        
        if Device.isZoomed || Device.screenType == .iPhones_5 {
            scrollView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 60, right: 0)
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillShowNotification , object: nil)
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillHideNotification , object: nil)
    }
    
    private func biometricAuthorization() {
        if BiometricAuthorization.shared.canAuthenticate() && Settings.sharedManager().isEnableBiometric {
            
            BiometricAuthorization.shared.authenticateWithBioMetrics(success: {
                if let password = KeychainManager.getPassword() {
                    if AppModel.sharedManager().isValidPassword(password) {
                        self.dismiss(animated: true) {
                            self.delegate?.onConfirmSend(amount: self.amount, fee: self.fee, toAddress: self.toAddress)
                        }
                    }
                    else{
                        self.touchIdButton.tintColor = UIColor.main.red
                        
                        self.passwordErrorLabel.isHidden = false
                        self.passwordErrorLabel.text = "Incorrect password"
                        self.passwordErrorLabel.textColor = UIColor.main.red
                        self.passwordField.status = BMField.Status.error
                    }
                }
                else{
                    self.touchIdButton.tintColor = UIColor.main.red

                    self.passwordErrorLabel.isHidden = false
                    self.passwordErrorLabel.text = "Incorrect password"
                    self.passwordErrorLabel.textColor = UIColor.main.red
                    self.passwordField.status = BMField.Status.error
                }
                
            }, failure: {
                self.touchIdButton.tintColor = UIColor.main.red
            }, retry: {
                self.touchIdButton.tintColor = UIColor.white
            })
        }
    }
    
    @IBAction func onClose(sender :UIButton) {
        dismiss(animated: true, completion:nil)
    }
    
    @IBAction func onTouchId(sender :UIButton) {
        touchIdButton.tintColor = UIColor.white
        
        passwordErrorLabel.isHidden = true
        passwordField.status = BMField.Status.normal

        biometricAuthorization()
    }
    
    @IBAction func onSend(sender :UIButton) {
        self.view.endEditing(true)
        
        if passwordField.text?.isEmpty ?? true {
            passwordErrorLabel.isHidden = false
            passwordErrorLabel.text = "Password can not be empty"
            passwordErrorLabel.textColor = UIColor.main.red
            passwordField.status = BMField.Status.error
        }
        else if let pass = passwordField.text {
            if AppModel.sharedManager().isValidPassword(pass) {
                self.dismiss(animated: true) {
                    self.delegate?.onConfirmSend(amount: self.amount, fee: self.fee, toAddress: self.toAddress)
                }
            }
            else{
                passwordErrorLabel.isHidden = false
                passwordErrorLabel.text = "Incorrect password"
                passwordErrorLabel.textColor = UIColor.main.red
                passwordField.status = BMField.Status.error
            }
        }
    }
}

extension WalletConfirmSendViewController : UITextFieldDelegate {
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        
        passwordErrorLabel.isHidden = true
        
        return true
    }
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        let fieldPosition = textField.superview?.frame
        if let position = fieldPosition {
            scrollView.scrollRectToVisible(position, animated: true)
        }
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        scrollView.scrollRectToVisible(CGRect.zero, animated: true)
    }
}

extension WalletConfirmSendViewController {
    @objc func keyboardWillShow(_ notification: Notification) {
        if let keyboardFrame: NSValue = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue {
            let keyboardRectangle = keyboardFrame.cgRectValue
            let keyboardHeight = keyboardRectangle.height
            
            scrollView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: keyboardHeight, right: 0)
        }
    }
    
    @objc func keyboardWillHide(notification: NSNotification) {
        if Device.isZoomed || Device.screenType == .iPhones_5 {
            scrollView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 60, right: 0)
        }
        else {
            scrollView.contentInset = UIEdgeInsets.zero
        }
    }
}
