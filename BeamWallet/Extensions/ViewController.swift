//
//  ViewController.swift
//  BeamWallet
//
// 3/2/19.
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

import Foundation
import UIKit

extension UIViewController {
    func presentDetail(_ viewControllerToPresent: UIViewController) {
        let transition = CATransition()
        transition.duration = 0.28
        transition.type = CATransitionType.push
        transition.subtype = CATransitionSubtype.fromRight
        self.view.window!.layer.add(transition, forKey: kCATransition)
        
        present(viewControllerToPresent, animated: false)
    }
    
    func dismissDetail() {
        let transition = CATransition()
        transition.duration = 0.28
        transition.type = CATransitionType.push
        transition.subtype = CATransitionSubtype.fromLeft
        self.view.window!.layer.add(transition, forKey: kCATransition)
        
        dismiss(animated: false)
    }
}

extension UIViewController {
    func pushViewController(vc:UIViewController) {
        navigationItem.backBarButtonItem = UIBarButtonItem.arrowButton()
        navigationController?.pushViewController(vc, animated: true)
    }
}

extension UIViewController {
    
    public func openUrl(url:URL) {
        if Settings.sharedManager().isAllowOpenLink {
            UIApplication.shared.open(url , options: [:], completionHandler: nil)
        }
        else{
            self.confirmAlert(title: LocalizableStrings.external_link_title, message: LocalizableStrings.external_link_text, cancelTitle: LocalizableStrings.cancel, confirmTitle: LocalizableStrings.open, cancelHandler: { (_ ) in
                
            }) { (_ ) in
                UIApplication.shared.open(url , options: [:], completionHandler: nil)
            }
        }
    }
    
    func alert(title: String = "", message: String, handler: ((UIAlertAction) -> Void)? = nil) {
        if (self.presentedViewController as? UIAlertController) != nil {
            return
        }
        
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let OKAction = UIAlertAction(title: "OK", style: .default) { (action) in
            if handler != nil {
                handler!(action)
            }
        }
        alertController.addAction(OKAction)
        self.present(alertController, animated: true, completion: nil)
    }
    
    func confirmAlert(title: String, message: String, cancelTitle:String, confirmTitle:String, cancelHandler: @escaping ((UIAlertAction) -> Void) , confirmHandler: @escaping ((UIAlertAction) -> Void)) {
        
        if (self.presentedViewController as? UIAlertController) != nil {
            return
        }
        
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        
        let cancelAction = UIAlertAction(title: cancelTitle, style: .default) { (action) in
            cancelHandler(action)
        }
        alertController.addAction(cancelAction)
        
  
        let confirmAction = UIAlertAction(title: confirmTitle, style: .default) { (action) in
            confirmHandler(action)
        }
        alertController.addAction(confirmAction)
        alertController.preferredAction = confirmAction
        
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
