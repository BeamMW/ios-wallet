//
// CreateWalletProgressViewController.swift
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
import Loaf

class CreateWalletProgressViewController: BaseViewController {

    @IBOutlet private weak var progressView: UIProgressView!
    @IBOutlet private weak var progressTitleLabel: UILabel!
    @IBOutlet private weak var progressValueLabel: UILabel!
    @IBOutlet private weak var restotingInfoLabel: UILabel!
    @IBOutlet private weak var restotingWarningLabel: UILabel!
    @IBOutlet private weak var cancelButton: UIButton!
    @IBOutlet private weak var logoYOffset: NSLayoutConstraint!
    @IBOutlet private weak var stackYOffset: NSLayoutConstraint!

    private var timeoutTimer = Timer()
    
    private var password:String!
    private var phrase:String?
    private var isPresented = false
    private var start = Date.timeIntervalSinceReferenceDate;

    override func viewDidLoad() {
        super.viewDidLoad()

        navigationItem.hidesBackButton = true

        let progressViewHeight: CGFloat = 4.0
        
        let transformScale = CGAffineTransform(scaleX: 1.0, y: progressViewHeight)
        progressView.transform = transformScale
        
        if AppModel.sharedManager().isRestoreFlow {
            progressTitleLabel.text = "restoring_wallet".localized
            restotingInfoLabel.isHidden = false
            restotingWarningLabel.isHidden = false
            progressValueLabel.text = "restored".localized + "0%"
            progressValueLabel.isHidden = false
            cancelButton.isHidden = false
        }
        else if phrase == nil {
            timeoutTimer = Timer.scheduledTimer(timeInterval: 10.0, target: self, selector: #selector(onTimeOut), userInfo: nil, repeats: false)
            
            progressTitleLabel.text = "loading_wallet".localized
            cancelButton.isHidden = true
        }
        
        if Device.screenType == .iPhones_5 {
            logoYOffset.constant = 50
            stackYOffset.constant = 50
        }
        else if Device.screenType == .iPhones_6 {
            logoYOffset.constant = 50
            stackYOffset.constant = 50
        }
        
        startCreateWallet()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        timeoutTimer.invalidate()
        
        AppModel.sharedManager().removeDelegate(self)
    }

    private func startCreateWallet() {
        let appModel = AppModel.sharedManager()
        appModel.addDelegate(self)

        if !appModel.isInternetAvailable {
            appModel.resetWallet(false)

            self.navigationController?.popViewController(animated: true)

            self.alert(title: "error".localized, message: "no_internet".localized) { (_ ) in

            }
        }
        else{
            if let phrase = phrase {
                let created = appModel.createWallet(phrase, pass: password)
                if(!created)
                {
                    self.alert(title: "error".localized, message: "wallet_not_created") { (_ ) in
                        if appModel.isInternetAvailable {
                            self.navigationController?.popToRootViewController(animated: true)
                        }
                        else{
                            DispatchQueue.main.async {
                                self.navigationController?.popViewController(animated: true)
                            }
                        }
                    }
                }
                else{
                    if (!appModel.isRestoreFlow)
                    {
                        UIView.animate(withDuration: 0.3) {
                            self.progressView.progress = 0.2
                        }
                    }
                }
            }
            else{
                let opened = appModel.openWallet(password)
                if(!opened)
                {
                    self.alert(title: "error".localized, message: "wallet_not_opened") { (_ ) in
                        self.navigationController?.popToRootViewController(animated: true)
                    }
                }
                else{
                    UIView.animate(withDuration: 0.3) {
                        self.progressView.progress = 0.2
                    }
                }
            }
        }
    }

    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }

// MARK: IBAction
    @IBAction func onCancel(sender :UIButton) {
        let appModel = AppModel.sharedManager()
        appModel.resetWallet(true)
        
        navigationController?.popToRootViewController(animated: true)
    }
    
