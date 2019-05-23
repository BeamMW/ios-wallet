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
import MessageUI

class BaseViewController: UIViewController {

    private var initialTouchPoint = CGPoint.zero

    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = UIColor.main.marine
    }
    
    public func addLeftButton(image:UIImage?, target:Any?, selector:Selector) {
        let backButton = UIButton(type: .system)
        backButton.frame = CGRect(x: 15, y: 60, width: 40, height: 40)
        backButton.contentHorizontalAlignment = .left
        backButton.tintColor = UIColor.white
        backButton.setImage(image, for: .normal)
        backButton.addTarget(target, action: selector, for: .touchUpInside)
        self.navigationController?.navigationBar.addSubview(backButton)
    }
    
    public func addRightButton(image:UIImage?, target:Any?, selector:Selector) {
        let backButton = UIButton(type: .system)
        backButton.frame = CGRect(x: UIScreen.main.bounds.size.width-55, y: 60, width: 40, height: 40)
        backButton.contentHorizontalAlignment = .right
        backButton.tintColor = UIColor.white
        backButton.setImage(image, for: .normal)
        backButton.addTarget(target, action: selector, for: .touchUpInside)
        self.navigationController?.navigationBar.addSubview(backButton)
    }
    
    public func addCustomBackButton(target:Any?, selector:Selector) {
        let backButton = UIButton(type: .system)
        backButton.frame = CGRect(x: 0, y: 0, width: 40, height: 40)
        backButton.contentHorizontalAlignment = .left
        backButton.tintColor = UIColor.white
        backButton.setImage(IconBack(), for: .normal)
        backButton.addTarget(target, action: selector, for: .touchUpInside)
        self.navigationItem.leftBarButtonItem = UIBarButtonItem(customView: backButton)
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
    
    public func showRateDialog() {
        let logoView = UIImageView(frame: CGRect(x: 10, y: 14, width: 40, height: 31))
        logoView.image = RateLogo()
        
        let view = UIView(frame: CGRect(x: 95, y: 15, width: 60, height: 60))
        view.backgroundColor = UIColor.init(red: 11/255, green: 22/255, blue: 36/255, alpha: 1)
        view.layer.cornerRadius = 8
        view.addSubview(logoView)
        
        let showAlert = UIAlertController(title: LocalizableStrings.rate_title, message: LocalizableStrings.rate_text, preferredStyle: .alert)
        showAlert.view.addSubview(view)
        
        let height = NSLayoutConstraint(item: showAlert.view!, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: 285)
        let width = NSLayoutConstraint(item: showAlert.view!, attribute: .width, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: 250)
        showAlert.view.addConstraint(height)
        showAlert.view.addConstraint(width)
        
        showAlert.addAction(UIAlertAction(title: LocalizableStrings.rate_app, style: .default, handler: { action in
            AppStoreReviewManager.openAppStoreRatingPage()
        }))
        showAlert.addAction(UIAlertAction(title: LocalizableStrings.feedback, style: .default, handler: { action in
            AppStoreReviewManager.resetRating()
            
            self.writeFeedback()
        }))
        showAlert.addAction(UIAlertAction(title: LocalizableStrings.not_now, style: .default, handler: { action in
            AppStoreReviewManager.resetRating()
        }))
        
        self.present(showAlert, animated: true, completion: nil)
    }
    
    public func writeFeedback() {
        if(MFMailComposeViewController.canSendMail()) {
            let mailComposer = MFMailComposeViewController()
            mailComposer.mailComposeDelegate = self
            mailComposer.setToRecipients([LocalizableStrings.support_email])
            mailComposer.setSubject(LocalizableStrings.ios_feedback)
            present(mailComposer, animated: true, completion: nil)
        }
        else {
            UIApplication.shared.open(URL(string: LocalizableStrings.support_email_mailto)!, options: [:]) { (_ ) in
            }
        }
    }
}

extension BaseViewController : MFMailComposeViewControllerDelegate {

    func mailComposeController(_ didFinishWithcontroller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
        
        didFinishWithcontroller.dismiss(animated: true) {
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
