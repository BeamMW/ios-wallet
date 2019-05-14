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
import FirebaseMessaging

protocol NotificationManagerDelegate: AnyObject {
    func onTransactionStatus(succes:NotificationManager.TransactionStatus, status:String)
}

class NotificationManager : NSObject {
    
    weak var delegate: NotificationManagerDelegate?

    static var disableApns = true
    
    //MARK: Notif Status
    
    enum MessageType: String {
        case transaction = "transaction_status"
        case push = "push_status"
    }
    
    enum MessageStatus: Int {
        case in_progress = 1
        case done = 2
        case failed = 3
    }
    
    enum TransactionStatus: String {
        case sent = "sent"
        case failed = "failed"
        case sending = "sending"
    }
    
    //MARK: - Actions
    
    private struct NotificationTransaction {
        static let id = "TRANSACTION_INVITATION"

        struct Action {
            static let accept = "Accept"
            static let decline = "Decline"
        }
    }
    
    private var sendedTransactions = [String]()
    
    //MARK: - Transaction
    
    private struct TransactionData {
        public var amount:Double = 0.0
        public var fee:Double = 0.0
        public var comment = ""
        public var address = ""
        public var id = ""
        public var confirmed = false

        static func fromUserInfo(data:[AnyHashable : Any]) -> TransactionData? {
            if let amount = data["amount"] as? String,
                let toAddress = data["to"] as? String, let id = data["message_id"] as? String {
                
                var transaction = TransactionData()
                transaction.amount = Double(amount)!
                transaction.address = toAddress
                transaction.comment = "automatic transaction"
                transaction.id = id
                
                if let fee = data["fee"] as? String {
                    transaction.fee = Double(fee)!
                }
                else{
                    transaction.fee = 10
                }
                
                transaction.confirmed = false
                
                return transaction
            }
            
            return nil
        }
    }
    
    private var backgroundTask: UIBackgroundTaskIdentifier = .invalid
    private var transaction:TransactionData?

    static let sharedManager = NotificationManager()
    
    public var clickedTransaction = ""

    public func fcmToken() -> String? {
       return Messaging.messaging().fcmToken
    }
    
    //MARK: - Tasks
    
    
    private func registerBackgroundTask() {
        backgroundTask = UIApplication.shared.beginBackgroundTask { [weak self] in
            self?.endBackgroundTask()
        }
    }
    
    private func endBackgroundTask() {
        UIApplication.shared.endBackgroundTask(backgroundTask)
        backgroundTask = .invalid
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
        if !NotificationManager.disableApns {
            
            AppModel.sharedManager().addDelegate(self)
            
            Messaging.messaging().delegate = self
        }
      

        let options: UNAuthorizationOptions = [.alert, .sound, .badge]
        
        let notificationCenter = UNUserNotificationCenter.current()
        
        notificationCenter.delegate = self
        notificationCenter.requestAuthorization(options: options) {
            (didAllow, error) in
            if didAllow {
                self.createActionCategories()
            }
        }
        
        UIApplication.shared.registerForRemoteNotifications()
    }
    
    private func createActionCategories() {
//        let acceptAction = UNNotificationAction(identifier: NotificationTransaction.Action.accept,
//                                                title: NotificationTransaction.Action.accept,
//                                                options: [])
//        let declineAction = UNNotificationAction(identifier: NotificationTransaction.Action.decline,
//                                                 title: NotificationTransaction.Action.decline,
//                                                 options: [])
        let сategory =
            UNNotificationCategory(identifier: NotificationTransaction.id,
                                   actions: [],
                                   intentIdentifiers: [],
                                   hiddenPreviewsBodyPlaceholder: "",
                                   options: .customDismissAction)

        let notificationCenter = UNUserNotificationCenter.current()
        notificationCenter.setNotificationCategories([сategory])
    }
    
    
    public func subscribeToTopic(topic:String){
        if !NotificationManager.disableApns {
            Messaging.messaging().subscribe(toTopic: topic)
        }
    }

