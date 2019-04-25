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
            let mechanism = BiometricAuthorization.shared.faceIDAvailable() ? "Face ID " : "Touch ID "

            loginLabel.text = "use".localized +  mechanism + "enter_password_title_2".localized
        }
        
       biometricAuthorization()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        AppModel.sharedManager().cancelForgotPassword()
    }
    
    private func biometricAuthorization() {
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
            errorLabel.text = "empty_password".localized
            passField.status = BMField.Status.error
        }
        else if let pass = passField.text {
            let appModel = AppModel.sharedManager()
            let valid = appModel.canOpenWallet(pass)
            if !valid {
                errorLabel.text = "incorrect_password".localized
                passField.status = BMField.Status.error
            }
            else{
//                if(AppModel.sharedManager().isValidNodeAddress(Settings.sharedManager().nodeAddress) == false) {
//                    let alert = UIAlertController(title: "incompatible_node_title".localized, message: "incompatible_node_info".localized, preferredStyle: .alert)
//
//                    let ok = UIAlertAction(title: "change_settings".localized, style: .default, handler: { action in
//                        let vc = EnterNodeAddressViewController()
//                        vc.hidesBottomBarWhenPushed = true
//                        self.pushViewController(vc: vc)
//                    })
//                    alert.addAction(ok)
//
//                    alert.addAction(UIAlertAction(title: "cancel".localized, style: .default, handler: nil))
//
//                    self.present(alert, animated: true)
//                }
//                else{
                    _ = KeychainManager.addPassword(password: pass)
                    
                    let vc = CreateWalletProgressViewController()
                        .withPassword(password: pass)
                    pushViewController(vc: vc)
//                }
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
        
        errorLabel.text = ""
     
        return true
    }
    
}
