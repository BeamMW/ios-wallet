//
//  LoginViewController.swift
//  BeamWallet
//
//  Created by Denis on 2/28/19.
//  Copyright © 2019 Denis. All rights reserved.
//

import UIKit

class LoginViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
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
