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
    
    @IBOutlet private weak var textLabel: UILabel!
    @IBOutlet private weak var nextButton: UIButton!

    public var increaseSecutirty = false
    
    override var isUppercasedTitle: Bool {
        get{
            return true
        }
        set{
            super.isUppercasedTitle = true
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setGradientTopBar(mainColor: UIColor.main.peacockBlue, addedStatusView: false)

        title = Localizable.shared.strings.seed_prhase
        
        switch Device.screenType {
        case .iPhones_5:
            mainStack?.spacing = 50
        default:
            return
        }
    }
    
// MARK: IBAction
    @IBAction func onNext(sender :UIButton) {
        let vc = SeedPhraseViewController(event: .display, words: nil)
      //  vc.increaseSecutirty = increaseSecutirty
        pushViewController(vc: vc)
    }
}
