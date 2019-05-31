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
    
    public func setGradientTopBar(image:UIImage?) {
        self.navigationController?.isNavigationBarHidden = true
        
        let colors = [UIColor.main.brightSkyBlue, UIColor.main.marine.withAlphaComponent(0.1)]

        let gradient: CAGradientLayer = CAGradientLayer()
        gradient.colors = colors.map { $0.cgColor }
        gradient.frame = CGRect(x: 0.0, y: 0.0, width: UIScreen.main.bounds.size.width, height: 180)
        
        let backgroundImage = UIImageView()
       // backgroundImage.image = image
            backgroundImage.clipsToBounds = true
        backgroundImage.contentMode = .scaleToFill
        backgroundImage.frame = CGRect(x: 0.0, y: 0.0, width: UIScreen.main.bounds.size.width, height: 180)
        backgroundImage.layer.addSublayer(gradient)
      //  self.view.insertSubview(backgroundImage, at: 0)
        self.view.addSubview(backgroundImage)
        
        let button = UIButton(type: .system)
        button.frame = CGRect(x: 15, y: 60, width: 40, height: 40)
        button.contentHorizontalAlignment = .left
        button.tintColor = UIColor.white
        button.setImage(IconBack(), for: .normal)
        button.addTarget(self, action: #selector(onLeftBackButton), for: .touchUpInside)
        self.view.addSubview(button)
        
        let statusView = BMNetworkStatusView()
        statusView.y = 110
        statusView.x = 0
        self.view.addSubview(statusView)
    }
    
    var attributedTitle: String? {
        willSet {
            if let titleString = newValue {
                let attributedString = NSMutableAttributedString(string: titleString)
                attributedString.addAttribute(NSAttributedString.Key.kern, value: CGFloat(2), range: NSRange(location: 0, length: titleString.lengthOfBytes(using: .utf8) ))
                
                let w = UIScreen.main.bounds.size.width
                
                let titleLabel = UILabel()
                titleLabel.frame = CGRect(x: 0, y: 55, width: 0, height: 50)
                titleLabel.font = ProMediumFont(size: 20)
                titleLabel.numberOfLines = 1
                titleLabel.attributedText = attributedString
                titleLabel.textColor = UIColor.white
                titleLabel.textAlignment = .center
                titleLabel.sizeToFit()
                
                if titleLabel.frame.size.width > (UIScreen.main.bounds.size.width - 100)
                {
                    let labelMaxW = (UIScreen.main.bounds.size.width - 100)
                    titleLabel.frame = CGRect(x: (w - labelMaxW)/2, y: 55, width: labelMaxW, height: 50)
                }
                else{
                    titleLabel.frame = CGRect(x: (w - titleLabel.frame.size.width)/2, y: 55, width: titleLabel.frame.size.width, height: 50)
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
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: title, style: .plain, target: targer, action: selector)
        navigationItem.rightBarButtonItem?.tintColor = UIColor.main.brightTeal
        navigationItem.rightBarButtonItem?.isEnabled = enabled
    }
    
    public func enableRightButton(enabled:Bool) {
        navigationItem.rightBarButtonItem?.isEnabled = enabled
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
