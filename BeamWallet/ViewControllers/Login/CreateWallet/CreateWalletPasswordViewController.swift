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
    @IBOutlet private weak var saveButton: UIButton!
    @IBOutlet private weak var scrollView: UIScrollView!
    @IBOutlet private weak var subTitleLabel: UILabel!

    private var phrase:String!
    
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
        
        if AppModel.sharedManager().isLoggedin {
            subTitleLabel.text = Localizable.shared.strings.create_new_password_short
            
            saveButton.setTitle(Localizable.shared.strings.save, for: .normal)
            saveButton.setImage(IconSaveDone(), for: .normal)
        }
        
        setGradientTopBar(mainColor: UIColor.main.peacockBlue, addedStatusView: false)
        
        title = AppModel.sharedManager().isLoggedin ? Localizable.shared.strings.change_password : Localizable.shared.strings.create_password
                
        passField.addTarget(self, action: #selector(textFieldDidChange(_:)), for: .editingChanged)
        confirmPassField.addTarget(self, action: #selector(textFieldDidChange(_:)), for: .editingChanged)
        
        addCustomBackButton(target: self, selector: #selector(onBack))
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: UIResponder.keyboardWillHideNotification, object: nil)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillShowNotification , object: nil)
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillHideNotification , object: nil)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        if AppModel.sharedManager().isLoggedin {
            _ = passField.becomeFirstResponder()
        }
    }
    
// MARK: IBAction
    
    @objc private func onBack() {
        if AppModel.sharedManager().isLoggedin || AppModel.sharedManager().isRestoreFlow {
            self.back()
        }
        else{
            self.confirmAlert(title: Localizable.shared.strings.return_to_seed_title, message: Localizable.shared.strings.return_to_seed_info, cancelTitle: Localizable.shared.strings.cancel, confirmTitle: Localizable.shared.strings.retur, cancelHandler: { (_ ) in
                
            }) { (_ ) in
                let count = OnboardManager.shared.isSkipedSeed() ? 2 : 3
                let viewControllers = self.navigationController?.viewControllers
                let vc = viewControllers![(viewControllers?.count)!-count]
                self.navigationController?.popToViewController(vc, animated: true)
            }
        }
    }
    
    @IBAction func onNext(sender :UIButton) {
        let pass = passField.text ?? String.empty()
        let confirmPass = confirmPassField.text ?? String.empty()
        
        if pass.isEmpty {
            self.confirmPassField.error = Localizable.shared.strings.empty_password
            
            self.passField.status = BMField.Status.error
        }
        
        if confirmPass.isEmpty {
            self.confirmPassField.error = Localizable.shared.strings.empty_password

            self.confirmPassField.status = BMField.Status.error
        }
        
        if !pass.isEmpty && !confirmPass.isEmpty {
            if pass == confirmPass {
                if AppModel.sharedManager().isLoggedin {
                    if AppModel.sharedManager().isValidPassword(pass)
                    {
                        self.confirmPassField.error = Localizable.shared.strings.old_password
                        self.confirmPassField.status = BMField.Status.error
                        self.passField.status = BMField.Status.error
                    }
                    else{
                        self.goNext(pass: pass)
                    }
                }
                else{
                    if BiometricAuthorization.shared.canAuthenticate() {
                        
                        let title = BiometricAuthorization.shared.faceIDAvailable() ? Localizable.shared.strings.enable_face_id_title : Localizable.shared.strings.enable_touch_id_title

                        let message = BiometricAuthorization.shared.faceIDAvailable() ? Localizable.shared.strings.enable_face_id_text : Localizable.shared.strings.enable_touch_id_text
                        
                        self.confirmAlert(title: title, message: message, cancelTitle: Localizable.shared.strings.dont_use, confirmTitle: Localizable.shared.strings.enable, cancelHandler: { (_ ) in
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
                self.confirmPassField.error = Localizable.shared.strings.passwords_dont_match
                self.confirmPassField.status = BMField.Status.error
                self.passField.status = BMField.Status.error
            }
        }
    }
    
    private func goNext(pass:String) {
        if AppModel.sharedManager().isLoggedin {
            AppModel.sharedManager().changePassword(pass)
            
            self.back()
        }
        else if AppModel.sharedManager().isRestoreFlow {
            let vc = RestoreOptionsViewController(password: pass, phrase: phrase)
            pushViewController(vc: vc)
        }
        else{
            let vc = CreateWalletProgressViewController(password: pass, phrase: phrase)
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
        
        self.passField.status = BMField.Status.normal
        self.confirmPassField.status = BMField.Status.normal
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        
        if textField == passField {
            _ = confirmPassField.becomeFirstResponder()
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
                frame?.origin.y = (Device.screenType == .iPhones_Plus) ? 0 : -105
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

extension CreateWalletPasswordViewController {
    
    func withPhrase(phrase: String) -> Self {
        
        self.phrase = phrase
        
        return self
    }
}