    public func unSubscribeToTopic(topic:String){
        if !NotificationManager.disableApns {
            Messaging.messaging().unsubscribe(fromTopic: topic)
        }
    }
    
    public func subscribeToTopics(addresses:[BMAddress]?) {
        if let walletAddresses = addresses {
            for address in walletAddresses {
                if address.isExpired() {
                    NotificationManager.sharedManager.unSubscribeToTopic(topic: address.walletId)
                }
                else{
                    NotificationManager.sharedManager.subscribeToTopic(topic: address.walletId)
                }
            }
        }
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
            NotificationManager.sharedManager.scheduleNotification(title: "New transaction", body: "Сlick to view details", id:transaction.id)
        }
        else if transaction.enumStatus == BMTransactionStatusCompleted {
            NotificationManager.sharedManager.scheduleNotification(title: "Transaction update", body: "Сlick to view details", id:transaction.id)
        }
        else if transaction.enumStatus == BMTransactionStatusFailed {
            NotificationManager.sharedManager.scheduleNotification(title: "Transaction failed", body: "Сlick to view details", id:transaction.id)
        }
    }
    
    public func sendFirebaseNotification(topic:String) {
        if NotificationManager.disableApns {
            return
        }
        
        if AppModel.sharedManager().isMyAddress(topic) {
            return
        }
        
        let key = "key=AAAAQDKSPzM:APA91bFitbu15xf3jeStYO3nMNPwdleBGqsGZ49Uy6SnspPh9yoQ9M6dAYXkjrZzh9tMAxK2wfqx-kzizSjCu-wyuVkPRNJKb2VHgj4dAJq4ZUMzXOWWgty1DQCVwFukbaAnqN5b_TTB"

        //"content_available":true
        let notification: [String:Any] = ["title":"New transaction","body":"Сlick to confirm transaction","sound":"default"]
        let parameters: [String: Any] = ["to": "/topics/\(topic)", "priority":10,"notification": notification]
        
        let url = URL(string: "https://fcm.googleapis.com/fcm/send")!

        let session = URLSession.shared

        var request = URLRequest(url: url)
        request.httpMethod = "POST"

        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: parameters, options: .prettyPrinted)

        } catch let error {
            print(error.localizedDescription)
        }

        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue(key, forHTTPHeaderField: "Authorization")

        let task = session.dataTask(with: request, completionHandler: { data, response, error in

            guard error == nil else {
                return
            }

            guard let data = data else {
                return
            }

            do {
                if let json = try JSONSerialization.jsonObject(with: data, options: .mutableContainers) as? [String: Any] {
                    print(json)
                }

            } catch let error {
                print(error.localizedDescription)
            }
        })
        task.resume()
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
        TGBotManager.updateNotificationStatus(id: id, status: .done, type: .push) { (_) in
            
        }
    }
    
    public func cancelSendAutomaticMoney(data:[AnyHashable : Any]) {
        if let transaction = TransactionData.fromUserInfo(data: data) {
            
            didReceiveNotification(id: transaction.id)
            
            TGBotManager.updateTransactionStatus(id: transaction.id, status: .failed, type: .transaction, completion: { (_ ) in
                
            })
        }
    }
    
    public func sendAutomaticMoney(data:[AnyHashable : Any]) -> Bool
    {
        self.transaction = TransactionData.fromUserInfo(data: data)
        
        if self.transaction != nil {
            
            self.transaction?.confirmed = true
            
            didReceiveNotification(id: self.transaction!.id)
            
            openWallet()
            
            return true
        }
        
        self.delegate?.onTransactionStatus(succes: .failed, status: "Invalid parameters")
        
        return false
    }
    
    private func openWallet() {
        if let password = KeychainManager.getPassword() {
            
            if UIApplication.shared.applicationState != .active {
                registerBackgroundTask()
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 26) {
                    self.endBackgroundTask()
                }
            }
            
            AppModel.sharedManager().addDelegate(self)
            
            self.delegate?.onTransactionStatus(succes: .sending, status: "Loading wallet")

//            if(AppModel.sharedManager().isLoggedin) {
//                AppModel.sharedManager().refreshAllInfo()
//            }
//            else{
                AppModel.sharedManager().openWallet(password)
           // }
        }
    }
    
    public func displayConfirmAlert() {
        #if EXTENSION
            print("ignore")
        #else
        if let transaction = self.transaction, AppModel.sharedManager().isLoggedin == true {
            if let vc = UIApplication.getTopMostViewController() {
                let alert = UIAlertController(title: "Confirm transaction", message: "You are trying to send \(String.currency(value: transaction.amount)) BEAM to address \(transaction.address)", preferredStyle: .alert)
                
                let ok = UIAlertAction(title: "Confirm", style: .default, handler: { action in
                    self.transaction?.confirmed = true
                    self.openWallet()
                })
                
                let cancel = UIAlertAction(title: "Cancel", style: .default, handler: { action in
                    
                    TGBotManager.updateTransactionStatus(id: transaction.id, status: .failed, type: .transaction, completion: { (_ ) in
                        
                    })
                    
                    self.transaction = nil
                })
                alert.addAction(cancel)
                alert.addAction(ok)
                
                vc.present(alert, animated: true, completion: nil)
            }
        }
        else if let _ = self.transaction, AppModel.sharedManager().isLoggedin == false {
            if let vc = UIApplication.getTopMostViewController() {
                vc.alert(title: "Confirm transaction", message: "Please open your wallet to confirm transaction") { (_ ) in
                    if let passVC = UIApplication.getTopMostViewController() as? EnterWalletPasswordViewController {
                        passVC.biometricAuthorization()
                    }
                }
            }
        }
        #endif
    }
}

