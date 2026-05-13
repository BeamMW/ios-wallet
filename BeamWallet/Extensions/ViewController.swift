//
// ViewController.swift
// BeamWallet
//
// 3/2/19.
// Copyright 2026 Beam Development
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
    
    func openUrl(url: URL, additionalInfo:String? = nil, infoDelay:Double? = nil) {
        if Settings.sharedManager().isAllowOpenLink {
            if let info = additionalInfo, let seconds = infoDelay {
                BMToast.show(text: info, shadow: true, duration: seconds, block: {
                    UIApplication.shared.open(url, options: [:], completionHandler: nil)
                })
            }
            else{
                UIApplication.shared.open(url, options: [:], completionHandler: nil)
            }
        }
        else {
            self.confirmAlert(title: Localizable.shared.strings.external_link_title, message: Localizable.shared.strings.external_link_text, cancelTitle: Localizable.shared.strings.cancel, confirmTitle: Localizable.shared.strings.open, cancelHandler: { _ in

            }, confirmHandler: { _ in
                if let info = additionalInfo, let seconds = infoDelay {
                    BMToast.show(text: info, shadow: true, duration: seconds, block: {
                        UIApplication.shared.open(url, options: [:], completionHandler: nil)
                    })
                }
                else{
                    UIApplication.shared.open(url, options: [:], completionHandler: nil)
                }
            })
        }
    }
    
    func alert(title: String = "", message: String, button: String, handler: ((UIAlertAction) -> Void)? = nil) {
        BMAlertViewController.present(
            from: self,
            title: title,
            message: message,
            actions: [makeAlertAction(title: button, isConfirm: true, handler: handler)]
        )
    }

    func alert(title: String = "", message: String, handler: ((UIAlertAction) -> Void)? = nil) {
        alert(title: title, message: message, button: "OK", handler: handler)
    }

    // `cancelTitle` is a meaningful choice (e.g. "Don't save"), not a dismiss — it stays `.default`
    // styled. The third action is the actual dismiss/cancel.
    func confirmAndSkipAlert(title: String, message: String, cancelTitle: String, confirmTitle: String, cancelHandler: @escaping ((UIAlertAction) -> Void), confirmHandler: @escaping ((UIAlertAction) -> Void)) {
        BMAlertViewController.present(
            from: self,
            title: title,
            message: message,
            actions: [
                makeAlertAction(title: confirmTitle, isConfirm: true, handler: confirmHandler),
                makeAlertAction(title: cancelTitle, isConfirm: true, handler: cancelHandler),
                BMAlertViewController.Action(title: Localizable.shared.strings.cancel, style: .cancel, handler: nil)
            ]
        )
    }

    func confirmAlert(title: String, message: String, cancelTitle: String, confirmTitle: String, cancelHandler: @escaping ((UIAlertAction) -> Void), confirmHandler: @escaping ((UIAlertAction) -> Void)) {
        BMAlertViewController.present(
            from: self,
            title: title,
            message: message,
            actions: [
                makeAlertAction(title: confirmTitle, isConfirm: true, handler: confirmHandler),
                makeAlertAction(title: cancelTitle, isConfirm: false, handler: cancelHandler)
            ]
        )
    }

    private func makeAlertAction(title: String, isConfirm: Bool, handler: ((UIAlertAction) -> Void)?) -> BMAlertViewController.Action {
        let style: BMAlertViewController.ActionStyle
        if !isConfirm {
            style = .cancel
        } else if BMAlertViewController.isDestructiveTitle(title) {
            style = .destructive
        } else {
            style = .default
        }
        let bridged: (() -> Void)? = handler.map { cb in
            { cb(UIAlertAction(title: title, style: .default, handler: nil)) }
        }
        return BMAlertViewController.Action(title: title, style: style, handler: bridged)
    }
}

extension BMAlertViewController {
    static func isDestructiveTitle(_ title: String) -> Bool {
        let destructive: [String] = [
            Localizable.shared.strings.delete,
            Localizable.shared.strings.remove_wallet,
            Localizable.shared.strings.dapps_uninstall,
            Localizable.shared.strings.asset_swap_cancel_order
        ]
        return destructive.contains { $0.caseInsensitiveCompare(title) == .orderedSame }
    }
}

extension UIViewController {
    func hideKeyboardWhenTappedAround() {
        let tapGesture = UITapGestureRecognizer(target: self,
                                                action: #selector(self.hideKeyboard))
        tapGesture.cancelsTouchesInView = false
        view.addGestureRecognizer(tapGesture)
    }
    
    @objc func hideKeyboard() {
        view.endEditing(true)
    }
}
