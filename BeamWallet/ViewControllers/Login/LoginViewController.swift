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
        
        switch Settings.sharedManager().target {
        case Testnet:
            bgView.image = BackgroundTestnet()
        case Masternet:
            bgView.image = BackgroundMasternet()
        default:
            return
        }
    }

    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    //MARK: IBAction
    
    @IBAction func onRestoreWallet(sender :UIButton) {
        if AppModel.sharedManager().canRestoreWallet() {
            
            self.confirmAlert(title: LocalizableStrings.restore_wallet_title, message: LocalizableStrings.restore_wallet_info, cancelTitle: LocalizableStrings.cancel, confirmTitle: LocalizableStrings.restore_wallet_title, cancelHandler: { (_ ) in
                
            }) { (_ ) in
                AppModel.sharedManager().isRestoreFlow = true;
                
                self.pushViewController(vc: InputPhraseViewController())
            }
        }
        else{
            self.alert(title: LocalizableStrings.no_space_title, message: LocalizableStrings.no_space_info) { (_ ) in
            }
        }
    }
    
    @IBAction func onCreateWallet(sender :UIButton) {
        AppModel.sharedManager().isRestoreFlow = false;
        
        pushViewController(vc: IntroPhraseViewController())
    }

}
