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
    @IBOutlet private weak var restoreButton: UIButton!
    @IBOutlet private weak var languageButton: UIButton!
    @IBOutlet private weak var createButton: UIButton!
    @IBOutlet private weak var titleLabel: UILabel!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        setTitles()
        
        switch Settings.sharedManager().target {
        case Testnet:
            bgView.image = BackgroundTestnet()
        case Masternet:
            bgView.image = BackgroundMasternet()
        default:
            break
        }
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    private func setTitles() {
        titleLabel.text = Localizable.shared.strings.beam_title
        createButton.setTitle(Localizable.shared.strings.create_new_wallet.lowercased(), for: .normal)
        restoreButton.setTitle(Localizable.shared.strings.restore_wallet_title, for: .normal)
        languageButton.setTitle(Settings.sharedManager().shortLanguageName(), for: .normal)
    }
    
    //MARK: IBAction
    
    @IBAction func onRestoreWallet(sender :UIButton) {
        AppModel.sharedManager().resetWallet(true)

        if AppModel.sharedManager().canRestoreWallet() {
            
            self.confirmAlert(title: Localizable.shared.strings.restore_wallet_title, message: Localizable.shared.strings.restore_wallet_info, cancelTitle: Localizable.shared.strings.cancel, confirmTitle: Localizable.shared.strings.restore_wallet_title, cancelHandler: { (_ ) in
                
            }) { (_ ) in
                AppModel.sharedManager().isRestoreFlow = true;
                self.pushViewController(vc: RestoreOptionsViewController())
            }
        }
        else{
            self.alert(title: Localizable.shared.strings.no_space_title, message: Localizable.shared.strings.no_space_info) { (_ ) in
            }
        }
    }
    
    @IBAction func onCreateWallet(sender :UIButton) {
        AppModel.sharedManager().resetWallet(true)
        AppModel.sharedManager().isRestoreFlow = false;

        pushViewController(vc: IntroPhraseViewController())
    }

    @IBAction func onLanguage(sender :UIButton) {
        let vc = LanguagePickerViewController()
        vc.completion = {[weak self] obj in
            self?.setTitles()
        }
        pushViewController(vc: vc)
    }
}
