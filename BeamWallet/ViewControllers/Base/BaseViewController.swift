//
// BaseViewController.swift
// BeamWallet
//
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

    public var largeTitle:String?
    public var isGradient = false

    public var minimumVelocityToHide = 1500 as CGFloat
    public var minimumScreenRatioToHide = 0.5 as CGFloat
    public var animationDuration = 0.2 as TimeInterval

    public var isNavigationGradient:Bool {
        return ((self.navigationController as? BMGradientNavigationController) != nil)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = UIColor.main.marine
    }
    
    
    @objc private func onLeftMenu() {
        sideMenuController?.toggleLeftViewAnimated()
    }
    
    public func setGradientTopBar(mainColor:UIColor!, addedStatusView:Bool = true) {
        self.navigationController?.isNavigationBarHidden = true
        
        let height:CGFloat = Device.isXDevice ? 180 : 150
        let y:CGFloat = Device.isXDevice ? 60 : 35

        let colors = [mainColor, UIColor.main.marine.withAlphaComponent(0.1)]

        let gradient: CAGradientLayer = CAGradientLayer()
        gradient.colors = colors.map { $0?.cgColor ?? UIColor.white.cgColor }
        gradient.frame = CGRect(x: 0.0, y: 0.0, width: UIScreen.main.bounds.size.width, height: height)
        
        let backgroundImage = UIImageView()
        backgroundImage.clipsToBounds = true
        backgroundImage.contentMode = .scaleToFill
        backgroundImage.frame = CGRect(x: 0.0, y: 0.0, width: UIScreen.main.bounds.size.width, height: height)
        backgroundImage.layer.addSublayer(gradient)
        self.view.addSubview(backgroundImage)
        
        let button = UIButton(type: .system)
        button.frame = CGRect(x: 15, y: y, width: 40, height: 40)
        button.contentHorizontalAlignment = .left
        button.tintColor = UIColor.white
        button.setImage(IconBack(), for: .normal)
        button.addTarget(self, action: #selector(onLeftBackButton), for: .touchUpInside)
        self.view.addSubview(button)
        
        if addedStatusView {
            let statusView = BMNetworkStatusView()
            statusView.y = Device.isXDevice ? 110 : 80
            statusView.x = 0
            self.view.addSubview(statusView)
        }
    }
    
    var attributedTitle: String? {
        willSet {
            if let titleString = newValue {
                let attributedString = NSMutableAttributedString(string: titleString)
                attributedString.addAttribute(NSAttributedString.Key.kern, value: CGFloat(2), range: NSRange(location: 0, length: titleString.lengthOfBytes(using: .utf8) ))
                
                let w = UIScreen.main.bounds.size.width
                
                let y:CGFloat = Device.isXDevice ? 55 : 30
                
                let titleLabel = UILabel()
                titleLabel.frame = CGRect(x: 0, y: y, width: 0, height: 50)
                titleLabel.font = ProMediumFont(size: 20)
                titleLabel.numberOfLines = 1
                titleLabel.attributedText = attributedString
                titleLabel.textColor = UIColor.white
                titleLabel.textAlignment = .center
                titleLabel.sizeToFit()
                
                if titleLabel.frame.size.width > (UIScreen.main.bounds.size.width - 100)
                {
                    let labelMaxW = (UIScreen.main.bounds.size.width - 100)
                    titleLabel.frame = CGRect(x: (w - labelMaxW)/2, y: y, width: labelMaxW, height: 50)
                }
                else{
                    titleLabel.frame = CGRect(x: (w - titleLabel.frame.size.width)/2, y: y, width: titleLabel.frame.size.width, height: 50)
                }
                
                titleLabel.adjustsFontSizeToFitWidth = true
                titleLabel.minimumScaleFactor = 0.7
                
                view.addSubview(titleLabel)
            }
        }
    }
    
//MARK: - Navigation Buttons
    
    public func onAddMenuIcon() {
        self.navigationItem.leftBarButtonItem = UIBarButtonItem(image: IconLeftMenu(), style: .plain, target: self, action: #selector(onLeftMenu))
    }
    
    @objc private func onLeftBackButton() {
        self.navigationController?.popViewController(animated: true)
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
    
    public func addRightButton(image:UIImage?, targer:Any?, selector:Selector?) {
        if isGradient {
            let y:CGFloat = Device.isXDevice ? 60 : 35

            self.view.viewWithTag(20191)?.removeFromSuperview()
            
            let rightButton = UIButton(type: .system)
            rightButton.tag = 20191
            rightButton.contentHorizontalAlignment = .right
            rightButton.tintColor = UIColor.white
            rightButton.setImage(image, for: .normal)
            rightButton.addTarget(target, action: selector!, for: .touchUpInside)
            rightButton.frame = CGRect(x: UIScreen.main.bounds.size.width-55, y: y, width: 40, height: 40)
            self.view.addSubview(rightButton)
        }
        else {
            navigationItem.rightBarButtonItem = UIBarButtonItem(image: image, style: .plain, target: targer, action: selector)
            navigationItem.rightBarButtonItem?.tintColor = UIColor.main.brightTeal
        }
    }
    
    public func addRightButton(title:String, targer:Any?, selector:Selector?, enabled:Bool) {
        if isGradient {
            let y:CGFloat = Device.isXDevice ? 60 : 35

            self.view.viewWithTag(20191)?.removeFromSuperview()

            let rightButton = UIButton(type: .system)
            rightButton.tag = 20191
            rightButton.contentHorizontalAlignment = .right
            rightButton.tintColor = UIColor.white
            rightButton.setTitle(title, for: .normal)
            rightButton.addTarget(target, action: selector!, for: .touchUpInside)
            rightButton.frame = CGRect(x: UIScreen.main.bounds.size.width-55, y: y, width: 40, height: 40)
            rightButton.isEnabled = enabled
            self.view.addSubview(rightButton)
        }
        else {
            navigationItem.rightBarButtonItem = UIBarButtonItem(title: title, style: .plain, target: targer, action: selector)
            navigationItem.rightBarButtonItem?.tintColor = UIColor.main.brightTeal
            navigationItem.rightBarButtonItem?.isEnabled = enabled
        }
    }
    
    public func enableRightButton(enabled:Bool) {
        if isGradient {
            if let button = view.viewWithTag(20191) as? UIButton {
                button.isEnabled = enabled
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
