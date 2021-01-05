//
// TrustedNodeViewController.swift
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

class TrustedNodeViewController: BMInputViewController {
    enum EventType {
        case restore
        case change
    }
    
    public var completion: ((Bool) -> Void)?
    
    private var isPresented = false
    private var timer = Timer()
    private var timeoutTimer:Timer?
    private var event: EventType!
    private var isConnected = false

    private var oldAddress: String!
        
    init(event: EventType) {
        super.init(nibName: "BMInputViewController", bundle: nil)
        
        self.event = event
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError(Localizable.shared.strings.fatalInitCoderError)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        titleLabel.text = Localizable.shared.strings.enter_trusted_node
        
        inputField.placeholder = Localizable.shared.strings.ip_port
        inputField.placeHolderColor = UIColor.white.withAlphaComponent(0.2)
        inputField.delegate = self
        
        switch event {
        case .change:
            oldAddress = Settings.sharedManager().nodeAddress
            
            inputField.text = oldAddress
            
            title = Localizable.shared.strings.node_address
           
            nextButton.setTitle(Localizable.shared.strings.save, for: .normal)
            nextButton.setImage(IconSaveDone(), for: .normal)
        case .restore:
            AppModel.sharedManager().addDelegate(self)
            
            nextButton.setTitle(Localizable.shared.strings.next, for: .normal)
            nextButton.setImage(IconNextBlue(), for: .normal)
          
            if let base = self.navigationController as? BaseNavigationController {
                base.enableSwipeToDismiss = false
            }
            
            title = Localizable.shared.strings.restore_wallet_title
        case .none:
            break
        }
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        
        if isMovingFromParent, event == .restore {
            timer.invalidate()
            
            AppModel.sharedManager().removeDelegate(self)
        }
    }
    
    override func onNext() {
        view.endEditing(true)
        
        switch event {
        case .change:
            changeNode()
        case .restore:
            setNode()
        case .none:
            break
        }
    }
    
    private func setNode() {
        timer.invalidate()
        
        if !AppModel.sharedManager().isInternetAvailable {
            alert(title: Localizable.shared.strings.error, message: Localizable.shared.strings.no_internet) { _ in
            }
        }
        else if let fullAddress = inputField.text, let password = KeychainManager.getPassword() {
            if AppModel.sharedManager().isValidNodeAddress(fullAddress) && !fullAddress.isEmpty {
                SVProgressHUD.show()
                
                AppModel.sharedManager().resetOnlyWallet()
                
                Settings.sharedManager().connectToRandomNode = false
                Settings.sharedManager().nodeAddress = fullAddress
                
                let opened = AppModel.sharedManager().openWallet(password)
                if !opened {
                    alert(title: Localizable.shared.strings.error, message: Localizable.shared.strings.wallet_not_opened) { _ in
                        self.navigationController?.popToRootViewController(animated: true)
                    }
                }
                else {
                    timer.invalidate()
                    timer = Timer.scheduledTimer(timeInterval: 5, target: self, selector: #selector(timerAction), userInfo: nil, repeats: false)
                    
                    AppModel.sharedManager().getNetworkStatus()
                }
            }
            else {
                alert(title: Localizable.shared.strings.invalid_address_title, message: Localizable.shared.strings.invalid_address_text, handler: nil)
            }
        }
    }
    
    private func changeNode() {
        if let fullAddress = inputField.text {
            if AppModel.sharedManager().isValidNodeAddress(fullAddress) {
                if fullAddress != oldAddress {
                    Settings.sharedManager().nodeAddress = fullAddress
                    
                    AppModel.sharedManager().changeNodeAddress()
                    
                    completion?(true)
                    
                    back()
                }
                else {
                    completion?(true)
                    
                    back()
                }
            }
            else {
                errorLabel.text = Localizable.shared.strings.invalid_address_text
                errorLabel.isHidden = false
            }
        }
    }
    
    private func openMainPage() {
        if KeychainManager.getPassword() != nil {
            AppModel.sharedManager().stopChangeWallet()
            AppModel.sharedManager().isRestoreFlow = false
            AppModel.sharedManager().isOwnNode = true
        }

        let mainVC = BaseNavigationController.navigationController(rootViewController: WalletViewController())
        let menuViewController = LeftMenuViewController()

        let sideMenuController = LGSideMenuController(rootViewController: mainVC,
                                                      leftViewController: menuViewController,
                                                      rightViewController: nil)

        sideMenuController.leftViewWidth = UIScreen.main.bounds.size.width - 60
        sideMenuController.leftViewPresentationStyle = LGSideMenuPresentationStyle.slideAbove
        sideMenuController.rootViewLayerShadowRadius = 0
        sideMenuController.rootViewLayerShadowColor = UIColor.clear
        sideMenuController.leftViewLayerShadowRadius = 0
        sideMenuController.rootViewCoverAlphaForLeftView = 0.5
        sideMenuController.rootViewCoverAlphaForRightView = 0.5
        sideMenuController.leftViewCoverAlpha = 0.5
        sideMenuController.rightViewCoverAlpha = 0.5
        sideMenuController.modalTransitionStyle = .crossDissolve

        navigationController?.setViewControllers([sideMenuController], animated: true)
    }
}

extension TrustedNodeViewController: UITextFieldDelegate {
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

extension TrustedNodeViewController: WalletModelDelegate {
    
    func onWalletStatusChange(_ status: BMWalletStatus) {
        if (status.available > 0 || status.maxPrivacy > 0 || status.maturing > 0) && event == .restore && !Settings.sharedManager().connectToRandomNode {
            DispatchQueue.main.async { [weak self] in
                guard let strongSelf = self else { return }
                strongSelf.timeout()
            }
        }
    }
    
    @objc private func timeout() {
        SVProgressHUD.dismiss()
        if !isPresented && !Settings.sharedManager().connectToRandomNode {
            isPresented = true
            timer.invalidate()
            timeoutTimer?.invalidate()
            openMainPage()
        }
    }
    
    @objc private func timerAction() {
        
        let connected = AppModel.sharedManager().isConnected
        isConnected = connected
        
        if connected {
            errorLabel.isHidden = true
            inputField.status = .normal
            
            if !isPresented {
                DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                    AppModel.sharedManager().getWalletStatus()
                }
                timer.invalidate()
                
                if timeoutTimer == nil {
                    timeoutTimer = Timer.scheduledTimer(timeInterval: 5, target: self, selector: #selector(timeout), userInfo: nil, repeats: false)
                }
       
            }
            else {
                SVProgressHUD.dismiss()
            }
        }
        else {
            SVProgressHUD.dismiss()

            inputField.status = .error
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
