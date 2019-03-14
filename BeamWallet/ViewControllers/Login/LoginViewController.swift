//
//  LoginViewController.swift
//  BeamWallet
//
// 2/28/19.
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
        let vc = InputPhraseViewController()
        pushViewController(vc: vc)
    }
    
    @IBAction func onCreateWallet(sender :UIButton) {
        let vc = IntroPhraseViewController()
        pushViewController(vc: vc)
    }

}
