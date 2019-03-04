//
//  ViewController.swift
//  BeamWallet
//
//  Created by Denis on 3/2/19.
//  Copyright © 2019 Denis. All rights reserved.
//

import Foundation
import UIKit

extension UIViewController {
    func pushViewController(vc:UIViewController) {
        let backItem = UIBarButtonItem(title: "", style: .plain, target: nil, action: nil)
        navigationItem.backBarButtonItem = backItem        
        navigationController?.pushViewController(vc, animated: true)
    }
}

extension UIViewController {
    func alert(title: String = "", message: String) {
        if (self.presentedViewController as? UIAlertController) != nil {
            return
        }
        
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let OKAction = UIAlertAction(title: "OK", style: .default, handler: nil)
        alertController.addAction(OKAction)
        self.present(alertController, animated: true, completion: nil)
    }
}

extension UIViewController {
    func hideKeyboardWhenTappedAround() {
        let tapGesture = UITapGestureRecognizer(target: self,
                                                action: #selector(hideKeyboard))
        view.addGestureRecognizer(tapGesture)
    }
    
    @objc func hideKeyboard() {
        view.endEditing(true)
    }
}
