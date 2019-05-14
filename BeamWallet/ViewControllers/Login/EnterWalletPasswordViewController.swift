//
// EnterWalletPasswordViewController.swift
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

class EnterWalletPasswordViewController: BaseWizardViewController {

    private var isRequestedAuthorization = false
    
    @IBOutlet private weak var passField: BMField!
    @IBOutlet private weak var errorLabel: UILabel!
    @IBOutlet private weak var touchIdButton: UIButton!
    @IBOutlet private weak var passViewHeight: NSLayoutConstraint!
    @IBOutlet private weak var loginLabel: UILabel!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        if Device.isZoomed {
            mainStack?.spacing = 40
            passViewHeight.constant = 50
        }
        else if Device.screenType == .iPhones_5 {
            mainStack?.spacing = 60
            passViewHeight.constant = 70
        }
        
        if !BiometricAuthorization.shared.canAuthenticate() || !Settings.sharedManager().isEnableBiometric {
            touchIdButton.isHidden = true
        }
        else{
            let mechanism = BiometricAuthorization.shared.faceIDAvailable() ? LocalizableStrings.face_id : LocalizableStrings.touch_id

            loginLabel.text = LocalizableStrings.use + mechanism + LocalizableStrings.enter_password_title_2
        }
        
        NotificationCenter.default.addObserver(self, selector: #selector(didBecomeActive), name: UIApplication.didBecomeActiveNotification, object: nil)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        AppModel.sharedManager().cancelForgotPassword()
        
        if (self.presentedViewController as? UIAlertController) != nil {
            
        }
        else{
            if isRequestedAuthorization == false && TGBotManager.sharedManager.isNeedLinking() == false && UIApplication.shared.applicationState == .active {
                isRequestedAuthorization = true

                biometricAuthorization()
            }
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        
        NotificationCenter.default.removeObserver(self, name: UIApplication.didBecomeActiveNotification, object: nil)
    }
    
    @objc private func didBecomeActive() {
        if UIApplication.shared.applicationState == .active {
            viewWillAppear(false)
        }
    }
    
    public func biometricAuthorization() {        
        if BiometricAuthorization.shared.canAuthenticate() && Settings.sharedManager().isEnableBiometric {
            
            BiometricAuthorization.shared.authenticateWithBioMetrics(success: {
                if let password = KeychainManager.getPassword() {
                    self.passField.text = password
                    self.onLogin(sender: UIButton())
                }

            }, failure: {
                 self.touchIdButton.tintColor = UIColor.main.red
            }, retry: {
                self.touchIdButton.tintColor = UIColor.white
            })
        }
    }
    
    //MARK: IBAction
    
    @IBAction func onTouchId(sender :UIButton) {
        touchIdButton.tintColor = UIColor.white

        biometricAuthorization()
    }
    
    @IBAction func onLogin(sender :UIButton) {
        AppModel.sharedManager().isRestoreFlow = false;

        if passField.text?.isEmpty ?? true {
            errorLabel.text = LocalizableStrings.empty_password
            passField.status = BMField.Status.error
        }
        else if let pass = passField.text {
            let appModel = AppModel.sharedManager()
            let valid = appModel.canOpenWallet(pass)
            if !valid {
                errorLabel.text = LocalizableStrings.incorrect_password
                passField.status = BMField.Status.error
            }
            else{
                _ = KeychainManager.addPassword(password: pass)
                
                let vc = CreateWalletProgressViewController()
                    .withPassword(password: pass)
                pushViewController(vc: vc)
            }
        }
    }
    
    @IBAction func onChangeWallet(sender :UIButton) {
        let vc = LoginViewController()
        pushViewController(vc: vc)
    }
}

// MARK: TextField Actions
extension EnterWalletPasswordViewController : UITextFieldDelegate {
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        
        errorLabel.text = String.empty()
     
        return true
    }
}
