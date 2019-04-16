//
// LoginViewController.swift
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

class LoginViewController: BaseViewController {

    @IBOutlet private weak var bgView: UIImageView!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        if AppDelegate.CurrentTarget == .Test {
            bgView.image = UIImage.init(named: "bgTestnet.jpg");
        }
    }

    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    //MARK: IBAction
    
    @IBAction func onRestoreWallet(sender :UIButton) {
        if AppModel.sharedManager().canRestoreWallet() {
            
            let alertController = UIAlertController(title: "Restore Wallet", message: "Only your funds can be fully restored from the blockchain. The transaction history is stored locally and is encrypted with your password, hence it can't be restored.\n\nThat's the final version until the future validation and process.", preferredStyle: .alert)
            
            let NoAction = UIAlertAction(title: "Cancel", style: .default) { (action) in
            }
            alertController.addAction(NoAction)
            
            let OKAction = UIAlertAction(title: "Restore wallet", style: .cancel) { (action) in
                AppModel.sharedManager().isRestoreFlow = true;
                
                let vc = InputPhraseViewController()
                self.pushViewController(vc: vc)
            }
            alertController.addAction(OKAction)          
            
            self.present(alertController, animated: true, completion: nil)
        }
        else{
            self.alert(title: "Not enough storage", message: "To restore the wallet on the phone should be at least 200 MB of free space") { (_ ) in
            }
        }
    }
    
    @IBAction func onCreateWallet(sender :UIButton) {
        AppModel.sharedManager().isRestoreFlow = false;

        let vc = IntroPhraseViewController()
        pushViewController(vc: vc)
    }

}
