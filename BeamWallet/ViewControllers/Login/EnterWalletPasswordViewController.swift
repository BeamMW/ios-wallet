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

    override func viewDidLoad() {
        super.viewDidLoad()
        
        if Device.screenType == .iPhones_5 {
            mainStack?.spacing = 60
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        AppModel.sharedManager().cancelForgotPassword()
    }
    
    //MARK: IBAction
    
    @IBAction func onLogin(sender :UIButton) {
        AppModel.sharedManager().isRestoreFlow = false;

        if passField.text?.isEmpty ?? true {
            errorLabel.text = "Password should not be empty"
            passField.status = BMField.Status.error
        }
        else if let pass = passField.text {
            let appModel = AppModel.sharedManager()
            let valid = appModel.canOpenWallet(pass)
            if !valid {
                errorLabel.text = "Incorrect password"
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
    
    @IBAction func onForgotPassword(sender :UIButton) {
        if AppModel.sharedManager().canRestoreWallet() {
            let alertController = UIAlertController(title: "Forgot password", message: "Only your funds can be fully restored from the blockchain. The transaction history is stored locally and is encrypted with your password, hence it can't be restored.\n\nThat's the final version until the future validation and process.", preferredStyle: .alert)

            let NoAction = UIAlertAction(title: "Cancel", style: .default) { (action) in
            }
            alertController.addAction(NoAction)
            
            let OKAction = UIAlertAction(title: "Restore wallet", style: .cancel) { (action) in
                AppModel.sharedManager().isRestoreFlow = true;
                AppModel.sharedManager().startForgotPassword()
                
                let vc = InputPhraseViewController()
                self.pushViewController(vc: vc)
            }
            alertController.addAction(OKAction)
            
            self.present(alertController, animated: true, completion: nil)
        }
        else{
            self.alert(title: "Not enough storage", message: "To restore the wallet on the phone should be at least 200 MB of free space") { (_ ) in
                
            }
        }
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