//MARK: - Notifications Delegate

extension NotificationManager : UNUserNotificationCenterDelegate {
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                didReceive response: UNNotificationResponse,
                                withCompletionHandler completionHandler: @escaping () -> Void) {
        
        if response.notification.request.content.categoryIdentifier ==
            NotificationTransaction.id {
            
            let data = response.notification.request.content.userInfo
            
            self.transaction = TransactionData.fromUserInfo(data: data)
            
            switch response.actionIdentifier {
            case NotificationTransaction.Action.accept:
                
                if let transaction = self.transaction {
                    didReceiveNotification(id: transaction.id)
                }
                
                self.transaction?.confirmed = true
                
                openWallet()
                
                break
            case UNNotificationDefaultActionIdentifier:
                
                if let transaction = self.transaction {
                    didReceiveNotification(id: transaction.id)
                    
                    self.displayConfirmAlert()
                }
                
                break;
            default:
//                if let transaction = self.transaction {
//                    if UIApplication.shared.applicationState != .active {
//                        registerBackgroundTask()
//                    }
//                    
//                    didReceiveNotification(id: transaction.id)
//
//                    TGBotManager.updateTransactionStatus(id: transaction.id, status: .failed, type: .transaction, completion: { (_ ) in
//                        
//                    })
//                }
//                self.transaction = nil
                break
            }
        }
        else{
            if AppModel.sharedManager().isLoggedin {
                clickedTransaction = ""
            }
            else{
                clickedTransaction = response.notification.request.identifier
            }
            
            #if EXTENSION
                print("ignore")
            #else
            if AppModel.sharedManager().isLoggedin {
                if let rootVC = UIApplication.getTopMostViewController() {
                    
                    if rootVC is TransactionViewController {
                        rootVC.navigationController?.popViewController(animated: false)
                    }
                    
                    if rootVC is WalletQRCodeViewController {
                        rootVC.dismiss(animated: true) {
                            if let transactions = AppModel.sharedManager().transactions as? [BMTransaction] {
                                if let transaction = transactions.first(where: { $0.id == response.notification.request.identifier }) {
                                    let vc = TransactionViewController(transaction: transaction)
                                    vc.hidesBottomBarWhenPushed = true
                                    
                                    if let topVC = UIApplication.getTopMostViewController() {
                                        topVC.pushViewController(vc: vc)
                                    }
                                }
                            }
                        }
                    }
                    else{
                        if let transactions = AppModel.sharedManager().transactions as? [BMTransaction] {
                            if let transaction = transactions.first(where: { $0.id == response.notification.request.identifier }) {
                                let vc = TransactionViewController(transaction: transaction)
                                vc.hidesBottomBarWhenPushed = true
                                
                                if let topVC = UIApplication.getTopMostViewController() {
                                    topVC.pushViewController(vc: vc)
                                }
                            }
                        }
                    }
             
                }
            }
            #endif
        }
        
        completionHandler()
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                willPresent notification: UNNotification,
                                withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        
        if notification.request.content.categoryIdentifier == NotificationTransaction.id {
            if UIApplication.shared.applicationState == .active {
                
                let data = notification.request.content.userInfo
                
                self.transaction = TransactionData.fromUserInfo(data: data)
                
                if let transaction = self.transaction {
                    self.didReceiveNotification(id: transaction.id)
                    
                    self.displayConfirmAlert()
                }
                
                completionHandler([])
            }
            else{
                completionHandler([.alert, .sound])
            }
        }
        else if UIApplication.shared.applicationState == .active  {
            if (notification.request.content.userInfo["local"] as? Bool) != nil {
                completionHandler([.alert, .sound])
            }
            else{
                completionHandler([])
            }
        }
        else{
            completionHandler([.alert, .sound])
        }
    }
}

