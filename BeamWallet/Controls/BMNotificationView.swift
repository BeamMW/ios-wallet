//
// BMNotificationView.swift
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

import UIKit
import AVFoundation

protocol BMNotificationViewDelegate: AnyObject {
    func onOpenNotification(id: String)
}

class BMNotificationView: UIView {
    private static var notificationView: BMNotificationView?

    private var id:String!
    private var lastLocation = CGPoint.zero
    private var timer: Timer?
    private var hideDuration: TimeInterval = 7
    private let defaultY: CGFloat = Device.isXDevice ? 45 : 25
    private var defaultCenterY: CGFloat = 0

    weak var delegate: BMNotificationViewDelegate?

    private static func showNews (notification: BMNotification, delegate:BMNotificationViewDelegate) {
        DispatchQueue.main.async {
            let detail = NSMutableAttributedString(string: Localizable.shared.strings.new_notifications_text)
            detail.addAttribute(NSAttributedString.Key.font, value: BoldFont(size: 14) , range: NSRange(location: 0, length: Localizable.shared.strings.new_notifications_text.count))
            let view = BMNotificationView(title: Localizable.shared.strings.new_notifications_title, detail: detail, icon: IconBeam(), id: NotificationManager.notificationID, delegate: delegate)
            view.display()
        }
    }
    
    private static func showAddress (notification: BMNotification, delegate:BMNotificationViewDelegate) {
        DispatchQueue.main.async {
            let view = BMNotificationView(title: Localizable.shared.strings.address_expired_notif, detail: nil, icon: IconNotifictionsExpired()?.maskWithColor(color: UIColor.main.marineOriginal), id: notification.pId, delegate: delegate)
            view.display()
        }
    }
    
    private static func showVersion (notification: BMNotification, delegate:BMNotificationViewDelegate) {
        DispatchQueue.main.async {
            let detail = NSMutableAttributedString(string: Localizable.shared.strings.new_version_available_notif_detail)
            detail.addAttribute(NSAttributedString.Key.font, value: BoldFont(size: 14) , range: NSRange(location: 0, length: Localizable.shared.strings.new_version_available_notif_detail.count))            
            let view = BMNotificationView(title: Localizable.shared.strings.new_version_available_notif_title, detail: detail, icon: IconNotifictionsUpdate()?.maskWithColor(color: UIColor.main.marineOriginal), id: NotificationManager.versionID, delegate: delegate)
            view.display()
        }
    }
    
    static func showTransaction (transaction: BMTransaction, delegate:BMNotificationViewDelegate) {
        DispatchQueue.main.async {
            var icon: UIImage?
            var title: String?
            var detail: NSMutableAttributedString?
            
            if transaction.isIncome {
                if (transaction.enumStatus == BMTransactionStatusRegistering || transaction.enumStatus == BMTransactionStatusPending) && !transaction.isSelf {
                    icon = UIImage.init(named: "iconNotifictionsReceived")
                    title = Localizable.shared.strings.new_transaction
                    let beam = Settings.sharedManager().isHideAmounts ? String.empty() : String.currency(value: transaction.realAmount)
                    detail = Localizable.shared.strings.transaction_receiving_notif_body(beam: beam, address: transaction.senderAddress, failed: false)
                }
                else if transaction.isFailed() || transaction.isExpired() || transaction.isCancelled() {
                    icon = UIImage.init(named: "iconNotifictionsFailedReceived")
                    title = Localizable.shared.strings.buy_transaction_failed_title
                    let beam = Settings.sharedManager().isHideAmounts ? String.empty() : String.currency(value: transaction.realAmount)
                    detail = Localizable.shared.strings.muttableTransaction_received_notif_body(beam: beam, address: transaction.senderAddress, failed: true)
                }
                else {
                    icon = UIImage.init(named: "iconNotifictionsReceived")
                    title = Localizable.shared.strings.transaction_received
                    let beam = Settings.sharedManager().isHideAmounts ? String.empty() : String.currency(value: transaction.realAmount)
                    detail = Localizable.shared.strings.muttableTransaction_received_notif_body(beam: beam, address: transaction.senderAddress, failed: false)
                }
            }
            else {
                if transaction.isFailed() || transaction.isExpired() || transaction.isCancelled() {
                    icon = UIImage.init(named: "iconNotifictionsFailed")
                    title = Localizable.shared.strings.buy_transaction_failed_title
                    let beam = Settings.sharedManager().isHideAmounts ? String.empty() : String.currency(value: transaction.realAmount)
                    detail = Localizable.shared.strings.muttableTransaction_sent_notif_body(beam:beam , address: transaction.receiverAddress, failed: true)
                }
                else {
                    icon = UIImage.init(named: "iconNotifictionsSent")
                    title = Localizable.shared.strings.transaction_sent
                    let beam = Settings.sharedManager().isHideAmounts ? String.empty() : String.currency(value: transaction.realAmount)
                    detail = Localizable.shared.strings.muttableTransaction_sent_notif_body(beam: beam, address: transaction.receiverAddress, failed: false)
                }
            }
            
            let view = BMNotificationView(title: title, detail: detail, icon: icon, id: transaction.id, delegate: delegate)
            view.display()
        }
    }
    
