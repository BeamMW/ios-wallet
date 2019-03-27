//
//  NotificationManager.swift
//  BeamWallet
//
//  Created by Denis on 3/22/19.
//  Copyright © 2019 Denis. All rights reserved.
//

import Foundation
import UserNotifications

class NotificationManager : NSObject {
    
    static let sharedManager = NotificationManager()
    public var clickedTransaction = ""
    
    public func requestPermissions() {
        let options: UNAuthorizationOptions = [.alert, .sound, .badge]
        
        let notificationCenter = UNUserNotificationCenter.current()
        
        notificationCenter.delegate = self
        notificationCenter.requestAuthorization(options: options) {
            (didAllow, error) in
            if !didAllow {
                print("User has declined notifications")
            }
        }
    }
    
    public func clearNotifications() {
        UIApplication.shared.applicationIconBadgeNumber = 0

        let notificationCenter = UNUserNotificationCenter.current()
        notificationCenter.removeAllDeliveredNotifications()
        notificationCenter.removeAllPendingNotificationRequests()
    }
    
    public func scheduleNotification(transaction:BMTransaction){
        if transaction.enumStatus == BMTransactionStatusRegistering || transaction.enumStatus == BMTransactionStatusPending {
            NotificationManager.sharedManager.scheduleNotification(title: "New transaction", body: "You receiving \(String.currency(value: transaction.realAmount)) BEAM. Сlick to view details", id:transaction.id)
        }
        else if transaction.enumStatus == BMTransactionStatusCompleted {
            NotificationManager.sharedManager.scheduleNotification(title: "Transaction update", body: "You received \(String.currency(value: transaction.realAmount)) BEAM. Сlick to view details", id:transaction.id)
        }
        else if transaction.enumStatus == BMTransactionStatusFailed {
            NotificationManager.sharedManager.scheduleNotification(title: "Transaction failed", body: "You failed to receiving \(String.currency(value: transaction.realAmount)) BEAM. Сlick to view details", id:transaction.id)
        }
    }
    
    public func scheduleNotification(title:String, body: String, id:String = "wallet") {
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = UNNotificationSound.default
        content.badge = 1
        
        let identifier = id
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
        
        let notificationCenter = UNUserNotificationCenter.current()
        notificationCenter.add(request) { (error) in
            if let error = error {
                print("Error \(error.localizedDescription)")
            }
        }
    }
}

extension NotificationManager : UNUserNotificationCenterDelegate {
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                didReceive response: UNNotificationResponse,
                                withCompletionHandler completionHandler: @escaping () -> Void) {
        
        if AppModel.sharedManager().isLoggedin {
            clickedTransaction = ""
        }
        else{
            clickedTransaction = response.notification.request.identifier
        }
        
        if AppModel.sharedManager().isLoggedin {
            if let rootVC = UIApplication.getTopMostViewController() {
                if rootVC is TransactionViewController {
                    rootVC.navigationController?.popViewController(animated: false)
                }
           
                if let transactions = AppModel.sharedManager().transactions as? [BMTransaction] {
                    if let transaction = transactions.first(where: { $0.id == response.notification.request.identifier }) {
                        let vc = TransactionViewController()
                        vc.hidesBottomBarWhenPushed = true
                        vc.configure(with: transaction)
                        rootVC.pushViewController(vc: vc)
                    }
                }
            }
        }
        
        completionHandler()
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                willPresent notification: UNNotification,
                                withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.alert, .sound])
    }
}
