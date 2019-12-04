//
// ViewController.swift
// BeamWallet
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

let BLUR_TAG = 102

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
    func back(animated: Bool = true) {
        navigationController?.popViewController(animated: animated)
    }
    
    func pushViewController(vc: UIViewController) {
        navigationItem.backBarButtonItem = UIBarButtonItem.arrowButton()
        navigationController?.pushViewController(vc, animated: true)
    }
}

extension UIViewController {
    func removeBlur() {
        self.view.viewWithTag(BLUR_TAG)?.removeFromSuperview()
    }
    func addBlur() {
        self.view.viewWithTag(BLUR_TAG)?.removeFromSuperview()
        if let image = self.view.snapshot() {
            let blured = image.blurredImage(withRadius: 10, iterations: 5, tintColor: UIColor.clear)
            let imageView = UIImageView(frame: UIScreen.main.bounds)
            imageView.image = blured
            imageView.tag = BLUR_TAG
            view.addSubview(imageView)
        }
    }
    
    func openUrl(url: URL) {
        if Settings.sharedManager().isAllowOpenLink {
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
        }
        else {
            self.confirmAlert(title: Localizable.shared.strings.external_link_title, message: Localizable.shared.strings.external_link_text, cancelTitle: Localizable.shared.strings.cancel, confirmTitle: Localizable.shared.strings.open, cancelHandler: { _ in
                
            }) { _ in
                UIApplication.shared.open(url, options: [:], completionHandler: nil)
            }
        }
    }
    
    func alert(title: String = "", message: String, button: String, handler: ((UIAlertAction) -> Void)? = nil) {
        if (self.presentedViewController as? UIAlertController) != nil {
            return
        }
        
        addBlur()
        
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        
        let OKAction = UIAlertAction(title: button, style: .default) { action in
            if handler != nil {
                handler!(action)
            }
            self.view.viewWithTag(BLUR_TAG)?.removeFromSuperview()
        }
        alertController.addAction(OKAction)
        self.present(alertController, animated: true, completion: nil)
    }
    
    func alert(title: String = "", message: String, handler: ((UIAlertAction) -> Void)? = nil) {
        if (self.presentedViewController as? UIAlertController) != nil {
            return
        }
        
        addBlur()
        
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let OKAction = UIAlertAction(title: "OK", style: .default) { action in
            if handler != nil {
                handler!(action)
            }
            self.view.viewWithTag(BLUR_TAG)?.removeFromSuperview()
        }
        alertController.addAction(OKAction)
        self.present(alertController, animated: true, completion: nil)
    }
    
    func confirmAndSkipAlert(title: String, message: String, cancelTitle: String, confirmTitle: String, cancelHandler: @escaping ((UIAlertAction) -> Void), confirmHandler: @escaping ((UIAlertAction) -> Void)) {
        if (self.presentedViewController as? UIAlertController) != nil {
            return
        }
        
        addBlur()
        
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        
        let confirmAction = UIAlertAction(title: confirmTitle, style: .default) { action in
            confirmHandler(action)
            self.view.viewWithTag(BLUR_TAG)?.removeFromSuperview()
        }
        alertController.addAction(confirmAction)
        
        let cancelAction = UIAlertAction(title: cancelTitle, style: .default) { action in
            cancelHandler(action)
            self.view.viewWithTag(BLUR_TAG)?.removeFromSuperview()
        }
        alertController.addAction(cancelAction)
        
        let skipAction = UIAlertAction(title: Localizable.shared.strings.cancel, style: .default) { _ in
            self.view.viewWithTag(BLUR_TAG)?.removeFromSuperview()
        }
        alertController.addAction(skipAction)
        
        alertController.preferredAction = confirmAction
        
        self.present(alertController, animated: true, completion: nil)
    }
    
    func confirmAlert(title: String, message: String, cancelTitle: String, confirmTitle: String, cancelHandler: @escaping ((UIAlertAction) -> Void), confirmHandler: @escaping ((UIAlertAction) -> Void)) {
        if (self.presentedViewController as? UIAlertController) != nil {
            return
        }
        
        addBlur()
        
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)

        let cancelAction = UIAlertAction(title: cancelTitle, style: .default) { action in
            cancelHandler(action)
            self.view.viewWithTag(BLUR_TAG)?.removeFromSuperview()
        }
        alertController.addAction(cancelAction)

        let confirmAction = UIAlertAction(title: confirmTitle, style: .default) { action in
            confirmHandler(action)
            self.view.viewWithTag(BLUR_TAG)?.removeFromSuperview()
        }
        alertController.addAction(confirmAction)
        alertController.preferredAction = confirmAction

        self.present(alertController, animated: true, completion: nil)
    }
}

extension UIViewController {
    func hideKeyboardWhenTappedAround() {
        let tapGesture = UITapGestureRecognizer(target: self,
                                                action: #selector(self.hideKeyboard))
        tapGesture.cancelsTouchesInView = true
        view.addGestureRecognizer(tapGesture)
    }
    
    @objc func hideKeyboard() {
        view.endEditing(true)
    }
}
