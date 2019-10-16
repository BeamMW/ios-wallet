//
// RestoreNodeViewController.swift
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

class RestoreNodeViewController: BaseViewController {

    private var isPresented = false
    var timer = Timer()

    @IBOutlet private weak var nodeAddressField:BMField!
    @IBOutlet private weak var errorLabel: UILabel!

    override var isUppercasedTitle: Bool {
        get{
            return true
        }
        set{
            super.isUppercasedTitle = true
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setGradientTopBar(mainColor: UIColor.main.peacockBlue, addedStatusView: false)

        title = Localizable.shared.strings.restore_wallet_title
        
        hideKeyboardWhenTappedAround()
        
        if let base = self.navigationController as? BaseNavigationController {
            base.enableSwipeToDismiss = false
        }
        
        AppModel.sharedManager().addDelegate(self)
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        
        if isMovingFromParent {
            timer.invalidate()

            AppModel.sharedManager().removeDelegate(self)
        }
    }
    
    @IBAction func onNext(sender :UIButton) {
        view.endEditing(true)
        
        timer.invalidate()

        if !AppModel.sharedManager().isInternetAvailable {
            self.alert(title: Localizable.shared.strings.error, message: Localizable.shared.strings.no_internet) { (_ ) in
            }
        }
        else if let fullAddress = nodeAddressField.text, let password = KeychainManager.getPassword()  {
            if AppModel.sharedManager().isValidNodeAddress(fullAddress) {
                SVProgressHUD.show()

                AppModel.sharedManager().resetOnlyWallet()

                Settings.sharedManager().nodeAddress = fullAddress
                
                let opened = AppModel.sharedManager().openWallet(password)
                if(!opened) {
                    self.alert(title: Localizable.shared.strings.error, message: Localizable.shared.strings.wallet_not_opened) { (_ ) in
                        self.navigationController?.popToRootViewController(animated: true)
                    }
                }
                else{
                    AppModel.sharedManager().getNetworkStatus()
                }
            }
            else{
                self.alert(title: Localizable.shared.strings.invalid_address_title, message: Localizable.shared.strings.invalid_address_text, handler: nil)
            }
        }
    }
    
    private func openMainPage() {
        AppModel.sharedManager().removeDelegate(self)
        AppModel.sharedManager().isRestoreFlow = false
        AppModel.sharedManager().isChangeWallet = false

        AppModel.sharedManager().refreshAddresses()
        
        let mainVC = BaseNavigationController.navigationController(rootViewController: WalletViewController())
        let menuViewController = LeftMenuViewController()
        
        let sideMenuController = LGSideMenuController(rootViewController: mainVC,
                                                      leftViewController: menuViewController,
                                                      rightViewController: nil)
        
        sideMenuController.leftViewWidth = UIScreen.main.bounds.size.width - 60;
        sideMenuController.leftViewPresentationStyle = .slideAbove;
        sideMenuController.rootViewLayerShadowRadius = 0
        sideMenuController.rootViewLayerShadowColor = UIColor.clear
        sideMenuController.leftViewLayerShadowRadius = 0
        sideMenuController.rootViewCoverAlphaForLeftView = 0.5
        sideMenuController.rootViewCoverAlphaForRightView = 0.5
        sideMenuController.leftViewCoverAlpha = 0.5
        sideMenuController.rightViewCoverAlpha = 0.5
        sideMenuController.modalTransitionStyle = .crossDissolve
        
        self.navigationController?.setViewControllers([sideMenuController], animated: true)
    }
}

extension RestoreNodeViewController : UITextFieldDelegate {
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        
        return true
    }
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        
        errorLabel.isHidden = true
        timer.invalidate()

        let textFieldText: NSString = (textField.text ?? "") as NSString
        
        let txtAfterUpdate = textFieldText.replacingCharacters(in: range, with: string)
        
        if txtAfterUpdate.countInstances(of: ":") > 1 {
            return false
        }
        else if txtAfterUpdate.contains(":") {
            let splited = txtAfterUpdate.split(separator: ":")
            if splited.count == 2 {
                let port = String(splited[1])
                let portRange = (txtAfterUpdate as NSString).range(of: String(port))
                
                if port.isEmpty == false && string == ":" {
                    return false
                }
                else if range.intersection(portRange) != nil || port.lengthOfBytes(using: .utf8) == 1 {
                    return (port.isNumeric() && port.isValidPort())
                }
            }
        }
        
        return true
    }
    
    func textFieldShouldClear(_ textField: UITextField) -> Bool {
        errorLabel.isHidden = true
        timer.invalidate()
        
        return true
    }
}

extension RestoreNodeViewController : WalletModelDelegate {
    
    @objc private func timerAction() {
        SVProgressHUD.dismiss()
        
        let connected = AppModel.sharedManager().isConnected
        
        if connected {
            errorLabel.isHidden = true
            nodeAddressField.status = .normal
            
            if !isPresented {
                isPresented = true
                openMainPage()
            }
        }
        else{
            nodeAddressField.status = .error
            errorLabel.isHidden = false
        }
    }
    
    func onNetwotkStatusChange(_ connected: Bool) {
        DispatchQueue.main.async { [weak self] in
            guard let strongSelf = self else { return }
            
            strongSelf.timer.invalidate()
            strongSelf.timer = Timer.scheduledTimer(timeInterval: 1, target: strongSelf, selector: #selector(strongSelf.timerAction), userInfo: nil, repeats: false)
        }
    }
}
