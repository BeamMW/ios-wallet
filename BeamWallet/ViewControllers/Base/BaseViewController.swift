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

    private  let leftTag = 9821
    private  let rightTag = 9822

    public var largeTitle:String?

    public var minimumVelocityToHide = 1500 as CGFloat
    public var minimumScreenRatioToHide = 0.5 as CGFloat
    public var animationDuration = 0.2 as TimeInterval

    public var isNavigationGradient:Bool {
        return ((self.navigationController as? BMGradientNavigationController) != nil)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = UIColor.main.marine
        
        if self.navigationController?.viewControllers.count == 1 && AppModel.sharedManager().isLoggedin {
           
            if !isNavigationGradient {
                onAddMenuIcon()
            }
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if let navigation = self.navigationController as? BMGradientNavigationController {
            navigation.title = self.largeTitle
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        if let rightButton = self.navigationController?.view.viewWithTag(rightTag)
        {
            rightButton.removeFromSuperview()
        }
    }
    
    @objc private func onLeftMenu() {
        sideMenuController?.toggleLeftViewAnimated()
    }
    
//MARK: - Navigation Buttons
    
    public func onAddMenuIcon() {
        self.navigationItem.leftBarButtonItem = UIBarButtonItem(image: IconLeftMenu(), style: .plain, target: self, action: #selector(onLeftMenu))
    }
    
    @objc private func onLeftBackButton() {
        if self.navigationController?.viewControllers.count == 1 {
            dismissDetail()
        }
        else{
            self.navigationController?.popViewController(animated: true)
        }
    }
    
    public func addLeftButton(image:UIImage?) {
        if self.navigationController?.view.viewWithTag(leftTag) == nil {
            let button = UIButton(type: .system)
            button.tag = leftTag
            button.frame = CGRect(x: 15, y: 60, width: 40, height: 40)
            button.contentHorizontalAlignment = .left
            button.tintColor = UIColor.white
            button.setImage(image, for: .normal)
            button.addTarget(self, action: #selector(onLeftBackButton), for: .touchUpInside)
            self.navigationController?.view.addSubview(button)
        }
    }
    
    public func addRightButton(image:UIImage?, target:Any?, selector:Selector) {
        let backButton = UIButton(type: .system)
        backButton.frame = CGRect(x: UIScreen.main.bounds.size.width-55, y: 60, width: 40, height: 40)
        backButton.contentHorizontalAlignment = .right
        backButton.tintColor = UIColor.white
        backButton.setImage(image, for: .normal)
        backButton.addTarget(target, action: selector, for: .touchUpInside)
        self.navigationController?.view.addSubview(backButton)
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
        if isNavigationGradient {
            
            if let rightButton = self.navigationController?.view.viewWithTag(rightTag)
            {
                rightButton.removeFromSuperview()
            }
            
            let button = UIButton(type: .system)
            button.frame = CGRect(x: UIScreen.main.bounds.size.width-55, y: 60, width: 40, height: 40)
            button.contentHorizontalAlignment = .right
            button.tag = rightTag
            button.tintColor = UIColor.white
            button.isEnabled = enabled
            button.setTitle(title, for: .normal)
            button.addTarget(targer, action: selector!, for: .touchUpInside)
            button.titleLabel?.font = RegularFont(size: 16)
            self.navigationController?.view.addSubview(button)
        }
        else{
            navigationItem.rightBarButtonItem = UIBarButtonItem(title: title, style: .plain, target: targer, action: selector)
            navigationItem.rightBarButtonItem?.tintColor = UIColor.main.brightTeal
            navigationItem.rightBarButtonItem?.isEnabled = enabled
        }
    }
    
    public func enableRightButton(enabled:Bool) {
        if isNavigationGradient {
            if let rightButton = self.navigationController?.view.viewWithTag(rightTag) as? UIButton
            {
                rightButton.isEnabled = enabled
            }
        }
        else{
            navigationItem.rightBarButtonItem?.isEnabled = enabled
        }
    }
    

//MARK: - Feedback
        
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

//MARK: - MFMailComposeViewControllerDelegate

extension BaseViewController : MFMailComposeViewControllerDelegate {

    func mailComposeController(_ didFinishWithcontroller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
        
        didFinishWithcontroller.dismiss(animated: true) {
        }
    }
}

//MARK: - Dismiss Swipe

extension BaseViewController {
    
    public func addSwipeToDismiss() {
        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(onPan(_:)))
        self.view.addGestureRecognizer(panGesture)
    }
    
    private func slideViewVerticallyTo(_ y: CGFloat) {
        let alpha = (self.view.frame.size.height - y) / self.view.frame.size.height
        
        if let visualView = self.view.subviews.first as? UIVisualEffectView {
            visualView.alpha = alpha
        }
        else{
            self.view.alpha = alpha
        }
        
        self.view.frame.origin = CGPoint(x: 0, y: y)
    }
    
    @objc private func onPan(_ panGesture: UIPanGestureRecognizer) {
        if panGesture.state == .began {
            self.view.endEditing(true)
        }
        
        switch panGesture.state {
        case .began, .changed:
            let translation = panGesture.translation(in: view)
            let y = max(0, translation.y)
            self.slideViewVerticallyTo(y)
            break
        case .ended:
            let translation = panGesture.translation(in: view)
            let velocity = panGesture.velocity(in: view)
            let closing = (translation.y > self.view.frame.size.height * minimumScreenRatioToHide) ||
                (velocity.y > minimumVelocityToHide)
            
            if closing {
                UIView.animate(withDuration: animationDuration, animations: {
                    self.slideViewVerticallyTo(self.view.frame.size.height)
                }, completion: { (isCompleted) in
                    if isCompleted {
                        self.dismiss(animated: false, completion: nil)
                    }
                })
            } else {
                UIView.animate(withDuration: animationDuration, animations: {
                    self.slideViewVerticallyTo(0)
                })
            }
            break
        default:
            UIView.animate(withDuration: animationDuration, animations: {
                self.slideViewVerticallyTo(0)
            })
            break
        }
    }
}