//MARK: - FCM Delegate

extension NotificationManager : MessagingDelegate {
    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String) {

    }

    func messaging(_ messaging: Messaging, didReceive remoteMessage: MessagingRemoteMessage) {
    }
}

//MARK: - Wallet Delegate

extension NotificationManager : WalletModelDelegate {
    
    func onNetwotkStatusChange(_ connected: Bool) {
        
        DispatchQueue.main.async {
            if self.transaction != nil {
                if self.transaction?.confirmed ?? false {
                    if connected {
                        self.delegate?.onTransactionStatus(succes: .sending, status: "Preparing to send a transaction")

                        AppModel.sharedManager().getWalletStatus()
                    }
                }
            }
            else if connected && TGBotManager.sharedManager.isNeedLinking() {
                TGBotManager.sharedManager.startLinking(completion: { (_ ) in
                    
                })
            }
        }
    }
    
//    func onReceivedTransactions(_ transactions: [BMTransaction]) {
//
//        for tr in transactions {
//            if tr.enumStatus == 1 && tr.isIncome == false  {
//                if tr.isNew() {
//                    if self.sendedTransactions.contains(tr.id) == false {
//                        self.sendedTransactions.append(tr.id)
//                        self.sendFirebaseNotification(topic: tr.receiverAddress)
//                    }
//                }
//            }
//        }
//    }
    
    func onWalletStatusChange(_ status: BMWalletStatus) {
        
        DispatchQueue.main.async {
            
            if let transaction = self.transaction {
                
                if transaction.confirmed {

                    if let error = AppModel.sharedManager().canSend(transaction.amount, fee: transaction.fee, to: transaction.address)
                    {
                        self.delegate?.onTransactionStatus(succes: .failed, status: error)

                        TGBotManager.updateTransactionStatus(id: transaction.id, status: .failed, type: .transaction, completion: { (_ ) in
                            
                        })
                    }
                    else{
                        self.delegate?.onTransactionStatus(succes: .sending, status: "Sending transaction")

                        AppModel.sharedManager().send(transaction.amount, fee: transaction.fee, to: transaction.address, comment: transaction.comment)
                        
                        TGBotManager.updateTransactionStatus(id: transaction.id, status: .sent, type: .transaction, completion: { (_ ) in
                            
                        })
                        
                        let address = transaction.address
                        
                        DispatchQueue.main.asyncAfter(deadline: .now() + 4.0) {
                            self.sendFirebaseNotification(topic: address)

                            self.delegate?.onTransactionStatus(succes: .sent, status: "Transaction successfully sent")
                        }
                   
                    }
                    
                    self.transaction = nil
                }
            }
        }
    }
}
