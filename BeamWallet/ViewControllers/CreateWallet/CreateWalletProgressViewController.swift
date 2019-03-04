//
//  CreateWalletProgressViewController.swift
//  BeamWallet
//
//  Created by Denis on 3/3/19.
//  Copyright © 2019 Denis. All rights reserved.
//

import UIKit

class CreateWalletProgressViewController: UIViewController {

    @IBOutlet private weak var progressView: UIProgressView!
    @IBOutlet private weak var progressTitleLabel: UILabel!
    @IBOutlet private weak var cancelButton: UIButton!

    private var password:String!
    private var phrase:String?

    override func viewDidLoad() {
        super.viewDidLoad()

        navigationItem.hidesBackButton = true

        let progressViewHeight: CGFloat = 4.0
        
        let transformScale = CGAffineTransform(scaleX: 1.0, y: progressViewHeight)
        progressView.transform = transformScale
        
        startCreateWallet()
    }

    private func startCreateWallet() {
        let appModel = AppModel.sharedManager()!
        appModel.walletDelegate = self
        
        if let phrase = phrase {
            let created = appModel.createWallet(phrase, pass: password)
            if(!created)
            {
                self.alert(title: "Error", message: "Wallet not created")
                navigationController?.popToRootViewController(animated: true)
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
                self.alert(title: "Error", message: "Wallet can not be opened")
                navigationController?.popToRootViewController(animated: true)
            }
            else{
                UIView.animate(withDuration: 0.3) {
                    self.progressView.progress = 0.2
                }
            }
        }
    }

    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }

// MARK: IBAction
    @IBAction func onCancel(sender :UIButton) {
        let appModel = AppModel.sharedManager()!
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
        if total == done {
            DispatchQueue.main.async {
                UIView.animate(withDuration: 2, animations: {
                    self.progressView.progress = 1
                }) { (_) in
                    
                }
            }
        }
        else{
            UIView.animate(withDuration: 2, animations: {
                self.progressView.progress = Float(Float(done)/Float(total))
            }) { (_) in
                
            }
        }
    }
    
    func onWalletError(_ error: String!) {
        DispatchQueue.main.async {
            self.alert(title: "Error", message: error)
        }
    }
}
