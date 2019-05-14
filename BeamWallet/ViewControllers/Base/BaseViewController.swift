//
//  BaseViewController.swift
//  BeamWallet
//
// 3/1/19.
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

class BaseViewController: UIViewController {

    private var initialTouchPoint = CGPoint.zero

    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = UIColor.main.marine
    }
    
    public func addRightButton(title:String, targer:Any?, selector:Selector?, enabled:Bool) {
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: title, style: .plain, target: targer, action: selector)
        navigationItem.rightBarButtonItem?.tintColor = UIColor.main.brightTeal
        navigationItem.rightBarButtonItem?.isEnabled = enabled
    }
    
    public func enableRightButton(enabled:Bool) {
        navigationItem.rightBarButtonItem?.isEnabled = enabled
    }
    
    public func addSwipeToDismiss() {
        view.addGestureRecognizer(UIPanGestureRecognizer(target: self, action: #selector(panGestureRecognizerHandler)))
    }

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
}

extension BaseViewController {
    @objc private func panGestureRecognizerHandler(sender:UIGestureRecognizer) {
        let touchPoint = sender.location(in: self.view?.window)
        
        if sender.state == .began {
            initialTouchPoint = touchPoint
        }
        else if sender.state == .changed {
            if touchPoint.y - initialTouchPoint.y > 0 {
                
                self.view.frame = CGRect(x: 0, y: touchPoint.y - initialTouchPoint.y, width: self.view.frame.size.width, height: self.view.frame.size.height)
                
                let offset = (self.view.frame.size.height - self.view.frame.origin.y)
                
                var percent = offset / self.view.frame.size.height
                if percent < 0.85 {
                    percent = 0.85
                }
                
                self.view.alpha = percent
            }
        } else if sender.state == .ended || sender.state == .cancelled {
            if touchPoint.y - initialTouchPoint.y > 100 {
                self.dismiss(animated: true, completion: nil)
            } else {
                UIView.animate(withDuration: 0.3, animations: {
                    self.view.alpha = 1
                    self.view.frame = CGRect(x: 0, y: 0, width: self.view.frame.size.width, height: self.view.frame.size.height)
                })
            }
        }
    }
}
