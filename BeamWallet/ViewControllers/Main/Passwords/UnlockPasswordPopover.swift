//
// UnlockPasswordPopover.swift
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

class UnlockPasswordPopover: BaseViewController {
    enum UnlockEvent {
        case transaction
        case node
        case settings
        case clear_wallet
    }
    
    private var event: UnlockEvent!
    private var allowBiometric: Bool = true
    
    @IBOutlet private var passField: BMField!
    @IBOutlet private var touchIdButton: UIButton!
    @IBOutlet private var loginLabel: UILabel!
    @IBOutlet private var height: NSLayoutConstraint!
    
    public var completion: ((Bool) -> Void)?
    
    init(event: UnlockEvent, allowBiometric: Bool = true) {
        super.init(nibName: nil, bundle: nil)
        
        self.event = event
        self.allowBiometric = allowBiometric
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError(Localizable.shared.strings.fatalInitCoderError)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = UIColor.clear
        view.isOpaque = false
        
        if !BiometricAuthorization.shared.canAuthenticate() || !Settings.sharedManager().isEnableBiometric || !allowBiometric {
            touchIdButton.isHidden = true
            height.constant = 300
            loginLabel.text = getTextForPassword()
        }
        else {
            if BiometricAuthorization.shared.faceIDAvailable() {
                touchIdButton.isHidden = true
                height.constant = 300
                loginLabel.text = getTextForFaceID()
            }
            else {
                loginLabel.text = getTextForTouchID()
            }
        }
        
        addSwipeToDismiss()
    }
    
    private func getTextForFaceID() -> String {
        switch event {
            case .transaction:
                return Localizable.shared.strings.confirm_transaction_2
            case .node:
                return Localizable.shared.strings.change_node_text_1
            case .settings:
                return Localizable.shared.strings.change_settings_text_1
            case .clear_wallet:
                return String.empty()
            case .none:
                return String.empty()
        }
    }
    
    private func getTextForTouchID() -> String {
        switch event {
            case .transaction:
                return Localizable.shared.strings.confirm_transaction_1
            case .node:
                return Localizable.shared.strings.change_node_text_2
            case .settings:
                return Localizable.shared.strings.change_settings_text_2
            case .clear_wallet:
                return String.empty()
            case .none:
                return String.empty()
        }
    }
    
    private func getTextForPassword() -> String {
        switch event {
            case .transaction:
                return Localizable.shared.strings.confirm_transaction_3
            case .node:
                return Localizable.shared.strings.change_node_text_3
            case .settings:
                return Localizable.shared.strings.change_settings_text_3
            case .clear_wallet:
                return Localizable.shared.strings.clear_wallet_password
            case .none:
                return String.empty()
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        if BiometricAuthorization.shared.canAuthenticate(), Settings.sharedManager().isEnableBiometric, BiometricAuthorization.shared.faceIDAvailable(), allowBiometric {
            biometricAuthorization()
        }
    }
    
    public func biometricAuthorization() {
        if BiometricAuthorization.shared.canAuthenticate(), Settings.sharedManager().isEnableBiometric {
            BiometricAuthorization.shared.authenticateWithBioMetrics(success: {
                if let password = KeychainManager.getPassword() {
                    self.passField.text = password
                    self.dismiss(animated: true, completion: {
                        self.completion?(true)
                    })
                }
                
            }, failure: {
                self.touchIdButton.tintColor = UIColor.white
                if BiometricAuthorization.shared.faceIDAvailable() {
                    self.loginLabel.text = Localizable.shared.strings.confirm_transaction_3
                }
                
            }, retry: {
                self.touchIdButton.tintColor = UIColor.white
            })
        }
    }
    
    @IBAction func onTouchId(sender: UIButton) {
        touchIdButton.tintColor = UIColor.white
        
        biometricAuthorization()
    }
    
    @IBAction func onLogin(sender: UIButton) {
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
            else {
                dismiss(animated: true, completion: {
                    self.completion?(true)
                })
            }
        }
    }
    
    @IBAction func onClose(sender: UIButton) {
        dismiss(animated: true, completion: nil)
    }
}

extension UnlockPasswordPopover: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        touchIdButton.tintColor = UIColor.white
        
        return true
    }
}
