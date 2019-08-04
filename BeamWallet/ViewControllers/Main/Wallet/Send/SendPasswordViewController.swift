//
// SendPasswordViewController.swift
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

class SendPasswordViewController: BaseViewController {

    @IBOutlet private weak var passField: BMField!
    @IBOutlet private weak var touchIdButton: UIButton!
    @IBOutlet private weak var loginLabel: UILabel!
    @IBOutlet private weak var height: NSLayoutConstraint!

    public var completion : ((Bool) -> Void)?

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = UIColor.clear
        view.isOpaque = false

        if !BiometricAuthorization.shared.canAuthenticate() || !Settings.sharedManager().isEnableBiometric {
            touchIdButton.isHidden = true
            height.constant = 300
            loginLabel.text = Localizable.shared.strings.confirm_transaction_3
        }
        else{
            if BiometricAuthorization.shared.faceIDAvailable() {
                touchIdButton.isHidden = true
                height.constant = 300
                loginLabel.text = Localizable.shared.strings.confirm_transaction_2
            }
            else{
                loginLabel.text = Localizable.shared.strings.confirm_transaction_1
            }
        }
        
        addSwipeToDismiss()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        if BiometricAuthorization.shared.canAuthenticate() && Settings.sharedManager().isEnableBiometric && BiometricAuthorization.shared.faceIDAvailable()  {

            biometricAuthorization()
        }
    }
    
    public func biometricAuthorization() {
        if BiometricAuthorization.shared.canAuthenticate() && Settings.sharedManager().isEnableBiometric {
            
            BiometricAuthorization.shared.authenticateWithBioMetrics(success: {
                if let password = KeychainManager.getPassword() {
                    self.passField.text = password
                    self.dismiss(animated: true, completion: {
                        self.completion?(true)
                    })
                }
                
            }, failure: {
                self.touchIdButton.tintColor = UIColor.main.red
                if BiometricAuthorization.shared.faceIDAvailable() {
                    self.loginLabel.text = Localizable.shared.strings.confirm_transaction_3
                }
                
            }, retry: {
                self.touchIdButton.tintColor = UIColor.white
            })
        }
    }
    
    @IBAction func onTouchId(sender :UIButton) {
        touchIdButton.tintColor = UIColor.white
        
        biometricAuthorization()
    }
    
    @IBAction func onLogin(sender :UIButton) {
        
        if passField.text?.isEmpty ?? true {
            passField.error = Localizable.shared.strings.empty_password
            passField.status = BMField.Status.error
        }
        else if let pass = passField.text {
            let password = KeychainManager.getPassword() ?? String.empty()
            let valid = password == pass
            if !valid {
                passField.error = Localizable.shared.strings.incorrect_password
                passField.status = BMField.Status.error
            }
            else{
                self.dismiss(animated: true, completion: {
                    self.completion?(true)
                })
            }
        }
    }
    
    @IBAction func onClose(sender :UIButton) {
        dismiss(animated: true, completion:nil)
    }
}

extension SendPasswordViewController : UITextFieldDelegate {
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        
        touchIdButton.tintColor = UIColor.white

        return true
    }
}