    @objc private func onTimeOut() {
        if Settings.sharedManager().isChangedNode() {
            if !self.isPresented {
                self.isPresented = true
                
                let vc = MainTabBarController()
                vc.modalTransitionStyle = .crossDissolve
                self.present(vc, animated: true, completion: nil)
            }
        }
        
//        if Settings.sharedManager().isChangedNode() {
//            let alert = UIAlertController(title: "Incompatible node", message: "You’re trying to connect to an incompatible node.", preferredStyle: .alert)
//
//            let ok = UIAlertAction(title: "Change settings", style: .default, handler: { action in
//                let vc = EnterNodeAddressViewController()
//                vc.completion = {
//                    obj in
//
//                    if obj == true {
//                        self.timeoutTimer = Timer.scheduledTimer(timeInterval: 10.0, target: self, selector: #selector(self.onTimeOut), userInfo: nil, repeats: false)
//
//                        self.startCreateWallet()
//                    }
//                }
//                vc.hidesBottomBarWhenPushed = true
//                self.pushViewController(vc: vc)
//            })
//            alert.addAction(ok)
//
//            let cancel = UIAlertAction(title: "Cancel", style: .default, handler: { action in
//                AppModel.sharedManager().resetWallet(false)
//                self.navigationController?.popViewController(animated: true)
//            })
//            alert.addAction(cancel)
//
//            self.present(alert, animated: true)
//        }
    }
}

extension CreateWalletProgressViewController {
    
    func withPassword(password: String) -> Self {
        
        self.password = password
        
        return self
    }
    
    func withPhrase(phrase: String) -> Self {
        
        self.phrase = phrase
        
        return self
    }
}


extension CreateWalletProgressViewController : WalletModelDelegate {
    
    func onSyncProgressUpdated(_ done: Int32, total: Int32) {
        DispatchQueue.main.async {
            if AppModel.sharedManager().isRestoreFlow {
                if total > 0 {
                    let speed = Double(done) / Double((Date.timeIntervalSinceReferenceDate - self.start))
                   
                    if speed > 0 {
                        let sizeLeft = Double(total-done)
                        let timeLeft = sizeLeft / speed
                        
                        print("-----------")
                        print(timeLeft.asTime(style: .abbreviated))
                        print("-----------")
                    }
    
                    let progress: Float = Float(done) / Float(total)
                    let percent = Int32(progress * 100)
                    
                    self.progressValueLabel.text = "restored".localized + "\(percent)%"
                }
            }
            
            if total == done && !self.isPresented && !AppModel.sharedManager().isRestoreFlow {
                self.isPresented = true
                
                UIView.animate(withDuration: 2, animations: {
                    self.progressView.progress = 1
                }) { (_) in
                    DispatchQueue.main.async {
                        let vc = MainTabBarController()
                        vc.modalTransitionStyle = .crossDissolve
                        self.present(vc, animated: true, completion: nil)
                    }
                }
            }
            else{
                self.progressView.progress = Float(Float(done)/Float(total))
            }
        }
    }
    
    func onWalletError(_ error: String) {
        DispatchQueue.main.async {
            if error == "Connection error." && Settings.sharedManager().isChangedNode() {
                if !self.isPresented {
                    self.isPresented = true
                    
                    let vc = MainTabBarController()
                    vc.modalTransitionStyle = .crossDissolve
                    self.present(vc, animated: true, completion: nil)
                }
            }
            else{
                if let controllers = self.navigationController?.viewControllers {
                    for vc in controllers {
                        if vc is EnterNodeAddressViewController {
                            return
                        }
                    }
                }
                self.alert(title: "error".localized, message: error, handler: { (_ ) in
                    AppModel.sharedManager().resetWallet(false)
                    self.navigationController?.popViewController(animated: true)
                })
            }
        }
    }
    
    func onLocalNodeStarted() {
        DispatchQueue.main.async {
            if !self.isPresented {
                self.isPresented = true
                
                let vc = MainTabBarController()
                vc.modalTransitionStyle = .crossDissolve
                self.present(vc, animated: true, completion: nil)
            }
        }
    }
}
