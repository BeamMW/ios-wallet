//
// OwnerKeyUnlockViewController.swift
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

class OwnerKeyUnlockViewController: BaseViewController {

    @IBOutlet private weak var titleLabel: UILabel!
    @IBOutlet private weak var subTitleLabel: UILabel!
    @IBOutlet private weak var confirmLabel: UILabel!
    @IBOutlet private weak var passField: BMField!
    @IBOutlet private weak var mainStack: UIStackView!

    override func viewDidLoad() {
        super.viewDidLoad()

        topOffset?.constant = topOffset?.constant ?? 0 + 30
        
        title = LocalizableStrings.show_owner_key
        
        if BiometricAuthorization.shared.canAuthenticate() {
            if BiometricAuthorization.shared.faceIDAvailable() {
                titleLabel.text = LocalizableStrings.ownerkey_faceid_text
                subTitleLabel.text = LocalizableStrings.ownerkey_faceid_subtext
                confirmLabel.text = LocalizableStrings.ownerkey_faceid_confirm
            }
            else{
                titleLabel.text = LocalizableStrings.ownerkey_touchid_text
                subTitleLabel.text = LocalizableStrings.ownerkey_touchid_subtext
                confirmLabel.text = LocalizableStrings.ownerkey_touchid_confirm
            }
        }
        else{
            titleLabel.text = LocalizableStrings.ownerkey_text
            subTitleLabel.text = LocalizableStrings.ownerkey_subtext
        }
        
        hideKeyboardWhenTappedAround()
    }
    
    private func biometricAuthorization() {
        view.endEditing(true)
        
        if BiometricAuthorization.shared.canAuthenticate() {
            BiometricAuthorization.shared.authenticateWithBioMetrics(success: {
                if let pass = KeychainManager.getPassword() {
                    SVProgressHUD.show()
                    AppModel.sharedManager().exportOwnerKey(pass) { (key) in
                        SVProgressHUD.dismiss()
                        let vc = OwnerKeyViewController()
                        vc.ownerKey = key
                        vc.hidesBottomBarWhenPushed = true
                        if var viewControllers = self.navigationController?.viewControllers {
                            viewControllers[viewControllers.count-1] = vc
                            self.navigationController?.setViewControllers(viewControllers, animated: true)
                        }
                    }
                }
            }, failure: {
                self.confirmLabel.isHidden = false
            }, retry: {
                self.confirmLabel.isHidden = false
            }, reasonText: LocalizableStrings.touch_id_ownerkey_verefication)
        }
        else{
            if let pass = passField.text {
                SVProgressHUD.show()
                AppModel.sharedManager().exportOwnerKey(pass) { (key) in
                    SVProgressHUD.dismiss()
                    let vc = OwnerKeyViewController()
                    vc.ownerKey = key
                    vc.hidesBottomBarWhenPushed = true
                    if var viewControllers = self.navigationController?.viewControllers {
                        viewControllers[viewControllers.count-1] = vc
                        self.navigationController?.setViewControllers(viewControllers, animated: true)
                    }
                }
            }
        }
    }
    
    @IBAction func onLogin(sender :UIButton) {
        self.confirmLabel.isHidden = true

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
                biometricAuthorization()
            }
        }
    }
}

// MARK: TextField Actions
extension OwnerKeyUnlockViewController : UITextFieldDelegate {
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
                
        return true
    }
}
