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
        
    static var disableApns = true
    
    static let sharedManager = NotificationManager()
    
    public var clickedTransaction = ""
    
    public func fcmToken() -> String? {
        return nil //Messaging.messaging().fcmToken
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
    
    public func scheduleNotification(transaction:BMTransaction){
        if transaction.enumStatus == BMTransactionStatusRegistering || transaction.enumStatus == BMTransactionStatusPending {
            NotificationManager.sharedManager.scheduleNotification(title: Localizable.shared.strings.new_transaction, body: Localizable.shared.strings.click_to_receive, id:transaction.id)
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
