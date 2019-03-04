//
//  CreateWalletPasswordViewController.swift
//  BeamWallet
//
//  Created by Denis on 3/1/19.
//  Copyright © 2019 Denis. All rights reserved.
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
        
        if Device.screenType == .iPhones_5_5s_5c_SE {
            mainStack?.spacing = 50
        }
        
        passField.addTarget(self, action: #selector(textFieldDidChange(_:)), for: .editingChanged)
        confirmPassField.addTarget(self, action: #selector(textFieldDidChange(_:)), for: .editingChanged)
    }
    
// MARK: IBAction
    @IBAction func onNext(sender :UIButton) {
        let pass = passField.text ?? ""
        let confirmPass = confirmPassField.text ?? ""
        
        if !pass.isEmpty {
            if pass == confirmPass {
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
        if textField == confirmPassField && Device.screenType == .iPhones_5_5s_5c_SE {
            UIView.animate(withDuration: 0.25) {
                var frame = self.navigationController?.view.frame
                frame?.origin.y = 0
                self.navigationController?.view.frame = frame ?? CGRect.zero
            }
        }
        return true
    }
    
    func textFieldShouldBeginEditing(_ textField: UITextField) -> Bool {
        if textField == confirmPassField && Device.screenType == .iPhones_5_5s_5c_SE {
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
