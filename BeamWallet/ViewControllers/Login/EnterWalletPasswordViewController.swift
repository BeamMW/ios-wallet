//
//  EnterWalletPasswordViewController.swift
//  BeamWallet
//
// 3/4/19.
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

    override func viewDidLoad() {
        super.viewDidLoad()
        
        if Device.screenType == .iPhones_5_5s_5c_SE {
            mainStack?.spacing = 60
        }
    }
    
    //MARK: IBAction
    
    @IBAction func onLogin(sender :UIButton) {
        if passField.text?.isEmpty ?? true {
            errorLabel.text = "password must not be empty"
            passField.lineColor = UIColor.main.red
            passField.textColor = UIColor.main.red
        }
        else if let pass = passField.text {
            let appModel = AppModel.sharedManager()
            let valid = appModel.canOpenWallet(pass)
            if !valid {
                errorLabel.text = "wrong password"
                passField.lineColor = UIColor.main.red
                passField.textColor = UIColor.main.red
            }
            else{
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
        
        errorLabel.text = ""
        passField.lineColor = UIColor.main.brightTeal
        passField.textColor = UIColor.white

        return true
    }
    
}
