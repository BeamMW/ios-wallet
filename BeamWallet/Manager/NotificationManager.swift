//
// NotificationManager.swift
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
import UserNotifications

class NotificationManager : NSObject {
    
    public static let notificationID = "notificationID"
    public static let addressesID = "addressesID"
    public static let versionID = "versionID"

    static let sharedManager = NotificationManager()
    
    public var clickedTransaction = ""
    public var clickedAddress = ""
    
    override init() {
        super.init()
        
        let notificationCenter = UNUserNotificationCenter.current()
        notificationCenter.delegate = self
        
        AppModel.sharedManager().addDelegate(self)
    }
    
    //MARK: - Registration
    
    public func isApnsEnabled(completion: @escaping ((Bool) -> Void)) {
        let current = UNUserNotificationCenter.current()
        
        current.getNotificationSettings(completionHandler: { (settings) in
            if settings.authorizationStatus == .notDetermined {
                completion(false)
            } else if settings.authorizationStatus == .denied {
                completion(false)
            } else if settings.authorizationStatus == .authorized {
                completion(true)
            }
        })
    }
    
    public func requestPermissions() {
        let options: UNAuthorizationOptions = [.alert, .sound, .badge]
        
        let notificationCenter = UNUserNotificationCenter.current()
        notificationCenter.requestAuthorization(options: options) {
            (didAllow, error) in
        }
        
        UIApplication.shared.registerForRemoteNotifications()
    }
    
    public func clearNotifications() {
        UIApplication.shared.applicationIconBadgeNumber = 0
        
        let notificationCenter = UNUserNotificationCenter.current()
        notificationCenter.removeAllDeliveredNotifications()
        notificationCenter.removeAllPendingNotificationRequests()
    }
    
    
    //MARK: - Send
    
    public func scheduleNotification(transaction: BMTransaction){
        if transaction.enumStatus == BMTransactionStatusRegistering || transaction.enumStatus == BMTransactionStatusPending {
            BMNotificationView.showTransaction(transaction: transaction, delegate: self)
        }
    }
        
    public func scheduleNotification(title:String, body: String, id:String = "wallet") {
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = UNNotificationSound.default
        content.badge = 1
        content.userInfo = ["local":true]
        
        let identifier = id
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
        
        let notificationCenter = UNUserNotificationCenter.current()
        notificationCenter.add(request) { (error) in
            if let error = error {
                print("Error \(error.localizedDescription)")
            }
        }
    }
    
    public func didReceiveNotification(id:String) {
        
    }
}

extension NotificationManager : UNUserNotificationCenterDelegate {
    
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                didReceive response: UNNotificationResponse,
                                withCompletionHandler completionHandler: @escaping () -> Void) {
        completionHandler()
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                willPresent notification: UNNotification,
                                withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.alert, .sound])
    }
}

extension NotificationManager: WalletModelDelegate {
    func onNotificationsChanged() {
        
        let count = AppModel.sharedManager().getUnsendedNotificationsCount()
        
        if count > 1 && AppModel.sharedManager().allUnsendedIsAddresses() {
            let title = Localizable.shared.strings.addresses_expired_notif(count: Int(count))
            let id = NotificationManager.addressesID
            BMNotificationView.show(title: title, detail: nil, icon: IconNotifictionsExpired()?.maskWithColor(color: UIColor.main.marine), id: id, delegate: self)
        }
        else if count > 1  {
            let attributedText = NSMutableAttributedString(string: Localizable.shared.strings.new_notifications_text)
            attributedText.addAttribute(NSAttributedString.Key.font, value: BoldFont(size: 14) , range: NSRange(location: 0, length: Localizable.shared.strings.new_notifications_text.count))
            BMNotificationView.show(title: Localizable.shared.strings.new_notifications_title, detail: attributedText, icon: IconBeam(), id: NotificationManager.notificationID, delegate: self)
        }
        else if count == 1 {
            if let notification = AppModel.sharedManager().getUnsendedNotification() {
                BMNotificationView.show(notification: notification, delegate: self)
            }
        }
        
        AppModel.sharedManager().sendNotifications()
    }
}

extension NotificationManager: BMNotificationViewDelegate {
    
    func onOpenNotification(id: String) {
        if(AppModel.sharedManager().isLoggedin && !BMLockScreen.shared.isScreenLocked) {
            if(id == NotificationManager.notificationID || id == NotificationManager.addressesID) {
                if let vc = UIApplication.getTopMostViewController() {
                    var notificationFound = false
                    for v in vc.navigationController?.viewControllers ?? [] {
                        if v is NotificationsViewController {
                            notificationFound = true
                            vc.navigationController?.popToViewController(v, animated: true)
                            break
                        }
                    }
                    if !notificationFound {
                        vc.navigationController?.pushViewController(NotificationsViewController(), animated: true)
                    }
                }
            }
            else if(id == NotificationManager.versionID) {
                if let vc = UIApplication.getTopMostViewController() {
                    var notificationFound = false
                    for v in vc.navigationController?.viewControllers ?? [] {
                        if v is NotificationVersionViewController {
                            notificationFound = true
                            vc.navigationController?.popToViewController(v, animated: true)
                            break
                        }
                    }
                    if !notificationFound {
                        if let notification = AppModel.sharedManager().getLastVersionNotification() {
                            vc.navigationController?.pushViewController(NotificationVersionViewController(version: notification.pId), animated: true)
                        }
                    }
                }
            }
            else {
                if let transaction = AppModel.sharedManager().transaction(byId: id) {
                    if let vc = UIApplication.getTopMostViewController() {
                        var found = false
                        for v in vc.navigationController?.viewControllers ?? [] {
                            if let trVC = v as? TransactionViewController {
                                if trVC.transactionId == transaction.id {
                                    found = true
                                    vc.navigationController?.popToViewController(trVC, animated: true)
                                    break
                                }
                            }
                        }
                        if !found {
                            vc.navigationController?.pushViewController(TransactionViewController(transaction: transaction), animated: true)
                        }
                    }
                    AppModel.sharedManager().readNotification(byObject: id)
                }
                else if let address = AppModel.sharedManager().findAddress(byID: id) {
                    if let vc = UIApplication.getTopMostViewController() {
                        var found = false
                        for v in vc.navigationController?.viewControllers ?? [] {
                            if let addVC = v as? AddressViewController {
                                if addVC.walletId == address.walletId {
                                    found = true
                                    vc.navigationController?.popToViewController(addVC, animated: true)
                                    break
                                }
                            }
                        }
                        if !found {
                            vc.navigationController?.pushViewController(AddressViewController(address: address), animated: true)
                        }
                    }
                    AppModel.sharedManager().readNotification(byObject: id)
                }
            }
        }
    }
}

