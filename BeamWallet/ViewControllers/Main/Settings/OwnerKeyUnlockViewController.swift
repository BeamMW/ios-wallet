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
    @IBOutlet private var titleLabel: UILabel!
    @IBOutlet private var passField: BMField!
    @IBOutlet private var mainStack: UIStackView!
    @IBOutlet private var touchIdButton: UIButton!
    @IBOutlet private var nextButtonView: UIView!
    
    override var isUppercasedTitle: Bool {
        get {
            return true
        }
        set {
            super.isUppercasedTitle = true
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setGradientTopBar(mainColor: UIColor.main.peacockBlue, addedStatusView: false)
        
        title = Localizable.shared.strings.show_owner_key
                
        if BiometricAuthorization.shared.canAuthenticate(), Settings.sharedManager().isEnableBiometric {
            nextButtonView.isHidden = true
            passField.isHidden = true
            touchIdButton.isHidden = false
            
            if BiometricAuthorization.shared.faceIDAvailable() {
                touchIdButton.setImage(IconFaceId(), for: .normal)
                titleLabel.text = Localizable.shared.strings.use_face_id
            }
            else {
                titleLabel.text = Localizable.shared.strings.use_touch_id
            }
        }
        else {
            titleLabel.text = Localizable.shared.strings.enter_your_password
        }
        
        hideKeyboardWhenTappedAround()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        if BiometricAuthorization.shared.canAuthenticate(), Settings.sharedManager().isEnableBiometric {
            biometricAuthorization()
        }
    }
    
    private func biometricAuthorization() {
        view.endEditing(true)
        
        if BiometricAuthorization.shared.canAuthenticate() {
            BiometricAuthorization.shared.authenticateWithBioMetrics(success: {
                self.titleLabel.text = Localizable.shared.strings.enter_your_password
                self.nextButtonView.isHidden = false
                self.passField.isHidden = false
                self.touchIdButton.isHidden = true
            }, failure: {}, retry: {}, reasonText: Localizable.shared.strings.touch_id_ownerkey_verefication)
        }
    }
    
    @IBAction func onBio(sender: UIButton) {
        biometricAuthorization()
    }
    
    @IBAction func onLogin(sender: UIButton) {
        if passField.text?.isEmpty ?? true {
            passField.error = Localizable.shared.strings.empty_password
            passField.status = BMField.Status.error
        }
        else if let pass = passField.text {
            let valid = AppModel.sharedManager().isValidPassword(pass)
            if !valid {
                passField.error = Localizable.shared.strings.incorrect_password
                passField.status = BMField.Status.error
            }
            else {
                view.endEditing(true)
                SVProgressHUD.show()
                AppModel.sharedManager().exportOwnerKey(pass) { key in
                    SVProgressHUD.dismiss()
                    let vc = OwnerKeyViewController()
                    vc.ownerKey = key
                    vc.hidesBottomBarWhenPushed = true
                    if var viewControllers = self.navigationController?.viewControllers {
                        viewControllers[viewControllers.count - 1] = vc
                        self.navigationController?.setViewControllers(viewControllers, animated: true)
                    }
                }
            }
        }
    }
}

// MARK: TextField Actions

extension OwnerKeyUnlockViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        
        return true
    }
}
