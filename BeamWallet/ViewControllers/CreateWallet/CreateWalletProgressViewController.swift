//
//  CreateWalletProgressViewController.swift
//  BeamWallet
//
// 3/3/19.
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

class CreateWalletProgressViewController: UIViewController {

    @IBOutlet private weak var progressView: UIProgressView!
    @IBOutlet private weak var progressTitleLabel: UILabel!
    @IBOutlet private weak var cancelButton: UIButton!

    private var password:String!
    private var phrase:String?
    private var isPresented = false
    
    override func viewDidLoad() {
        super.viewDidLoad()

        navigationItem.hidesBackButton = true

        let progressViewHeight: CGFloat = 4.0
        
        let transformScale = CGAffineTransform(scaleX: 1.0, y: progressViewHeight)
        progressView.transform = transformScale
        
        startCreateWallet()
    }

    private func startCreateWallet() {
        let appModel = AppModel.sharedManager()
        
        if (!appModel.isReachable){
            if phrase == nil {
                progressTitleLabel.text = "Loading wallet"
                cancelButton.isHidden = true
            }
            
            self.alert(title: "Error", message: "No internet connection") { (_ ) in
                self.navigationController?.popToRootViewController(animated: true)
            }
        }
        else{
            appModel.walletDelegate = self
            
            if let phrase = phrase {
                let created = appModel.createWallet(phrase, pass: password)
                if(!created)
                {
                    self.alert(title: "Error", message: "Wallet not created") { (_ ) in
                        self.navigationController?.popToRootViewController(animated: true)
                    }
                }
                else{
                    UIView.animate(withDuration: 0.3) {
                        self.progressView.progress = 0.2
                    }
                }
            }
            else{
                progressTitleLabel.text = "Loading wallet"
                cancelButton.isHidden = true
                
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
        if total == done && !isPresented {
            isPresented = true
            
            DispatchQueue.main.async {
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
        }
        else{
            DispatchQueue.main.async {
                self.progressView.progress = Float(Float(done)/Float(total))
            }
        }
    }
    
    func onWalletError(_ error: String) {
        DispatchQueue.main.async {
            self.alert(title: "Error", message: error)
        }
    }
}
