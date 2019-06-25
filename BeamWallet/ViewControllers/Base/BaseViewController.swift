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

    public var navigationBarOffset:CGFloat = Device.isXDevice ? 150 : 120

    @IBOutlet weak var topOffset: NSLayoutConstraint?
    public var isGradient = false

    public var minimumVelocityToHide = 1500 as CGFloat
    public var minimumScreenRatioToHide = 0.5 as CGFloat
    public var animationDuration = 0.2 as TimeInterval

    public var isAddStatusView = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.navigationController?.isNavigationBarHidden = true

        topOffset?.constant = Device.isXDevice ? 100 : 70
        
        view.backgroundColor = UIColor.main.marine
        
        if self.navigationController?.viewControllers.count ?? 0 > 1 {
            self.addCustomBackButton(target: self, selector: #selector(onLeftBackButton))
        }
    }
    
    private var _isUppercasedTitle = false
    var isUppercasedTitle: Bool{
        get{
            return _isUppercasedTitle
        }
        set{
            _isUppercasedTitle = newValue
        }
    }
    
    override var title: String?{
        get{
            return attributedTitle
        }
        set{
            attributedTitle = newValue?.uppercased()
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if let navigation = navigationController {
            self.sideMenuController?.isLeftViewSwipeGestureEnabled = (navigation.viewControllers.count == 1)
        }
    }
    
    
    @objc private func onLeftMenu() {
        sideMenuController?.toggleLeftViewAnimated()
    }
    
    public func setGradientTopBar(mainColor:UIColor!, addedStatusView:Bool = true) {        
        let height:CGFloat = Device.isXDevice ? 180 : 150

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
        
        if self.navigationController?.viewControllers.count ?? 0 > 1 {
            self.addCustomBackButton(target: self, selector: #selector(onLeftBackButton))
        }
        else{
            self.onAddMenuIcon()
        }
        
        if addedStatusView {
            self.isAddStatusView = true
            
            let statusView = BMNetworkStatusView()
            statusView.y = Device.isXDevice ? 110 : 80
            statusView.x = 0
            self.view.addSubview(statusView)
        }
    }
    
    var attributedTitle: String? {
        willSet {
            if let titleString = newValue {
                view.viewWithTag(987)?.removeFromSuperview()
                
                let attributedString = NSMutableAttributedString(string: (isUppercasedTitle) ? titleString.uppercased() : titleString.capitalizingFirstLetter())
                
                if isUppercasedTitle {
                    attributedString.addAttribute(NSAttributedString.Key.kern, value: CGFloat(2), range: NSRange(location: 0, length: titleString.count))
                }
                
                let w = UIScreen.main.bounds.size.width
                
                let y:CGFloat = Device.isXDevice ? 55 : 30
                
                let titleLabel = UILabel()
                titleLabel.frame = CGRect(x: 0, y: y, width: 0, height: 50)
                titleLabel.font = isUppercasedTitle ? ProMediumFont(size: 20) : SemiboldFont(size: 17)
                titleLabel.numberOfLines = 1
                titleLabel.attributedText = attributedString
                titleLabel.textColor = UIColor.white
                titleLabel.textAlignment = .center
                titleLabel.sizeToFit()
                titleLabel.tag = 987
                
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
        let y:CGFloat = Device.isXDevice ? 60 : 35

        let menuButton = UIButton(type: .system)
        menuButton.contentHorizontalAlignment = .left
        menuButton.tintColor = UIColor.white
        menuButton.setImage(IconLeftMenu(), for: .normal)
        menuButton.addTarget(self, action: #selector(onLeftMenu), for: .touchUpInside)
        menuButton.frame = CGRect(x: defaultX, y: y, width: 40, height: 40)
        self.view.addSubview(menuButton)
    }
    
    @objc public func onLeftBackButton() {
        self.navigationController?.popViewController(animated: true)
    }
    
    
    public func addCustomBackButton(target:Any?, selector:Selector) {
        let y:CGFloat = Device.isXDevice ? 60 : 35

        self.view.viewWithTag(20192)?.removeFromSuperview()

        let button = UIButton(type: .system)
        button.frame = CGRect(x: defaultX, y: y, width: 40, height: 40)
        button.contentHorizontalAlignment = .left
        button.tintColor = UIColor.white
        button.setImage(IconBack(), for: .normal)
        button.tag = 20192
        button.addTarget(target, action: selector, for: .touchUpInside)
        self.view.addSubview(button)
    }
    
    public func addRightButton(image:UIImage?, target:Any?, selector:Selector?) {
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
    
    public func addRightButton(title:String, target:Any?, selector:Selector?, enabled:Bool) {
        let y:CGFloat = Device.isXDevice ? 60 : 35
        
        self.view.viewWithTag(20191)?.removeFromSuperview()
        
        let aString:NSString = title as NSString
        
        let rectNeeded = aString.boundingRect(with: CGSize(width: 9999, height: 15), options: .usesLineFragmentOrigin, attributes: [NSAttributedString.Key.font: RegularFont(size: 16)], context: nil)
        let w = rectNeeded.width+10
        
        let rightButton = UIButton(type: .system)
        rightButton.tag = 20191
        rightButton.titleLabel?.font = RegularFont(size: 16)
        rightButton.contentHorizontalAlignment = .right
        rightButton.tintColor = UIColor.white
        rightButton.setTitle(title, for: .normal)
        rightButton.addTarget(target, action: selector!, for: .touchUpInside)
        rightButton.frame = CGRect(x: UIScreen.main.bounds.size.width-w-15, y: y, width: w, height: 40)
        rightButton.isEnabled = enabled
        rightButton.adjustFontSize = true
        self.view.addSubview(rightButton)
    }
    
    public func enableRightButton(enabled:Bool) {
        if let button = view.viewWithTag(20191) as? UIButton {
            button.isEnabled = enabled
        }
    }
    
    public func removeRightButton() {
        self.view.viewWithTag(20191)?.removeFromSuperview()
    }
    
    public func removeLeftButton() {
        self.view.viewWithTag(20192)?.removeFromSuperview()
    }

//MARK: - Feedback
        
    public func showRateDialog() {
        let logoView = UIImageView(frame: CGRect(x: 10, y: 14, width: 40, height: 31))
        logoView.image = RateLogo()
        
        let view = UIView(frame: CGRect(x: 95, y: 15, width: 60, height: 60))
        view.backgroundColor = UIColor.init(red: 11/255, green: 22/255, blue: 36/255, alpha: 1)
        view.layer.cornerRadius = 8
        view.addSubview(logoView)
        
        let showAlert = UIAlertController(title: Localizables.shared.strings.rate_title, message: Localizables.shared.strings.rate_text, preferredStyle: .alert)
        showAlert.view.addSubview(view)
        
        let height = NSLayoutConstraint(item: showAlert.view!, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: 285)
        let width = NSLayoutConstraint(item: showAlert.view!, attribute: .width, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: 250)
        showAlert.view.addConstraint(height)
        showAlert.view.addConstraint(width)
        
        showAlert.addAction(UIAlertAction(title: Localizables.shared.strings.rate_app, style: .default, handler: { action in
            AppStoreReviewManager.openAppStoreRatingPage()
        }))
        showAlert.addAction(UIAlertAction(title: Localizables.shared.strings.feedback, style: .default, handler: { action in
            AppStoreReviewManager.resetRating()
            
            self.writeFeedback()
        }))
        showAlert.addAction(UIAlertAction(title: Localizables.shared.strings.not_now, style: .default, handler: { action in
            AppStoreReviewManager.resetRating()
        }))
        
        self.present(showAlert, animated: true, completion: nil)
    }
    
    public func writeFeedback() {
        if(MFMailComposeViewController.canSendMail()) {
            let mailComposer = MFMailComposeViewController()
            mailComposer.mailComposeDelegate = self
            mailComposer.setToRecipients([Localizables.shared.strings.support_email])
            mailComposer.setSubject(Localizables.shared.strings.ios_feedback)
            present(mailComposer, animated: true, completion: nil)
        }
        else {
            UIApplication.shared.open(URL(string: Localizables.shared.strings.support_email_mailto)!, options: [:]) { (_ ) in
            }
        }
    }
    
    //MARK: - Security
    
    @objc public func onHideAmounts() {
        if !Settings.sharedManager().isHideAmounts {
            if Settings.sharedManager().isAskForHideAmounts {
                
                self.confirmAlert(title: Localizables.shared.strings.activate_security_title, message: Localizables.shared.strings.activate_security_text, cancelTitle: Localizables.shared.strings.cancel, confirmTitle: Localizables.shared.strings.activate, cancelHandler: { (_ ) in
                    
                }) { (_ ) in
                    Settings.sharedManager().isAskForHideAmounts = false
                    Settings.sharedManager().isHideAmounts = !Settings.sharedManager().isHideAmounts
                }
            }
            else{
                Settings.sharedManager().isHideAmounts = !Settings.sharedManager().isHideAmounts
            }
        }
        else{
            Settings.sharedManager().isHideAmounts = !Settings.sharedManager().isHideAmounts
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
