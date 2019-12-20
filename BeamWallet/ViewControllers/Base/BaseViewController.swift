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
import SwipeTransition

class BaseViewController: UIViewController {
    public var navigationBarOffset: CGFloat = Device.isXDevice ? 150 : 120
    
    @IBOutlet var topOffset: NSLayoutConstraint?
    public var isGradient = false
    
    public var minimumVelocityToHide = 1500 as CGFloat
    public var minimumScreenRatioToHide = 0.5 as CGFloat
    public var animationDuration = 0.2 as TimeInterval
    
    public var isAddStatusView = false
    
    public var disableMenu = false
    
    private var alpha:CGFloat = 1.0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.navigationController?.isNavigationBarHidden = true
        
        self.topOffset?.constant = Device.isXDevice ? 100 : 70
        
        view.backgroundColor = UIColor.main.marine
        
        if self.navigationController?.viewControllers.count ?? 0 > 1 {
            self.addCustomBackButton(target: self, selector: #selector(self.onLeftBackButton))
        }
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        if let rightButton = view.viewWithTag(20191), let titleLabel = view.viewWithTag(987) {
            let offset = rightButton.frame.size.width + 25
            var frame = titleLabel.frame
            frame.origin.x = offset
            frame.size.width = view.bounds.width - (offset * 2)
            titleLabel.frame = frame
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        self.view.endEditing(true)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if let navigation = navigationController {
            self.sideMenuController?.isLeftViewSwipeGestureEnabled = (navigation.viewControllers.count == 1)
        }
    }
    
    override var title: String? {
        get {
            return self.attributedTitle
        }
        set {
            self.attributedTitle = newValue?.uppercased()
        }
    }
    
    @objc private func onLeftMenu() {
        sideMenuController?.toggleLeftViewAnimated()
    }
    
    public func setGradientTopBar(mainColor: UIColor!, addedStatusView: Bool = true, menu: Bool = false) {
        self.isGradient = true
        
        view.viewWithTag(10)?.removeFromSuperview()
        view.viewWithTag(11)?.removeFromSuperview()
        
        let height: CGFloat = Device.isXDevice ? 180 : 150
        
        let colors = [mainColor, UIColor.clear]
        
        let gradient: CAGradientLayer = CAGradientLayer()
        gradient.colors = colors.map { $0?.cgColor ?? UIColor.white.cgColor }
        gradient.frame = CGRect(x: 0.0, y: 0.0, width: UIScreen.main.bounds.size.width, height: height)
        
        let backgroundImage = UIImageView()
        backgroundImage.clipsToBounds = true
        backgroundImage.contentMode = .scaleToFill
        backgroundImage.frame = CGRect(x: 0.0, y: 0.0, width: UIScreen.main.bounds.size.width, height: height)
        backgroundImage.tag = 10
        backgroundImage.layer.addSublayer(gradient)
        backgroundImage.alpha = 0.5
        self.view.addSubview(backgroundImage)

        if menu {
            self.onAddMenuIcon()
        }
        else {
            if self.navigationController?.viewControllers.count ?? 0 > 1 {
                self.addCustomBackButton(target: self, selector: #selector(self.onLeftBackButton))
            }
            else if !self.disableMenu {
                self.onAddMenuIcon()
            }
        }
        
        if addedStatusView {
            self.isAddStatusView = true
            
            let statusView = BMNetworkStatusView()
            statusView.tag = 11
            statusView.y = Device.isXDevice ? 110 : 80
            statusView.x = 5
            self.view.addSubview(statusView)
        }
        
        if addedStatusView {
            topOffset?.constant = navigationBarOffset
        }
        else{
            topOffset?.constant = navigationBarOffset - (Device.isXDevice ? 0 : 20)
        }
        
    }
    
    var attributedTitle: String? {
        willSet {
            if let titleString = newValue {
                view.viewWithTag(987)?.removeFromSuperview()
                
                let attributedString = NSMutableAttributedString(string: titleString.uppercased())
                                  attributedString.addAttribute(NSAttributedString.Key.kern, value: CGFloat(2), range: NSRange(location: 0, length: titleString.count))

                
                let w = UIScreen.main.bounds.size.width
                
                let y: CGFloat = Device.isXDevice ? 55 : 30
                
                let titleLabel = UILabel()
                titleLabel.frame = CGRect(x: 60, y: y, width: w - 120, height: 50)
                titleLabel.font = ProMediumFont(size: 20)
                titleLabel.numberOfLines = 1
                titleLabel.attributedText = attributedString
                titleLabel.textColor = UIColor.white
                titleLabel.textAlignment = .center
                titleLabel.tag = 987
                titleLabel.lineBreakMode = .byTruncatingTail
                
                view.addSubview(titleLabel)
            }
        }
    }
    
    // MARK: - Navigation Buttons
    
    public func onAddMenuIcon() {
        view.viewWithTag(12)?.removeFromSuperview()
        
        let y: CGFloat = Device.isXDevice ? 60 : 35
        
        let menuButton = UIButton(type: .system)
        menuButton.tag = 12
        menuButton.contentHorizontalAlignment = .left
        menuButton.tintColor = UIColor.white
        menuButton.setImage(IconLeftMenu(), for: .normal)
        menuButton.addTarget(self, action: #selector(self.onLeftMenu), for: .touchUpInside)
        menuButton.frame = CGRect(x: defaultX, y: y, width: 40, height: 40)
        self.view.addSubview(menuButton)
    }
    
    @objc public func onLeftBackButton() {
        back()
    }
    
    public func addCustomBackButton(target: Any?, selector: Selector) {
        let y: CGFloat = Device.isXDevice ? 60 : 35
        
        self.view.viewWithTag(13)?.removeFromSuperview()
        
        let button = UIButton(type: .system)
        button.frame = CGRect(x: defaultX, y: y, width: 40, height: 40)
        button.contentHorizontalAlignment = .left
        button.tintColor = UIColor.white
        button.setImage(IconBack(), for: .normal)
        button.tag = 13
        button.addTarget(target, action: selector, for: .touchUpInside)
        self.view.addSubview(button)
    }
    
    public func addRightButton(image: UIImage?, target: Any?, selector: Selector?) {
        let y: CGFloat = Device.isXDevice ? 60 : 35
        
        self.view.viewWithTag(20191)?.removeFromSuperview()
        
        let rightButton = UIButton(type: .system)
        rightButton.tag = 20191
        rightButton.contentHorizontalAlignment = .right
        rightButton.tintColor = UIColor.white
        rightButton.setImage(image, for: .normal)
        rightButton.addTarget(target, action: selector!, for: .touchUpInside)
        rightButton.frame = CGRect(x: UIScreen.main.bounds.size.width - 55, y: y, width: 40, height: 40)
        self.view.addSubview(rightButton)
    }
    
    public func addRightButton(title: String, target: Any?, selector: Selector?, enabled: Bool) {
        let y: CGFloat = Device.isXDevice ? 60 : 35
        
        self.view.viewWithTag(20191)?.removeFromSuperview()
        
        let aString: NSString = title as NSString
        
        let rectNeeded = aString.boundingRect(with: CGSize(width: 9999, height: 15), options: .usesLineFragmentOrigin, attributes: [NSAttributedString.Key.font: RegularFont(size: 16)], context: nil)
        let w = rectNeeded.width + 10
        
        let rightButton = UIButton(type: .system)
        rightButton.tag = 20191
        rightButton.titleLabel?.font = RegularFont(size: 16)
        rightButton.contentHorizontalAlignment = .right
        rightButton.tintColor = UIColor.main.brightTeal
        rightButton.setTitle(title, for: .normal)
        rightButton.addTarget(target, action: selector!, for: .touchUpInside)
        rightButton.frame = CGRect(x: UIScreen.main.bounds.size.width - w - 15, y: y, width: w, height: 40)
        rightButton.isEnabled = enabled
        rightButton.adjustFontSize = true
        self.view.addSubview(rightButton)
    }
    
    public func addRightButtons(image: [UIImage?], target: Any?, selector: [Selector?]) {
        let y: CGFloat = Device.isXDevice ? 60 : 35
        
        self.view.viewWithTag(20194)?.removeFromSuperview()
        
        let stackView = UIView()
        var x: CGFloat = 0
        
        for i in 0...image.count - 1 {
            let rightButton = UIButton(type: .system)
            rightButton.tintColor = UIColor.white
            rightButton.setImage(image[i], for: .normal)
            rightButton.contentHorizontalAlignment = .right
            rightButton.addTarget(target, action: selector[i]!, for: .touchUpInside)
            rightButton.frame = CGRect(x: x, y: 0, width: 40, height: 40)
            stackView.addSubview(rightButton)
            
            x = x + 45
        }
        
        stackView.frame = CGRect(x: UIScreen.main.bounds.size.width - x - 15, y: y, width: x, height: 40)
        
        self.view.addSubview(stackView)
    }
    
    public func enableRightButton(enabled: Bool) {
        if let button = view.viewWithTag(20191) as? UIButton {
            button.isEnabled = enabled
        }
    }
    
    public func removeLeftButton() {
        self.view.viewWithTag(13)?.removeFromSuperview()
        self.view.viewWithTag(12)?.removeFromSuperview()
    }
    
    public func removeRightButton() {
        self.view.viewWithTag(20191)?.removeFromSuperview()
    }
    
    // MARK: - Feedback
    
    public func showRateDialog() {
        addBlur()
        
        let logoView = UIImageView(frame: CGRect(x: 10, y: 15, width: 40, height: 28))
        logoView.image = RateLogo()
        
        let view = UIView(frame: CGRect(x: 95, y: 15, width: 60, height: 60))
        view.backgroundColor = UIColor(red: 11 / 255, green: 22 / 255, blue: 36 / 255, alpha: 1)
        view.layer.cornerRadius = 8
        view.addSubview(logoView)
        
        var title = Localizable.shared.strings.rate_title
        title = title.replacingOccurrences(of: "\n", with: "")
        title = "\n\n\n" + title
        
        let text = Localizable.shared.strings.rate_text
        
        var h: CGFloat = 285
        if Settings.sharedManager().language == "vi" {
            view.frame = CGRect(x: 95, y: 10, width: 60, height: 60)
            h = 300
        }
        else if Settings.sharedManager().language == "ko" || Settings.sharedManager().language == "fi" {
            title = "\n" + title
            h = 300
        }
        
        let showAlert = UIAlertController(title: title, message: text, preferredStyle: .alert)
        showAlert.view.addSubview(view)
        
        let height = NSLayoutConstraint(item: showAlert.view!, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: h)
        let width = NSLayoutConstraint(item: showAlert.view!, attribute: .width, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: 250)
        showAlert.view.addConstraint(height)
        showAlert.view.addConstraint(width)
        
        showAlert.addAction(UIAlertAction(title: Localizable.shared.strings.rate_app, style: .default, handler: { _ in
            self.removeBlur()
            AppStoreReviewManager.openAppStoreRatingPage()
        }))
        showAlert.addAction(UIAlertAction(title: Localizable.shared.strings.feedback, style: .default, handler: { _ in
            self.removeBlur()

            AppStoreReviewManager.resetRating()
            
            self.writeFeedback()
        }))
        showAlert.addAction(UIAlertAction(title: Localizable.shared.strings.not_now, style: .default, handler: { _ in
            self.removeBlur()

            AppStoreReviewManager.resetRating()
        }))
        
        if Settings.sharedManager().isDarkMode {
            showAlert.setBackgroundColor(color: UIColor.main.twilightBlue2)
            showAlert.setValue(NSAttributedString(string: title, attributes: [
                NSAttributedString.Key.font: UIFont.boldSystemFont(ofSize: 15),
                NSAttributedString.Key.foregroundColor: UIColor.white
            ]), forKey: "attributedTitle")
            showAlert.setValue(NSAttributedString(string: text, attributes: [
                NSAttributedString.Key.font: UIFont.systemFont(ofSize: 15),
                NSAttributedString.Key.foregroundColor: UIColor.white
            ]), forKey: "attributedMessage")
        }
        
        self.present(showAlert, animated: true, completion: nil)
    }
    
    public func writeFeedback() {
        if MFMailComposeViewController.canSendMail() {
            let mailComposer = MFMailComposeViewController()
            mailComposer.mailComposeDelegate = self
            mailComposer.setToRecipients([Localizable.shared.strings.support_email])
            mailComposer.setSubject(Localizable.shared.strings.ios_feedback)
            present(mailComposer, animated: true, completion: nil)
        }
        else {
            UIApplication.shared.open(URL(string: Localizable.shared.strings.support_email_mailto)!, options: [:]) { _ in
            }
        }
    }
    
    // MARK: - Security
    
    @objc public func onHideAmounts() {
        if !Settings.sharedManager().isHideAmounts {
            if Settings.sharedManager().isAskForHideAmounts {
                self.confirmAlert(title: Localizable.shared.strings.activate_security_title, message: Localizable.shared.strings.activate_security_text, cancelTitle: Localizable.shared.strings.cancel, confirmTitle: Localizable.shared.strings.activate, cancelHandler: { _ in
                    
                }) { _ in
                    Settings.sharedManager().isAskForHideAmounts = false
                    Settings.sharedManager().isHideAmounts = !Settings.sharedManager().isHideAmounts
                }
            }
            else {
                Settings.sharedManager().isHideAmounts = !Settings.sharedManager().isHideAmounts
            }
        }
        else {
            Settings.sharedManager().isHideAmounts = !Settings.sharedManager().isHideAmounts
        }
    }
}

// MARK: - MFMailComposeViewControllerDelegate

extension BaseViewController: MFMailComposeViewControllerDelegate {
    func mailComposeController(_ didFinishWithcontroller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
        didFinishWithcontroller.dismiss(animated: true) {}
    }
}

// MARK: - Dismiss Swipe

extension BaseViewController {
    public func addSwipeToDismiss() {
        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(self.onPan(_:)))
        self.view.addGestureRecognizer(panGesture)
    }
    
    private func slideViewVerticallyTo(_ y: CGFloat) {
        let alpha = (self.view.frame.size.height - y) / self.view.frame.size.height
        
        if let visualView = self.view.subviews.first as? UIVisualEffectView {
            visualView.alpha = alpha
        }
        else {
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
        case .ended:
            let translation = panGesture.translation(in: view)
            let velocity = panGesture.velocity(in: view)
            let closing = (translation.y > self.view.frame.size.height * self.minimumScreenRatioToHide) ||
                (velocity.y > self.minimumVelocityToHide)
            
            if closing {
                UIView.animate(withDuration: self.animationDuration, animations: {
                    self.slideViewVerticallyTo(self.view.frame.size.height)
                }, completion: { isCompleted in
                    if isCompleted {
                        self.dismiss(animated: false, completion: nil)
                    }
                })
            }
            else {
                UIView.animate(withDuration: self.animationDuration, animations: {
                    self.slideViewVerticallyTo(0)
                })
            }
        default:
            UIView.animate(withDuration: self.animationDuration, animations: {
                self.slideViewVerticallyTo(0)
            })
        }
    }
}
