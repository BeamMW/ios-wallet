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
        else if AppDelegate.CurrentTarget == .Master {
            bgView.image = UIImage.init(named: "bgMasternet.jpg");
        }
    }

    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    //MARK: IBAction
    
    @IBAction func onRestoreWallet(sender :UIButton) {
        if AppModel.sharedManager().canRestoreWallet() {
            
            let alertController = UIAlertController(title: "restore_wallet_title".localized, message: "restore_wallet_info".localized, preferredStyle: .alert)
            
            let NoAction = UIAlertAction(title: "cancel".localized, style: .default) { (action) in
            }
            alertController.addAction(NoAction)
            
            let OKAction = UIAlertAction(title: "restore_wallet_title".localized, style: .cancel) { (action) in
                AppModel.sharedManager().isRestoreFlow = true;
                
                let vc = InputPhraseViewController()
                self.pushViewController(vc: vc)
            }
            alertController.addAction(OKAction)          
            
            self.present(alertController, animated: true, completion: nil)
        }
        else{
            self.alert(title: "no_space_title".localized, message: "no_space_info".localized) { (_ ) in
            }
        }
    }
    
    @IBAction func onCreateWallet(sender :UIButton) {
        AppModel.sharedManager().isRestoreFlow = false;

        let vc = IntroPhraseViewController()
        pushViewController(vc: vc)
    }

}
