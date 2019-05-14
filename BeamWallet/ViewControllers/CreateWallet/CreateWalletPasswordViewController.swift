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
        
        self.title = AppModel.sharedManager().isLoggedin ? LocalizableStrings.change_password : LocalizableStrings.password

        if Device.isZoomed {
            stackY?.constant = 10
            mainStack?.spacing = 30
        }
        else if Device.screenType == .iPhones_5 {
            mainStack?.spacing = 50
        }
                
        passField.addTarget(self, action: #selector(textFieldDidChange(_:)), for: .editingChanged)
        confirmPassField.addTarget(self, action: #selector(textFieldDidChange(_:)), for: .editingChanged)
        
        addCustomBackButton(target: self, selector: #selector(onBack))
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
            self.confirmAlert(title: LocalizableStrings.return_to_seed_title, message: LocalizableStrings.return_to_seed_info, cancelTitle: LocalizableStrings.cancel, confirmTitle: LocalizableStrings.retur, cancelHandler: { (_ ) in
                
            }) { (_ ) in
                let viewControllers = self.navigationController?.viewControllers
                let vc = viewControllers![(viewControllers?.count)!-3]
                self.navigationController?.popToViewController(vc, animated: true)
            }
        }
    }
    
    @IBAction func onNext(sender :UIButton) {
        let pass = passField.text ?? String.empty()
        let confirmPass = confirmPassField.text ?? String.empty()
        
        if pass.isEmpty {
            self.passConfirmLabel.text = LocalizableStrings.empty_password
            
            self.passField.status = BMField.Status.error
        }
        
        if confirmPass.isEmpty {
            self.passConfirmLabel.text = LocalizableStrings.empty_password

            self.confirmPassField.status = BMField.Status.error
        }
        
        if !pass.isEmpty && !confirmPass.isEmpty {
            if pass == confirmPass {
                if AppModel.sharedManager().isLoggedin {
                    if AppModel.sharedManager().isValidPassword(pass)
                    {
                        self.passConfirmLabel.text = LocalizableStrings.old_password
                        self.confirmPassField.status = BMField.Status.error
                        self.passField.status = BMField.Status.error
                    }
                    else{
                        self.goNext(pass: pass)
                    }
                }
                else{
                    if BiometricAuthorization.shared.canAuthenticate() {
                        
                        let title = BiometricAuthorization.shared.faceIDAvailable() ? LocalizableStrings.enable_face_id_title : LocalizableStrings.enable_touch_id_title

                        let message = BiometricAuthorization.shared.faceIDAvailable() ? LocalizableStrings.enable_face_id_text : LocalizableStrings.enable_touch_id_text
                        
                        self.confirmAlert(title: title, message: message, cancelTitle: LocalizableStrings.dont_use, confirmTitle: LocalizableStrings.enable, cancelHandler: { (_ ) in
                            self.goNext(pass: pass)
                            
                            Settings.sharedManager().isEnableBiometric = false
                            
                        }) { (_ ) in
                            self.goNext(pass: pass)
                            
                            Settings.sharedManager().isEnableBiometric = true
                        }
                    }
                    else{
                        self.goNext(pass: pass)
                    }
                }
            }
            else{
                self.passConfirmLabel.text = LocalizableStrings.passwords_dont_match
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
        let text = textField.text ?? String.empty()
        
        if textField == passField {
            let state = PasswordTestManager.testPassword(password: text)
            
            switch state {
            case .none:
                passProgressView.currentStep = 0
                break;
            case .veryWeak:
                passProgressView.finishedStepColor = UIColor.main.red
                passProgressView.currentStep = 1
                break;
            case .weak:
                passProgressView.finishedStepColor = UIColor.main.red
                passProgressView.currentStep = 2
                break;
            case .medium:
                passProgressView.finishedStepColor = UIColor.main.maize
                passProgressView.currentStep = 3
                break;
            case .medium_two:
                passProgressView.finishedStepColor = UIColor.main.maize
                passProgressView.currentStep = 4
                break;
            case .strong:
                passProgressView.finishedStepColor = UIColor.main.brightTeal
                passProgressView.currentStep = 5
                break;
            case .veryStrong:
                passProgressView.finishedStepColor = UIColor.main.brightTeal
                passProgressView.currentStep = 6
                break;
            }
        }
        
        self.passConfirmLabel.text = String.empty()
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