    static func showTransaction (notification: BMNotification, delegate:BMNotificationViewDelegate) {
        DispatchQueue.main.async {
            if let transaction = AppModel.sharedManager().transaction(byId: notification.pId) {
                var icon: UIImage?
                var title: String?
                var detail: NSMutableAttributedString?
                
                if transaction.isIncome {
                    if transaction.isFailed() || transaction.isExpired() || transaction.isCancelled() {
                        icon = UIImage.init(named: "iconNotifictionsFailedReceived")
                        title = Localizable.shared.strings.buy_transaction_failed_title
                        let beam = Settings.sharedManager().isHideAmounts ? String.empty() : String.currency(value: transaction.realAmount)
                        detail = Localizable.shared.strings.muttableTransaction_received_notif_body(beam: beam, address: transaction.senderAddress, failed: true)
                    }
                    else {
                        icon = UIImage.init(named: "iconNotifictionsReceived")
                        title = Localizable.shared.strings.transaction_received
                        let beam = Settings.sharedManager().isHideAmounts ? String.empty() : String.currency(value: transaction.realAmount)
                        detail = Localizable.shared.strings.muttableTransaction_received_notif_body(beam: beam, address: transaction.senderAddress, failed: false)
                    }
                }
                else {
                    if transaction.isFailed() || transaction.isExpired() || transaction.isCancelled() {
                        icon = UIImage.init(named: "iconNotifictionsFailed")
                        title = Localizable.shared.strings.buy_transaction_failed_title
                        let beam = Settings.sharedManager().isHideAmounts ? String.empty() : String.currency(value: transaction.realAmount)
                        detail = Localizable.shared.strings.muttableTransaction_sent_notif_body(beam:beam , address: transaction.receiverAddress, failed: true)
                    }
                    else {
                        icon = UIImage.init(named: "iconNotifictionsSent")
                        title = Localizable.shared.strings.transaction_sent
                        let beam = Settings.sharedManager().isHideAmounts ? String.empty() : String.currency(value: transaction.realAmount)
                        detail = Localizable.shared.strings.muttableTransaction_sent_notif_body(beam: beam, address: transaction.receiverAddress, failed: false)
                    }
                }
                
                let view = BMNotificationView(title: title, detail: detail, icon: icon, id: transaction.id, delegate: delegate)
                view.display()
            }
        }
    }
    
    public static func show (notification: BMNotification, delegate:BMNotificationViewDelegate) {
        if(BMNotificationView.notificationView == nil) {
            if(notification.type == ADDRESS) {
                showAddress(notification: notification, delegate: delegate)
            }
            else if (notification.type == TRANSACTION) {
                showTransaction(notification: notification, delegate: delegate)
            }
            else if (notification.type == VERSION) {
                showVersion(notification: notification, delegate: delegate)
            }
            else if (notification.type == NEWS) {
                showNews(notification: notification, delegate: delegate)
            }
        }
    }
    
    public static func show (title: String?, detail: NSMutableAttributedString?, icon: UIImage?, id: String, delegate:BMNotificationViewDelegate) {
        DispatchQueue.main.async {
            if(BMNotificationView.notificationView == nil) {
                let view = BMNotificationView(title: title, detail: detail, icon: icon, id: id, delegate: delegate)
                view.display()
            }
        }
    }
    
