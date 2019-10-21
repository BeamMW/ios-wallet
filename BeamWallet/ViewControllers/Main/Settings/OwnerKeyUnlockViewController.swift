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

class OwnerKeyUnlockViewController: BMInputViewController {
    
    private var touchIdButton = UIButton(type: .system)
    
    init() {
        super.init(nibName: "BMInputViewController", bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError(Localizable.shared.strings.fatalInitCoderError)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        touchIdButton.isHidden = true
        touchIdButton.tintColor = UIColor.white
        touchIdButton.setImage(IconTouchid(), for: .normal)
        stackView.addArrangedSubview(touchIdButton)
        
        title = Localizable.shared.strings.show_owner_key
                
        inputField.placeholder = Localizable.shared.strings.enter_password
        inputField.placeHolderColor = UIColor.white.withAlphaComponent(0.2)
        inputField.delegate = self
        
        if BiometricAuthorization.shared.canAuthenticate(), Settings.sharedManager().isEnableBiometric {
            nextButton.isHidden = true
            inputField.isHidden = true
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
                self.nextButton.isHidden = false
                self.inputField.isHidden = false
                self.touchIdButton.isHidden = true
            }, failure: {}, retry: {}, reasonText: Localizable.shared.strings.touch_id_ownerkey_verefication)
        }
    }
    
    @IBAction func onBio(sender: UIButton) {
        biometricAuthorization()
    }
    
    override func onNext() {
        if inputField.text?.isEmpty ?? true {
            inputField.error = Localizable.shared.strings.empty_password
            inputField.status = BMField.Status.error
        }
        else if let pass = inputField.text {
            let valid = AppModel.sharedManager().isValidPassword(pass)
            if !valid {
                inputField.error = Localizable.shared.strings.incorrect_password
                inputField.status = BMField.Status.error
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
