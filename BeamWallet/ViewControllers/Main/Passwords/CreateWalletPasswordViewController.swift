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
    @IBOutlet var constraintContentHeight: NSLayoutConstraint!
    
    private var phrase: String!
    private var activeField: UITextField?
    
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
        
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillHideNotification, object: nil)
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
            back()
        }
        else {
            confirmAlert(title: Localizable.shared.strings.return_to_seed_title, message: Localizable.shared.strings.return_to_seed_info, cancelTitle: Localizable.shared.strings.cancel, confirmTitle: Localizable.shared.strings.retur, cancelHandler: { _ in
                
            }) { _ in
                let count = OnboardManager.shared.isSkipedSeed() ? 2 : 3
                let viewControllers = self.navigationController?.viewControllers
                let vc = viewControllers![(viewControllers?.count)! - count]
                self.navigationController?.popToViewController(vc, animated: true)
            }
        }
    }
    
    @IBAction func onNext(sender: UIButton) {
        let pass = passField.text ?? String.empty()
        let confirmPass = confirmPassField.text ?? String.empty()
        
        if pass.isEmpty {
            confirmPassField.error = Localizable.shared.strings.empty_password
            
            passField.status = BMField.Status.error
        }
        
        if confirmPass.isEmpty {
            confirmPassField.error = Localizable.shared.strings.empty_password
            
            confirmPassField.status = BMField.Status.error
        }
        
        if !pass.isEmpty, !confirmPass.isEmpty {
            if pass == confirmPass {
                if AppModel.sharedManager().isLoggedin {
                    if AppModel.sharedManager().isValidPassword(pass) {
                        confirmPassField.error = Localizable.shared.strings.old_password
                        confirmPassField.status = BMField.Status.error
                        passField.status = BMField.Status.error
                    }
                    else {
                        goNext(pass: pass)
                    }
                }
                else {
                    if BiometricAuthorization.shared.canAuthenticate() {
                        let title = BiometricAuthorization.shared.faceIDAvailable() ? Localizable.shared.strings.enable_face_id_title : Localizable.shared.strings.enable_touch_id_title
                        
                        let message = BiometricAuthorization.shared.faceIDAvailable() ? Localizable.shared.strings.enable_face_id_text : Localizable.shared.strings.enable_touch_id_text
                        
                        confirmAlert(title: title, message: message, cancelTitle: Localizable.shared.strings.dont_use, confirmTitle: Localizable.shared.strings.enable, cancelHandler: { _ in
                            self.goNext(pass: pass)
                            
                            Settings.sharedManager().isEnableBiometric = false
                            
                        }) { _ in
                            self.goNext(pass: pass)
                            
                            Settings.sharedManager().isEnableBiometric = true
                        }
                    }
                    else {
                        goNext(pass: pass)
                    }
                }
            }
            else {
                confirmPassField.error = Localizable.shared.strings.passwords_dont_match
                confirmPassField.status = BMField.Status.error
                passField.status = BMField.Status.error
            }
        }
    }
    
    private func goNext(pass: String) {
        if AppModel.sharedManager().isLoggedin {
            AppModel.sharedManager().changePassword(pass)
            KeychainManager.addPassword(password: pass)
            
            back()
        }
        else if AppModel.sharedManager().isRestoreFlow {
            let vc = RestoreOptionsViewController(password: pass, phrase: phrase)
            pushViewController(vc: vc)
        }
        else {
            let vc = OpenWalletProgressViewController(password: pass, phrase: phrase)
            pushViewController(vc: vc)
        }
    }
}

// MARK: TextField Actions

extension CreateWalletPasswordViewController: UITextFieldDelegate {
    @objc func textFieldDidChange(_ textField: BMField) {
        let text = textField.text ?? String.empty()
        
        if textField == passField {
            let state = PasswordTestManager.testPassword(password: text)
            
            switch state {
            case .none:
                passProgressView.currentStep = 0
            case .veryWeak:
                passProgressView.finishedStepColor = UIColor.main.red
                passProgressView.currentStep = 1
            case .weak:
                passProgressView.finishedStepColor = UIColor.main.red
                passProgressView.currentStep = 2
            case .medium:
                passProgressView.finishedStepColor = UIColor.main.maize
                passProgressView.currentStep = 3
            case .medium_two:
                passProgressView.finishedStepColor = UIColor.main.maize
                passProgressView.currentStep = 4
            case .strong:
                passProgressView.finishedStepColor = UIColor.main.brightTeal
                passProgressView.currentStep = 5
            case .veryStrong:
                passProgressView.finishedStepColor = UIColor.main.brightTeal
                passProgressView.currentStep = 6
            }
        }
        
        passField.status = BMField.Status.normal
        confirmPassField.status = BMField.Status.normal
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        
        if textField == passField {
            _ = confirmPassField.becomeFirstResponder()
        }
        
        return true
    }
    
    func textFieldShouldBeginEditing(_ textField: UITextField) -> Bool {
        activeField = textField
        return true
    }
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        if !Device.isLarge {
            var point = textField.frame.origin
            point.y = point.y - 5
            scrollView.setContentOffset(CGPoint(x: 0, y: point.y), animated: true)
        }
    }
}

extension CreateWalletPasswordViewController {
    @objc func keyboardWillShow(_ notification: Notification) {
        if let userInfo = notification.userInfo,
            let keyboardSize = (userInfo[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue,
            let duration: TimeInterval = (userInfo[UIResponder.keyboardAnimationDurationUserInfoKey] as? NSNumber)?.doubleValue,
            let animationCurveRaw = userInfo[UIResponder.keyboardAnimationCurveUserInfoKey] as? NSNumber {
            let animationCurve: UIView.AnimationOptions = UIView.AnimationOptions(rawValue: UIView.AnimationOptions.RawValue(truncating: animationCurveRaw))
            let contentInsets: UIEdgeInsets = UIEdgeInsets(top: 0.0, left: 0.0, bottom: keyboardSize.height, right: 0.0)
            UIView.animate(withDuration: duration, delay: 0, options: animationCurve, animations: {
                self.scrollView.contentInset = contentInsets
                self.scrollView.scrollIndicatorInsets = contentInsets
                var aRect: CGRect = self.view.frame
                aRect.size.height -= keyboardSize.height
                if let activeField = self.activeField {
                    if !aRect.contains(activeField.frame.origin) {
                        self.scrollView.scrollRectToVisible(activeField.frame, animated: false)
                    }
                }
            }, completion: nil)
        }
    }
    
    @objc func keyboardWillHide(notification: NSNotification) {
        if let userInfo = notification.userInfo,
            let duration: TimeInterval = (userInfo[UIResponder.keyboardAnimationDurationUserInfoKey] as? NSNumber)?.doubleValue,
            let animationCurveRaw = userInfo[UIResponder.keyboardAnimationCurveUserInfoKey] as? NSNumber {
            let animationCurve: UIView.AnimationOptions = UIView.AnimationOptions(rawValue: UIView.AnimationOptions.RawValue(truncating: animationCurveRaw))
            UIView.animate(withDuration: duration, delay: 0, options: animationCurve, animations: {
                self.scrollView.contentInset = .zero
                self.scrollView.scrollIndicatorInsets = .zero
            }, completion: nil)
        }
    }
}

extension CreateWalletPasswordViewController {
    func withPhrase(phrase: String) -> Self {
        self.phrase = phrase
        return self
    }
}
