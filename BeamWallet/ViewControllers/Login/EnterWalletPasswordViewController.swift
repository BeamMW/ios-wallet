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
    public var completion: (() -> Void)?
    
    private var isRequestedAuthorization = false
    
    @IBOutlet private var passField: BMField!
    @IBOutlet private var touchIdButton: UIButton!
    @IBOutlet private var loginLabel: UILabel!
    @IBOutlet private var restoreButton: UIButton!
    @IBOutlet private var stackView: UIStackView!
    @IBOutlet private var topSpace: NSLayoutConstraint!
    @IBOutlet private var versionLabel: UILabel!
    
    init(isNeedRequestedAuthorization: Bool = true) {
        super.init(nibName: nil, bundle: nil)
        
        self.isRequestedAuthorization = !isNeedRequestedAuthorization
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError(Localizable.shared.strings.fatalInitCoderError)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if Device.isLarge {
            stackView.spacing = 60
        }
        else if Device.isXDevice {
            stackView.spacing = 40
            topSpace.constant = -50
        }
        
        if !BiometricAuthorization.shared.canAuthenticate() || !Settings.sharedManager().isEnableBiometric {
            touchIdButton.isHidden = true
        }
        else {
            if BiometricAuthorization.shared.faceIDAvailable() {
                touchIdButton.setImage(IconFaceId(), for: .normal)
            }
            
            let loginText = BiometricAuthorization.shared.faceIDAvailable() ? Localizable.shared.strings.ownerkey_faceid_text : Localizable.shared.strings.ownerkey_touchid_text
            loginLabel.text = loginText.replacingOccurrences(of: Localizable.shared.strings.and.lowercased(), with: Localizable.shared.strings.or.lowercased())
        }
        
        NotificationCenter.default.addObserver(self, selector: #selector(didBecomeActive), name: UIApplication.didBecomeActiveNotification, object: nil)
        
        if AppModel.sharedManager().isLoggedin {
            restoreButton.isHidden = true
        }
        else {
            restoreButton.titleLabel?.numberOfLines = 2
            restoreButton.setTitle(Localizable.shared.strings.restore_create_title, for: .normal)
            restoreButton.titleLabel?.textAlignment = .center
        }
        
        versionLabel.text = Localizable.shared.strings.version.replacingOccurrences(of: "App ", with: "") + " " + UIApplication.appVersion()

    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if !AppModel.sharedManager().isLoggedin {
            AppModel.sharedManager().checkRecoveryWallet()
            
            if (presentedViewController as? UIAlertController) == nil {
                if isRequestedAuthorization == false, TGBotManager.sharedManager.isNeedLinking() == false, UIApplication.shared.applicationState == .active, AppDelegate.isCrashed() == false {
                    isRequestedAuthorization = true
                    biometricAuthorization()
                }
            }
        }
        else if AppModel.sharedManager().isLoggedin, !isRequestedAuthorization, UIApplication.shared.applicationState == .active {
            isRequestedAuthorization = true
            biometricAuthorization()
        }
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        
        NotificationCenter.default.removeObserver(self, name: UIApplication.didBecomeActiveNotification, object: nil)
    }
    
    @objc private func didBecomeActive() {
        if UIApplication.shared.applicationState == .active {
            viewWillAppear(false)
        }
    }
    
    public func biometricAuthorization() {
        if BiometricAuthorization.shared.canAuthenticate(), Settings.sharedManager().isEnableBiometric {
            BiometricAuthorization.shared.authenticateWithBioMetrics(success: {
                if let password = KeychainManager.getPassword() {
                    self.passField.text = password
                    self.onLogin(sender: UIButton())
                }
                
            }, failure: {
                self.touchIdButton.tintColor = UIColor.white
            }, retry: {
                self.touchIdButton.tintColor = UIColor.white
            })
        }
    }
    
    // MARK: IBAction
    
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
            if AppModel.sharedManager().isLoggedin {
                let valid = AppModel.sharedManager().isValidPassword(pass)
                if !valid {
                    passField.error = Localizable.shared.strings.incorrect_password
                    passField.status = BMField.Status.error
                }
                else {
                    if navigationController?.viewControllers.count == 1 {
                        dismiss(animated: true) {}
                    }
                    else {
                        back()
                    }
                    
                    completion?()
                }
            }
            else {
                let appModel = AppModel.sharedManager()
                let valid = appModel.canOpenWallet(pass)
                if !valid {
                    passField.error = Localizable.shared.strings.incorrect_password
                    passField.status = BMField.Status.error
                }
                else {
                    _ = KeychainManager.addPassword(password: pass)
                    
                    let vc = OpenWalletProgressViewController(password: pass, phrase: nil)
                    pushViewController(vc: vc)
                }
            }
        }
    }
    
    @IBAction func onChangeWallet(sender: UIButton) {
        confirmAlert(title: Localizable.shared.strings.restore_create_title, message: Localizable.shared.strings.restore_create_text, cancelTitle: Localizable.shared.strings.cancel, confirmTitle: Localizable.shared.strings.proceed, cancelHandler: { _ in
            
        }) { _ in
            AppModel.sharedManager().startChangeWallet()
            self.pushViewController(vc: WellcomeViewController())
        }
    }
    
    @IBAction func onExport(sender: UIButton) {
        let path = Settings.sharedManager().walletStoragePath()
        let url = URL(fileURLWithPath: path)
        
        let act = ShareLogActivity()
        act.zipUrl = url
        
        let vc = UIActivityViewController(activityItems: [url], applicationActivities: [act])
        vc.setValue("database", forKey: "subject")
        
        vc.excludedActivityTypes = [UIActivity.ActivityType.postToFacebook, UIActivity.ActivityType.assignToContact, UIActivity.ActivityType.copyToPasteboard, UIActivity.ActivityType.print, UIActivity.ActivityType.openInIBooks]
        
        present(vc, animated: true)
    }
}

// MARK: TextField Actions

extension EnterWalletPasswordViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
}
