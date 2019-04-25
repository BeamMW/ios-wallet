//
// CreateWalletPasswordViewController.swift
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

class CreateWalletPasswordViewController: BaseWizardViewController {
    
    @IBOutlet private weak var passField: BMField!
    @IBOutlet private weak var confirmPassField: BMField!
    @IBOutlet private weak var passProgressView: BMStepView!
    @IBOutlet private weak var passConfirmLabel: UILabel!

    private var phrase:String!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if AppModel.sharedManager().isLoggedin {
            self.title = "change_password".localized
        }
        else{
            self.title = "password".localized
        }
        
        if Device.isZoomed {
            stackY?.constant = 10
            mainStack?.spacing = 30
        }
        else if Device.screenType == .iPhones_5 {
            mainStack?.spacing = 50
        }
        
        if #available(iOS 12, *) {
            // iOS 12: Not the best solution, but it works.
            passField.textContentType = .oneTimeCode
            confirmPassField.textContentType = .oneTimeCode
        } else {
            // iOS 11: Disables the autofill accessory view.
            passField.textContentType = .init(rawValue: "")
            confirmPassField.textContentType = .init(rawValue: "")
        }
        
        passField.addTarget(self, action: #selector(textFieldDidChange(_:)), for: .editingChanged)
        confirmPassField.addTarget(self, action: #selector(textFieldDidChange(_:)), for: .editingChanged)
        
        let backButton = UIButton(type: .system)
        backButton.frame = CGRect(x: 0, y: 0, width: 40, height: 40)
        backButton.contentHorizontalAlignment = .left
        backButton.tintColor = UIColor.white
        backButton.setImage(UIImage.init(named: "iconBack"), for: .normal)
        backButton.addTarget(self, action: #selector(onBack), for: .touchUpInside)
        self.navigationItem.leftBarButtonItem = UIBarButtonItem(customView: backButton)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        if AppModel.sharedManager().isLoggedin {
            passField.becomeFirstResponder()
        }
    }
    
// MARK: IBAction
    
    @objc private func onBack() {
        if AppModel.sharedManager().isLoggedin {
            self.navigationController?.popViewController(animated: true)
        }
        else{
            let alert = UIAlertController(title: "return_to_seed_title".localized, message: "return_to_seed_info".localized, preferredStyle: .alert)
            
            let ok = UIAlertAction(title: "return".localized, style: .default, handler: { action in
                let viewControllers = self.navigationController?.viewControllers
                let vc = viewControllers![(viewControllers?.count)!-3]
                self.navigationController?.popToViewController(vc, animated: true)
            })
            alert.addAction(UIAlertAction(title: "cancel".localized, style: .default, handler: nil))
            alert.addAction(ok)
            
            self.present(alert, animated: true)
        }
    }
    
    @IBAction func onNext(sender :UIButton) {
        let pass = passField.text ?? ""
        let confirmPass = confirmPassField.text ?? ""
        
        if pass.isEmpty {
            self.passConfirmLabel.text = "empty_password".localized
            
            self.passField.status = BMField.Status.error
        }
        
        if confirmPass.isEmpty {
            self.passConfirmLabel.text = "empty_password".localized

            self.confirmPassField.status = BMField.Status.error
        }
        
        if !pass.isEmpty && !confirmPass.isEmpty {
            if pass == confirmPass {
                if AppModel.sharedManager().isLoggedin {
                    if AppModel.sharedManager().isValidPassword(pass)
                    {
                        self.passConfirmLabel.text = "old_password".localized
                        self.confirmPassField.status = BMField.Status.error
                        self.passField.status = BMField.Status.error
                    }
                    else{
                        goNext(pass: pass)
                    }
                }
                else{
                    if BiometricAuthorization.shared.canAuthenticate() {
                        
                        let mechanism = BiometricAuthorization.shared.faceIDAvailable() ? "Face ID" : "Touch ID"
                        
                        let message = "Would you like to use \(mechanism) for login to your wallet?\n\nAfter login \(mechanism) can be enabled or disabled at any time in the settings menu"
                        
                        let alertController = UIAlertController(title: "Enable \(mechanism)", message: message, preferredStyle: .alert)
                        
                        let yesAction = UIAlertAction(title: "enable".localized, style: .default) { (action) in
                            self.goNext(pass: pass)
                            
                            Settings.sharedManager().isEnableBiometric = true
                        }
                        
                        let noAction = UIAlertAction(title: "dont_use".localized, style: .destructive) { (action) in
                            self.goNext(pass: pass)
                            
                            Settings.sharedManager().isEnableBiometric = false
                        }
                        
                        alertController.addAction(noAction)
                        alertController.addAction(yesAction)
                        
                        self.present(alertController, animated: true, completion: nil)
                    }
                    else{
                        goNext(pass: pass)
                    }
                }
            }
            else{
                self.passConfirmLabel.text = "passwords_dont_match".localized
                self.confirmPassField.status = BMField.Status.error
                self.passField.status = BMField.Status.error
            }
        }
    }
    
    private func goNext(pass:String) {
        _ = KeychainManager.addPassword(password: pass)
        
        if AppModel.sharedManager().isLoggedin {
            AppModel.sharedManager().changePassword(pass)
            self.navigationController?.popViewController(animated: true)
        }
        else{
            let vc = CreateWalletProgressViewController()
                .withPassword(password: pass)
                .withPhrase(phrase: phrase)
            pushViewController(vc: vc)
        }
    }
}

// MARK: TextField Actions
extension CreateWalletPasswordViewController : UITextFieldDelegate {
    
    @objc func textFieldDidChange(_ textField: BMField) {
        let text = textField.text ?? ""
        
        if textField == passField {
            let state = PasswordTestManager.testPassword(password: text)
            
            switch state {
            case .none:
                passProgressView.currentStep = 0
                break;
            case .veryWeak:
                passProgressView.finishedStepColor = UIColor.main.red
                passProgressView.currentStep = 2
                break;
            case .weak:
                passProgressView.finishedStepColor = UIColor.main.maize
                passProgressView.currentStep = 3
                break;
            case .medium:
                passProgressView.finishedStepColor = UIColor.main.maize
                passProgressView.currentStep = 4
                break;
            case .strong:
                passProgressView.finishedStepColor = UIColor.main.brightTeal
                passProgressView.currentStep = 6
                break;
            case .veryStrong:
                passProgressView.finishedStepColor = UIColor.main.brightTeal
                passProgressView.currentStep = 6
                break;
            }
        }
        
        self.passConfirmLabel.text = ""
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        
        if textField == passField, textField.text?.isEmpty == false {
            confirmPassField.becomeFirstResponder()
        }
        
        return true
    }
    
    func textFieldShouldEndEditing(_ textField: UITextField) -> Bool {
        if textField == confirmPassField && (Device.screenType == .iPhones_5 || Device.isZoomed) {
            UIView.animate(withDuration: 0.25) {
                var frame = self.navigationController?.view.frame
                frame?.origin.y = 0
                self.navigationController?.view.frame = frame ?? CGRect.zero
            }
        }
        return true
    }
    
    func textFieldShouldBeginEditing(_ textField: UITextField) -> Bool {
        if textField == confirmPassField && (Device.screenType == .iPhones_5 || Device.isZoomed) {
            UIView.animate(withDuration: 0.25) {
                var frame = self.navigationController?.view.frame
                frame?.origin.y = -48
                self.navigationController?.view.frame = frame ?? CGRect.zero
            }
        }
        return true
    }
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        
        return true
    }
}

extension CreateWalletPasswordViewController {
    
    func withPhrase(phrase: String) -> Self {
        
        self.phrase = phrase
        
        return self
    }
}
