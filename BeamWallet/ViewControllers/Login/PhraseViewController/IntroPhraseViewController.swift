//
// IntroPhraseViewController.swift
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

class IntroPhraseViewController: BaseWizardViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = Localizable.shared.strings.create_new_wallet
        
        switch Device.screenType {
        case .iPhones_5:
            mainStack?.spacing = 50
        default:
            return
        }
    }
    
// MARK: IBAction
    @IBAction func onNext(sender :UIButton) {
        let vc = DisplayPhraseViewController()
        pushViewController(vc: vc)
    }
}
