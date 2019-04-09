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
            progressTitleLabel.text = "Restoring wallet"
            restotingInfoLabel.isHidden = false
            restotingWarningLabel.isHidden = false
            progressValueLabel.text = "Restored 0%"
            progressValueLabel.isHidden = false
            cancelButton.isHidden = false
        }
        else if phrase == nil {
            progressTitleLabel.text = "Loading wallet"
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
        
        AppModel.sharedManager().removeDelegate(self)
    }

    private func startCreateWallet() {
        let appModel = AppModel.sharedManager()
        appModel.addDelegate(self)

        if !appModel.isInternetAvailable {
            self.navigationController?.popViewController(animated: true)

            self.alert(title: "Error", message: "No internet connection") { (_ ) in

            }
        }
        else{
            if let phrase = phrase {
                let created = appModel.createWallet(phrase, pass: password)
                if(!created)
                {
                    self.alert(title: "Error", message: "Wallet not created") { (_ ) in
                        if appModel.isInternetAvailable {
                            self.navigationController?.popToRootViewController(animated: true)
                        }
                        else{
                            let loaf = Loaf("Please check your internet connection and try again", state: .custom(.init(backgroundColor: UIColor.black.withAlphaComponent(0.8), icon: nil)), sender: self)
                            loaf.show(Loaf.Duration.long) { (_ ) in
                            }
                            
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
                    self.alert(title: "Error", message: "Wallet can not be opened") { (_ ) in
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
        appModel.resetWallet()
        
        navigationController?.popToRootViewController(animated: true)
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
                    
                    self.progressValueLabel.text = "Restored \(percent)%"
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
            self.alert(title: "Error", message: error)
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
