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
    
    }
    
    @IBAction func onCreateWallet(sender :UIButton) {
        let backItem = UIBarButtonItem(title: "", style: .plain, target: nil, action: nil)
        navigationItem.backBarButtonItem = backItem
        
        let vc = IntroPhraseViewController()
        navigationController?.pushViewController(vc, animated: true)
    }

}
