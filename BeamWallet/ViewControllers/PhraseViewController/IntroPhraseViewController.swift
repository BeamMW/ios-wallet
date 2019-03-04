//
//  IntroPhraseViewController.swift
//  BeamWallet
//
//  Created by Denis on 3/1/19.
//  Copyright © 2019 Denis. All rights reserved.
//

import UIKit

class IntroPhraseViewController: BaseWizardViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = "Create new wallet"
        
        if Device.screenType == .iPhones_5_5s_5c_SE {
            mainStack?.spacing = 60
        }
    }
    
// MARK: IBAction
    @IBAction func onNext(sender :UIButton) {
        let vc = DisplayPhraseViewController()
        pushViewController(vc: vc)
    }
}