    fileprivate init(title: String?, detail: NSMutableAttributedString?, icon: UIImage?, id: String, delegate:BMNotificationViewDelegate) {
        
        super.init(frame: CGRect.zero)
        
        self.delegate = delegate
        self.id = id
        self.alpha = 0
        
        let width = UIScreen.main.bounds.width - 30
        let labelWidth = width - 30
        
        let iconView = UIImageView(frame: CGRect(x: 15, y: 15, width: 20, height: 20))
        iconView.image = icon
        
        let titleLabel = UILabel(frame: CGRect(x: 45, y: 15, width: labelWidth - 45, height: 20))
        titleLabel.font = BoldFont(size: 14)
        titleLabel.textColor = UIColor.main.marineOriginal
        titleLabel.text = title
        
        let detailLabel = UILabel(frame: CGRect(x: 15, y: 45, width: labelWidth, height: 0))
        detailLabel.font = RegularFont(size: 14)
        detailLabel.attributedText = detail
        detailLabel.numberOfLines = 0
        detailLabel.textColor = UIColor.main.marineOriginal
        detailLabel.sizeToFit()

        let height = detailLabel.frame.size.height + detailLabel.frame.origin.y + (detail != nil ? 15 : 5)
        let frame = CGRect(x: 15, y: -height, width: width, height: height)
        self.backgroundColor = UIColor.white
        self.frame = frame
        self.layer.cornerRadius = 8
        self.layer.masksToBounds = false
        
        self.addSubview(iconView)
        self.addSubview(titleLabel)
        self.addSubview(detailLabel)
        self.frame = frame
        
        let app = UIApplication.shared.delegate as! AppDelegate
        app.window?.addSubview(self)
        
        self.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(onTap)))
        self.addGestureRecognizer(UIPanGestureRecognizer(target: self, action: #selector(onPan)))

        BMNotificationView.notificationView = self;
    }
    
    fileprivate func display() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            AudioServicesPlayAlertSound(SystemSoundID(1003))
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            
            UIView.animate(withDuration: 0.6,
                           delay: 0.0,
                           usingSpringWithDamping: 0.8,
                           initialSpringVelocity: 0,
                           options: .curveEaseOut,
                           animations: {
                            self.alpha = 1
                            self.y = self.defaultY
            }, completion: { _ in
                self.defaultCenterY = self.center.y
                self.timer = Timer.scheduledTimer(timeInterval: self.hideDuration, target: self, selector: #selector(self.hideAction(_:)), userInfo: nil, repeats: false)
            })
        }
    }
    
    fileprivate func hide() {
        UIView.animate(withDuration: 0.6,
                       delay: 0.0,
                       usingSpringWithDamping: 0.8,
                       initialSpringVelocity: 0,
                       options: .curveEaseOut,
                       animations: {
                        self.alpha = 0
                        self.y = -self.h
        }, completion: { _ in
            self.removeFromSuperview()
            BMNotificationView.notificationView = nil
        })
    }
    
    @objc private func hideAction(_ sender: Timer) {
        hide()
    }
    
    required init?(coder: NSCoder) {
        fatalError(Localizable.shared.strings.fatalInitCoderError)
    }
    
    @objc private func onTap() {
        self.delegate?.onOpenNotification(id: self.id)
        timer?.invalidate()
        timer = nil
        hide()
    }
    
    @objc private func onPan(gesture: UIPanGestureRecognizer) {
        if gesture.state == .ended || gesture.state == .cancelled {
            if self.center.y < (defaultCenterY - 15) {
                self.hide()
            }
            else {
                var center = self.center
                center.y = defaultCenterY
                self.center = center
                
                timer = Timer.scheduledTimer(timeInterval: self.hideDuration, target: self, selector: #selector(self.hideAction(_:)), userInfo: nil, repeats: false)
            }
        }
        else {
            timer?.invalidate()
            timer = nil
            
            guard let gestureView = gesture.view else {
                return
            }
            
            let translation = gesture.translation(in: self)
            let finalPoint = CGPoint(
                x: gestureView.center.x,
                y: gestureView.center.y + translation.y
            )
            
            if finalPoint.y >= defaultCenterY {
                return
            }
            
            gestureView.center = finalPoint
            gesture.setTranslation(.zero, in: self)
        }
    }
}
