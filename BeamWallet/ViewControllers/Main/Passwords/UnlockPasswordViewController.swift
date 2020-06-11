//
// UnlockPasswordViewController.swift
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

class UnlockPasswordViewController: BMInputViewController {
    enum UnlockEvent {
        case unlock
        case changePassword
    }
        
    private var event: UnlockEvent!
    private var isUnlocked = false
    
    public var completion: ((Bool) -> Void)?
    
    init(event: UnlockEvent) {
        super.init(nibName: "BMInputViewController", bundle: nil)

        self.event = event
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError(Localizable.shared.strings.fatalInitCoderError)
    }
        
    override func viewDidLoad() {
        super.viewDidLoad()
        
        inputField.isSecureTextEntry = true
        inputField.placeholder = Localizable.shared.strings.enter_password
        inputField.placeHolderColor = UIColor.white.withAlphaComponent(0.2)
        inputField.delegate = self
        
        switch event {
        case .unlock:
            title = Localizable.shared.strings.your_password
            titleLabel.text = Localizable.shared.strings.unlock_password
        case .changePassword:
            title = Localizable.shared.strings.change_password
            titleLabel.text = Localizable.shared.strings.your_current_password
        default:
            break
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        _ = inputField.becomeFirstResponder()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        
        completion?(isUnlocked)
    }
    
    override func onNext() {
        if inputField.text?.isEmpty ?? true {
            inputField.error = Localizable.shared.strings.empty_password
            inputField.status = BMField.Status.error
        }
        else if let pass = inputField.text {
            let valid = AppModel.sharedManager().isValidPassword(pass)
            if !valid {
                inputField.error = Localizable.shared.strings.current_password_error
                inputField.status = BMField.Status.error
            }
            else {
                isUnlocked = true
                
                if event == .unlock {
                    if navigationController?.viewControllers.count == 1 {
                        dismiss(animated: true) {}
                    }
                    else {
                        back()
                    }
                }
                else {
                    let vc = CreateWalletPasswordViewController()
                    if var viewControllers = self.navigationController?.viewControllers {
                        viewControllers[viewControllers.count - 1] = vc
                        navigationController?.setViewControllers(viewControllers, animated: true)
                    }
                }
            }
        }
    }
}

// MARK: TextField Actions

extension UnlockPasswordViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        
        return true
    }
}
