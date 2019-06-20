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

class UnlockPasswordViewController: BaseWizardViewController {

    enum UnlockEvent {
        case unlock
        case changePassword
    }
    
    @IBOutlet private weak var passField: BMField!
    @IBOutlet private weak var titleLabel: UILabel!
    @IBOutlet private var heightConstraint: NSLayoutConstraint!

    private var event:UnlockEvent!
    private var isUnlocked = false
    
    public var completion : ((Bool) -> Void)?
    
    init(event:UnlockEvent) {
        super.init(nibName: nil, bundle: nil)

        self.event = event
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError(LocalizableStrings.fatalInitCoderError)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        hideKeyboardWhenTappedAround()
        
        title = event == .unlock ? LocalizableStrings.your_password : LocalizableStrings.change_password
        
        if event == .unlock {
            titleLabel.text = LocalizableStrings.unlock_password
        }
        
        if Device.isZoomed {
            heightConstraint.constant = 250
        }
        
        if Device.screenType == .iPhones_5 {
            mainStack?.spacing = 50
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        _ = passField.becomeFirstResponder()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        completion?(isUnlocked)
    }
    
    @IBAction func onLogin(sender :UIButton) {        
        if passField.text?.isEmpty ?? true {
            passField.error = LocalizableStrings.empty_password
            passField.status = BMField.Status.error
        }
        else if let pass = passField.text {
            let valid = AppModel.sharedManager().isValidPassword(pass)
            if !valid {
                passField.error = LocalizableStrings.current_password_error
                passField.status = BMField.Status.error
            }
            else{
                isUnlocked = true
                
                if event == .unlock {
                    if navigationController?.viewControllers.count == 1 {
                        dismiss(animated: true) {
                            
                        }
                    }
                    else{
                        navigationController?.popViewController(animated: true)
                    }
                }
                else{
                    let vc = CreateWalletPasswordViewController()
                    vc.hidesBottomBarWhenPushed = true
                    if var viewControllers = self.navigationController?.viewControllers {
                        viewControllers[viewControllers.count-1] = vc
                        self.navigationController?.setViewControllers(viewControllers, animated: true)
                    }
                }
            }
        }
    }
}

// MARK: TextField Actions
extension UnlockPasswordViewController : UITextFieldDelegate {
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        
        return true
    }  
}
