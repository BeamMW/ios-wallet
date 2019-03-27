//
//  CreateWalletPasswordViewController.swift
//  BeamWallet
//
// 3/1/19.
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
        
        self.title = "Password"
        
        if Device.isZoomed {
            stackY?.constant = 10
            mainStack?.spacing = 30
        }
        else if Device.screenType == .iPhones_5_5s_5c_SE {
            mainStack?.spacing = 50
        }
        
        passField.addTarget(self, action: #selector(textFieldDidChange(_:)), for: .editingChanged)
        confirmPassField.addTarget(self, action: #selector(textFieldDidChange(_:)), for: .editingChanged)
        
        let backButton = UIButton(type: .system)
        backButton.frame = CGRect(x: 0, y: 0, width: 40, height: 40)
        backButton.contentHorizontalAlignment = .left
        backButton.tintColor = UIColor.white
        backButton.setImage(UIImage.init(named: "iconBack"), for: .normal)
        backButton.addTarget(self, action: #selector(onBack), for: .touchUpInside)
        self.navigationItem.leftBarButtonItem = UIBarButtonItem(customView: backButton)
    }
    
// MARK: IBAction
    
    @objc private func onBack() {
        let alert = UIAlertController(title: "Return to seed phrase", message: "If you return to seed phrase, it would be changed and your local password won’t be saved.", preferredStyle: .alert)
        
        let ok = UIAlertAction(title: "Return", style: .default, handler: { action in
            let viewControllers = self.navigationController?.viewControllers
            let vc = viewControllers![(viewControllers?.count)!-3]
            self.navigationController?.popToViewController(vc, animated: true)
        })
        alert.addAction(UIAlertAction(title: "Cancel", style: .default, handler: nil))
        alert.addAction(ok)
        
        self.present(alert, animated: true)
    }
    
    @IBAction func onNext(sender :UIButton) {
        let pass = passField.text ?? ""
        let confirmPass = confirmPassField.text ?? ""
        
        if !pass.isEmpty {
            if pass == confirmPass {
                _ = KeychainManager.addPassword(password: pass)
                
                let vc = CreateWalletProgressViewController()
                    .withPassword(password: pass)
                    .withPhrase(phrase: phrase)
                pushViewController(vc: vc)
            }
            else{
                self.passConfirmLabel.text = "Passwords do not match"
            }
        }
        else{
            self.passConfirmLabel.text = "Please enter password"
        }
    }
}

// MARK: TextField Actions
extension CreateWalletPasswordViewController : UITextFieldDelegate {
    
    @objc func textFieldDidChange(_ textField: BMField) {
        let text = textField.text ?? ""
        
        if textField == passField {
            let state = PasswordTestManager.testPassword(password: text)
            
            switch state {
            case .none:
                passProgressView.currentStep = 0
                break;
            case .veryWeak:
                passProgressView.finishedStepColor = UIColor.main.red
                passProgressView.currentStep = 2
                break;
            case .weak:
                passProgressView.finishedStepColor = UIColor.main.maize
                passProgressView.currentStep = 3
                break;
            case .medium:
                passProgressView.finishedStepColor = UIColor.main.maize
                passProgressView.currentStep = 4
                break;
            case .strong:
                passProgressView.finishedStepColor = UIColor.main.brightTeal
                passProgressView.currentStep = 6
                break;
            case .veryStrong:
                passProgressView.finishedStepColor = UIColor.main.brightTeal
                passProgressView.currentStep = 6
                break;
            }
        }
        
        self.passConfirmLabel.text = ""
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        
        if textField == passField, textField.text?.isEmpty == false {
            confirmPassField.becomeFirstResponder()
        }
        
        return true
    }
    
    func textFieldShouldEndEditing(_ textField: UITextField) -> Bool {
        if textField == confirmPassField && (Device.screenType == .iPhones_5_5s_5c_SE || Device.isZoomed) {
            UIView.animate(withDuration: 0.25) {
                var frame = self.navigationController?.view.frame
                frame?.origin.y = 0
                self.navigationController?.view.frame = frame ?? CGRect.zero
            }
        }
        return true
    }
    
    func textFieldShouldBeginEditing(_ textField: UITextField) -> Bool {
        if textField == confirmPassField && (Device.screenType == .iPhones_5_5s_5c_SE || Device.isZoomed) {
            UIView.animate(withDuration: 0.25) {
                var frame = self.navigationController?.view.frame
                frame?.origin.y = -48
                self.navigationController?.view.frame = frame ?? CGRect.zero
            }
        }
        return true
    }
}

extension CreateWalletPasswordViewController {
    
    func withPhrase(phrase: String) -> Self {
        
        self.phrase = phrase
        
        return self
    }
}
