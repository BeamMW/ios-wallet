//
// OpenWalletProgressViewController.swift
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

class OpenWalletProgressViewController: BaseViewController {
    
    @IBOutlet private weak var progressView: UIProgressView!
    @IBOutlet private weak var progressTitleLabel: UILabel!
    @IBOutlet private weak var progressValueLabel: UILabel!
    @IBOutlet private weak var restotingInfoLabel: UILabel!
    @IBOutlet private weak var cancelButton: UIButton!
    @IBOutlet private weak var errorLabel: UILabel!
    @IBOutlet private weak var versionLabel: UILabel!

    private var timeoutTimer:Timer?
    private var oldProgress:Int32 = 0
    
    private var password:String?
    private var phrase:String?
    private var isPresented = false
    private var start = Date.timeIntervalSinceReferenceDate;

    init(password:String, phrase:String?) {
        super.init(nibName: nil, bundle: nil)

        self.password = password
        self.phrase = phrase
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError(Localizable.shared.strings.fatalInitCoderError)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        removeLeftButton()
        
        if Settings.sharedManager().isDarkMode {
            cancelButton.setBackgroundColor(color: UIColor.main.marineThree, forState: .normal)
            cancelButton.setTitleColor(UIColor.white, for: .normal)
            cancelButton.setImage(IconCancelWhite(), for: .normal)
        }
        
        if phrase != nil {
            versionLabel.text = Localizable.shared.strings.version.replacingOccurrences(of: "App ", with: "") + " " + UIApplication.appVersion()
        }
        else{
            versionLabel.isHidden = true
        }
        
        let progressViewHeight: CGFloat = 4.0
        
        let transformScale = CGAffineTransform(scaleX: 1.0, y: progressViewHeight)
        progressView.transform = transformScale
        
        if AppModel.sharedManager().isRestoreFlow {
            progressTitleLabel.text = Localizable.shared.strings.restoring_wallet
            restotingInfoLabel.isHidden = false
            progressValueLabel.text = Localizable.shared.strings.restored + " 0%"
            progressValueLabel.isHidden = false
            cancelButton.isHidden = false
        }
        else if phrase == nil {
            timeoutTimer = Timer.scheduledTimer(timeInterval: 10.0, target: self, selector: #selector(onTimeOut), userInfo: nil, repeats: false)
            
            progressTitleLabel.text = Localizable.shared.strings.loading_wallet
            cancelButton.isHidden = true
        }

        if let base = self.navigationController as? BaseNavigationController {
            base.enableSwipeToDismiss = false
        }
        
        AppModel.sharedManager().addDelegate(self)

        startCreateWallet()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        timeoutTimer?.invalidate()
        
        if isMovingFromParent {
            AppModel.sharedManager().removeDelegate(self)
        }
        
        if AppModel.sharedManager().isRestoreFlow {
            RestoreManager.shared.cancelRestore()
            AppModel.sharedManager().isRestoreFlow = false
        }
    }
    
    private func openMainPage() {
        isPresented = true

        if phrase != nil {
            OnboardManager.shared.saveSeed(seed: phrase!)
        }

        if let pass = self.password {
            _ = KeychainManager.addPassword(password: pass)
        }

        timeoutTimer?.invalidate()
        
        AppModel.sharedManager().stopChangeWallet()

        AppModel.sharedManager().removeDelegate(self)
        
        AppModel.sharedManager().refreshAddresses()
        AppModel.sharedManager().getUTXO()

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
        
        BMLockScreen.shared.onTapEvent()
    }

    private func downloadFile() {
        self.progressValueLabel.text = Localizable.shared.strings.downloading + " " + "\(0)%"
        self.progressTitleLabel.text = Localizable.shared.strings.downloading_blockchain
        self.restotingInfoLabel.isHidden = true

        RestoreManager.shared.startRestore(completion: { (completed) in
            if completed {
                DispatchQueue.main.async {
                    self.errorLabel.isHidden = true
                    self.restoreCompleted()
                }
            }
        }) { (error, progress, time) in
            DispatchQueue.main.async {
                if let reason = error {
                    self.alert(title: Localizable.shared.strings.error, message: reason.localizedDescription) { (_ ) in
                        AppModel.sharedManager().isRestoreFlow = false
                        RestoreManager.shared.cancelRestore()
                        self.navigationController?.popToRootViewController(animated: true)
                    }
                }
                else if let percent = progress {
                    self.errorLabel.isHidden = true
                    self.progressView.progress = percent
                    
                    if let remaining = time {
                        self.progressValueLabel.text = Localizable.shared.strings.downloading + " " + "\(Int32(percent * 100))%" + "\n" + Localizable.shared.strings.estimted_time + " " + remaining
                    }
                    else{
                        self.progressValueLabel.text = Localizable.shared.strings.downloading + " " + "\(Int32(percent * 100))%"
                    }
                }
            }
        }
    }
    
    private func startCreateWallet() {
        
        if !AppModel.sharedManager().isInternetAvailable && AppModel.sharedManager().isRestoreFlow {
            self.alert(title: Localizable.shared.strings.error, message: Localizable.shared.strings.no_internet) { (_ ) in
                AppModel.sharedManager().resetWallet(false)
                self.back()
            }
        }
        else{
            if let phrase = phrase, AppModel.sharedManager().isRestoreFlow
            {
                let created = AppModel.sharedManager().createWallet(phrase, pass: password!)
                if(!created)
                {
                    self.alert(title: Localizable.shared.strings.error, message: Localizable.shared.strings.wallet_not_created) { (_ ) in
                        if AppModel.sharedManager().isInternetAvailable {
                            self.navigationController?.popToRootViewController(animated: true)
                        }
                        else{
                            DispatchQueue.main.async {
                                self.back()
                            }
                        }
                    }
                }
                else{
                    self.downloadFile()
                }
            }
            else if let phrase = phrase {
                let created = AppModel.sharedManager().createWallet(phrase, pass: password!)
                if(!created)
                {
                    self.alert(title: Localizable.shared.strings.error, message: Localizable.shared.strings.wallet_not_created) { (_ ) in
                        if AppModel.sharedManager().isInternetAvailable {
                            self.navigationController?.popToRootViewController(animated: true)
                        }
                        else{
                            DispatchQueue.main.async {
                                self.back()
                            }
                        }
                    }
                }
            }
            else{
                if AppModel.sharedManager().isRestoreFlow {
                    self.downloadFile()
                }
                else{
                    let opened = AppModel.sharedManager().openWallet(password!)
                    if(!opened)
                    {
                        self.alert(title: Localizable.shared.strings.error, message: Localizable.shared.strings.wallet_not_opened) { (_ ) in
                            self.navigationController?.popToRootViewController(animated: true)
                        }
                    }
                    else if (!AppModel.sharedManager().isInternetAvailable)
                    {
                        self.openMainPage()
                    }
                }
            }
        }
    }
    
    private func restoreCompleted() {
        DispatchQueue.main.async { [weak self] in
            guard let strongSelf = self else { return }
            strongSelf.progressTitleLabel.text = Localizable.shared.strings.restoring_wallet
            strongSelf.restotingInfoLabel.text = Localizable.shared.strings.restor_wallet_warning + "\n\n" + Localizable.shared.strings.restor_wallet_info
            strongSelf.restotingInfoLabel.isHidden = false
            strongSelf.progressView.progress = 0
            strongSelf.progressValueLabel.text = Localizable.shared.strings.restored + " \(0)%"
        }
        
        DispatchQueue.global(qos: .background).async {
            AppModel.sharedManager().restore(RestoreManager.shared.filePath.path)
        }
    }

    private func openNodeController() {
        let vc = TrustedNodeViewController(event: .change)
        vc.completion = { [weak self]
            obj in
            
            if obj == true {
                AppModel.sharedManager().isConnecting = false
                
                self?.timeoutTimer = Timer.scheduledTimer(timeInterval: 10.0, target: self as Any, selector: #selector(self?.onTimeOut), userInfo: nil, repeats: false)
                
                self?.startCreateWallet()
            }
            else{
                self?.navigationController?.popToRootViewController(animated: true)
            }
        }
        vc.hidesBottomBarWhenPushed = true
        self.pushViewController(vc: vc)
    }

// MARK: IBAction
    
    @IBAction func onCancel(sender :UIButton) {
        if AppModel.sharedManager().isRestoreFlow {
            RestoreManager.shared.cancelRestore()
            AppModel.sharedManager().isRestoreFlow = false
        }
        
        let appModel = AppModel.sharedManager()
        appModel.resetWallet(true)
        
        navigationController?.popToRootViewController(animated: true)
    }
    
    @objc private func onTimeOut() {
        if Settings.sharedManager().isChangedNode() {
            if !self.isPresented {
                self.isPresented = true
                
                self.openMainPage()
            }
        }
    }
}

extension OpenWalletProgressViewController : WalletModelDelegate {
    
    func onNetwotkStatusChange(_ connected: Bool) {
        DispatchQueue.main.async { [weak self] in
            guard let strongSelf = self else { return }
            
            if connected && !strongSelf.isPresented && !AppModel.sharedManager().isRestoreFlow {
                strongSelf.isPresented = true
                strongSelf.progressView.progress = 1
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    strongSelf.openMainPage()
                }
            }
        }
    }
    
    func onNoInternetConnection() {
        DispatchQueue.main.async { [weak self] in
            guard let strongSelf = self else { return }

            if AppModel.sharedManager().isRestoreFlow {
                strongSelf.errorLabel.isHidden = false
                strongSelf.errorLabel.text = Localizable.shared.strings.no_internet
            }
        }
    }
    
    func onRecoveryProgressUpdated(_ done: Int32, total: Int32, time: Int32) {
        DispatchQueue.main.async { [weak self] in
            guard let strongSelf = self else { return }
            
            strongSelf.errorLabel.isHidden = true

            strongSelf.progressView.progress = Float(Float(done)/Float(total))
            
            let progress_100 = Int32(strongSelf.progressView.progress * 100)

            if progress_100 != strongSelf.oldProgress {
                strongSelf.oldProgress = progress_100
                
                if time > 0 {
                    let asDouble = Double(time)
                    strongSelf.progressValueLabel.text = Localizable.shared.strings.restored + " " + "\(progress_100)%" + "\n" + Localizable.shared.strings.estimted_time + " " + asDouble.asTime(style: .abbreviated)
                }
                else{
                    strongSelf.progressValueLabel.text = Localizable.shared.strings.restored + " \(progress_100)%"
                }
            }
      
            
            if done == total {
                AppModel.sharedManager().isRestoreFlow = false
                RestoreManager.shared.cancelRestore()
                
                if !AppModel.sharedManager().isInternetAvailable {
                    strongSelf.alert(title: Localizable.shared.strings.error, message: Localizable.shared.strings.no_internet) { (_ ) in
                        
                        AppModel.sharedManager().resetWallet(false)
                        
                        strongSelf.navigationController?.setViewControllers( [EnterWalletPasswordViewController()], animated: true)
                    }
                }
                else{
                    strongSelf.startCreateWallet()
                }
            }
        }
    }
    
    func onSyncProgressUpdated(_ done: Int32, total: Int32) {
        DispatchQueue.main.async { [weak self] in
            guard let strongSelf = self else { return }

            strongSelf.errorLabel.isHidden = true

            if total == done && !strongSelf.isPresented && !AppModel.sharedManager().isRestoreFlow {
//
            }
            else{
                strongSelf.progressView.progress = Float(Float(done)/Float(total))
            }
        }
    }
    
    func onWalletError(_ _error: Error) {
        DispatchQueue.main.async {
            [weak self] in
            guard let strongSelf = self else { return }
            
            let error = _error as NSError
            
            if error.code == 2 && Settings.sharedManager().isChangedNode() {
                if !strongSelf.isPresented {
                    strongSelf.isPresented = true
                    strongSelf.openMainPage()
                }
            }
            else if error.code == 1 {
                if !strongSelf.isPresented {
                    strongSelf.isPresented = true
                    strongSelf.openMainPage()
                }
//                if strongSelf.navigationController?.viewControllers.last is OpenWalletProgressViewController {
//                    strongSelf.confirmAlert(title: Localizable.shared.strings.incompatible_node_title, message: Localizable.shared.strings.incompatible_node_info, cancelTitle: Localizable.shared.strings.cancel, confirmTitle: Localizable.shared.strings.change_settings, cancelHandler: { (_ ) in
//
//                        AppModel.sharedManager().resetWallet(false)
//                        strongSelf.back()
//                    }, confirmHandler: { (_ ) in
//
//                        strongSelf.openNodeController()
//                    })
//                }
            }
            else if error.code == 4 {
                if !strongSelf.isPresented {
                    strongSelf.isPresented = true
                    strongSelf.openMainPage()
                }
            }
            else if !strongSelf.isPresented {
                if let controllers = strongSelf.navigationController?.viewControllers {
                    for vc in controllers {
                        if vc is TrustedNodeViewController {
                            return
                        }
                    }
                }
                strongSelf.alert(title: Localizable.shared.strings.error, message: error.localizedDescription, handler: { (_ ) in
                    if AppModel.sharedManager().isRestoreFlow {
                        AppModel.sharedManager().resetWallet(true)
                        strongSelf.navigationController?.popToRootViewController(animated: true)
                    }
                    else{
                        strongSelf.back()
                    }
                })
            }
        }
    }
}
