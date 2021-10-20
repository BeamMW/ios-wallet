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
    @IBOutlet private weak var oldPassField: BMField!
    @IBOutlet private weak var oldPassView: UIStackView!

    @IBOutlet private weak var passField: BMField!
    @IBOutlet private weak var confirmPassField: BMField!
    @IBOutlet private weak var passProgressView: BMStepView!
    @IBOutlet private weak var saveButton: UIButton!
    @IBOutlet private weak var scrollView: UIScrollView!
   
    @IBOutlet private weak var subTitleLabel: UILabel!
    @IBOutlet private weak var passwordHintLabel: UILabel!

    @IBOutlet private weak var passTitleLabel: UILabel!
    @IBOutlet private weak var confirmPassTitleLabel: UILabel!
    @IBOutlet private weak var hintLabel: UILabel!
    @IBOutlet private weak var nextButton: BMButton!

    private var phrase: String!
    private var activeField: UITextField?
    
    @IBOutlet private weak var topViewOffset: NSLayoutConstraint!

    
    private var isChangePassword = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        nextButton.isEnabled = false
        
        passField.showEye = true
        oldPassField.showEye = true
        confirmPassField.showEye = true

        isChangePassword = AppModel.sharedManager().isLoggedin
        
        if  isChangePassword {
            oldPassView.isHidden = false
            
            subTitleLabel.isHidden = true
            subTitleLabel.text = nil
            topViewOffset.constant = 5
            
            saveButton.setTitle(Localizable.shared.strings.save, for: .normal)
            saveButton.setImage(IconSaveDone(), for: .normal)
            
            passTitleLabel.text = Localizable.shared.strings.new_password.uppercased()
            passTitleLabel.letterSpacing = 1.2
        }
        
        
        setGradientTopBar(mainColor: UIColor.main.peacockBlue, addedStatusView: isChangePassword)
        
        title = isChangePassword ? Localizable.shared.strings.change_password : Localizable.shared.strings.create_password
        
        passField.addTarget(self, action: #selector(textFieldDidChange(_:)), for: .editingChanged)
        confirmPassField.addTarget(self, action: #selector(textFieldDidChange(_:)), for: .editingChanged)
        oldPassField.addTarget(self, action: #selector(textFieldDidChange(_:)), for: .editingChanged)

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
    
    
    private func checkButton() {
        let p1 = passField.text ?? ""
        let p2 = confirmPassField.text ?? ""
        let p3 = oldPassField.text ?? ""
        
        if isChangePassword {
            nextButton.isEnabled = !p1.isEmpty && !p2.isEmpty && !p3.isEmpty
        }
        else {
            nextButton.isEnabled = !p1.isEmpty && !p2.isEmpty
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
        let oldPass = oldPassField.text ?? String.empty()
       
        if isChangePassword && !AppModel.sharedManager().isValidPassword(oldPass) {
            oldPassField.error = Localizable.shared.strings.current_password_error
            oldPassField.status = BMField.Status.error
            nextButton.isEnabled = false
        }
        else if !pass.isEmpty, !confirmPass.isEmpty {
            if pass == confirmPass {
                if isChangePassword {
                    if AppModel.sharedManager().isValidPassword(pass) {
                        confirmPassField.error = Localizable.shared.strings.old_password
                        confirmPassField.status = BMField.Status.error
                        nextButton.isEnabled = false
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
                nextButton.isEnabled = false
            }
        }
    }
    
    private func goNext(pass: String) {
        if isChangePassword {
            AppModel.sharedManager().changePassword(pass)
            _ = KeychainManager.addPassword(password: pass)
            
            back()
        }
        else if AppModel.sharedManager().isRestoreFlow {
            let vc = RestoreOptionsViewController(password: pass, phrase: phrase)
            pushViewController(vc: vc)
        }
        else {
            openMainPage()
        }
    }
    
    private func openMainPage() {
        if let phrase = phrase, let pass = passField.text {
            let created = AppModel.sharedManager().createWallet(phrase, pass: pass)
            if(!created)
            {
                self.alert(title: Localizable.shared.strings.error, message: Localizable.shared.strings.wallet_not_created) { (_ ) in
                 
                }
            }
            else {
                OnboardManager.shared.saveSeed(seed: phrase)
                _ = KeychainManager.addPassword(password: pass)
  
                if AppModel.sharedManager().isRestoreFlow {
                    let vc = OpenWalletProgressViewController(password: pass, phrase: phrase)
                    self.pushViewController(vc: vc)
                }
                else {
                    let vc = SelectNodeViewController()
                    vc.isCreateWallet = true
                    vc.isNeedDisconnect = false
                    vc.password = pass
                    vc.phrase = phrase
                    self.pushViewController(vc: vc)
                }
            }
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
                passwordHintLabel.text = nil
                passwordHintLabel.isHidden = true
                passProgressView.currentStep = 0
            case .veryWeak:
                passwordHintLabel.isHidden = false
                passwordHintLabel.text = Localizable.shared.strings.very_weak_password
                passProgressView.finishedStepColor = UIColor.main.red
                passProgressView.currentStep = 1
            case .weak:
                passwordHintLabel.isHidden = false
                passwordHintLabel.text = Localizable.shared.strings.weak_password
                passProgressView.finishedStepColor = UIColor.main.red
                passProgressView.currentStep = 2
            case .medium:
                passwordHintLabel.isHidden = false
                passwordHintLabel.text = Localizable.shared.strings.medium_password
                passProgressView.finishedStepColor = UIColor.main.maize
                passProgressView.currentStep = 3
            case .medium_two:
                passwordHintLabel.isHidden = false
                passwordHintLabel.text = Localizable.shared.strings.medium_password
                passProgressView.finishedStepColor = UIColor.main.maize
                passProgressView.currentStep = 4
            case .strong:
                passwordHintLabel.isHidden = false
                passwordHintLabel.text = Localizable.shared.strings.strong_password
                passProgressView.finishedStepColor = UIColor.main.brightTeal
                passProgressView.currentStep = 5
            case .veryStrong:
                passwordHintLabel.isHidden = false
                passwordHintLabel.text = Localizable.shared.strings.very_strong_password
                passProgressView.finishedStepColor = UIColor.main.brightTeal
                passProgressView.currentStep = 6
            }
        }
        
        oldPassField.status = BMField.Status.normal
        passField.status = BMField.Status.normal
        confirmPassField.status = BMField.Status.normal
        
        checkButton()
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
            var offset = scrollView.contentSize.height - keyboardSize.height
            offset = 150

            let contentInsets: UIEdgeInsets = UIEdgeInsets(top: 0.0, left: 0.0, bottom: offset, right: 0.0)
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
