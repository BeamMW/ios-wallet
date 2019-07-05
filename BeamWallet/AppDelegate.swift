//
// AppDelegate.swift
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
import Fabric
import Crashlytics
import FirebaseCore
import FirebaseMessaging


@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    public static let newFeaturesEnabled = true

    private var scannedTGUserId = String.empty()

    var securityScreen = AutoSecurityScreen()
    var lockScreen = LockScreen()

    var window: UIWindow?
    var backgroundTask: UIBackgroundTaskIdentifier = .invalid
    var completionHandler: ((UIBackgroundFetchResult) -> Void)?
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
            
        UIView.appearance(whenContainedInInstancesOf: [UIAlertController.self]).tintColor = UIColor.main.marine

        UIApplication.shared.setMinimumBackgroundFetchInterval (UIApplication.backgroundFetchIntervalMinimum)
        
        UIApplication.shared.isIdleTimerDisabled = false

        FirebaseConfiguration.shared.setLoggerLevel(.min)
        FirebaseApp.configure()

        Crashlytics().debugMode = true
        Fabric.with([Crashlytics.self()])
        
        Settings.sharedManager()
        
        NotificationManager.sharedManager.requestPermissions()
        
        AppModel.sharedManager().addDelegate(self)
        
        let added = AppModel.sharedManager().isWalletAlreadyAdded()

        let rootController = BaseNavigationController.navigationController(rootViewController: added ? EnterWalletPasswordViewController() : LoginViewController())
        
        self.window = UIWindow(frame: UIScreen.main.bounds)
        self.window?.backgroundColor = UIColor.main.navy
        self.window?.rootViewController = rootController
        self.window?.makeKeyAndVisible()
    
        ShortcutManager.launchWithOptions(launchOptions: launchOptions)
        
        CryptoWolfManager.sharedManager.loadData {
            
        }
        
        return true
    }
    
    public func logout() {
        AppModel.sharedManager().isLoggedin = false

        AppModel.sharedManager().resetWallet(false)

        let rootController = BaseNavigationController.navigationController(rootViewController: EnterWalletPasswordViewController(isNeedRequestedAuthorization: false))

        self.window!.rootViewController = rootController
    }

    func applicationWillResignActive(_ application: UIApplication) {
   
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
    
        if AppModel.sharedManager().isRestoreFlow {
            registerBackgroundTask()
        }
        
        if let transactions = AppModel.sharedManager().preparedTransactions as? [BMPreparedTransaction] {
            
            if transactions.count > 0 && AppModel.sharedManager().isLoggedin {
                BMSnackBar.dismiss(canceled: true)

                for tr in transactions {
                    AppModel.sharedManager().sendPreparedTransaction(tr.id)
                }
            }
        }
        
        if let addresses = AppModel.sharedManager().preparedDeleteAddresses as? [BMAddress] {
            
            if addresses.count > 0 && AppModel.sharedManager().isLoggedin {
                BMSnackBar.dismiss(canceled: true)
                
                for a in addresses {
                    AppModel.sharedManager().deletePreparedAddresses(a.walletId)
                }
            }
        }
        
        AppModel.sharedManager().isConnecting = true
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        
        if AppModel.sharedManager().isRestoreFlow {
            endBackgroundTask()
        }
    }

    func applicationDidBecomeActive(_ application: UIApplication) {

        NotificationManager.sharedManager.clearNotifications()
                
        if ShortcutManager.canHandle() {
            _ = ShortcutManager.handleShortcutItem()
        }
    }

    func applicationWillTerminate(_ application: UIApplication) {
        
    }

    private func registerBackgroundTask() {
        backgroundTask = UIApplication.shared.beginBackgroundTask { [weak self] in
            self?.endBackgroundTask()
        }
    }
    
    private func endBackgroundTask() {
        UIApplication.shared.endBackgroundTask(backgroundTask)
        backgroundTask = .invalid
    }
    
    private func tryLinkingBot(url:URL) {
        if TGBotManager.sharedManager.isValidUserFromUrl(url: url) {
            if AppModel.sharedManager().isLoggedin {
                TGBotManager.sharedManager.startLinking { (_ ) in
                    
                }
            }
            else{
                if let vc = UIApplication.getTopMostViewController() {
                    vc.alert(title: Localizable.shared.strings.tg_bot, message: Localizable.shared.strings.tg_bot_link) { (_ ) in
                        
                        if let passVC = UIApplication.getTopMostViewController() as? EnterWalletPasswordViewController {
                            passVC.biometricAuthorization()
                        }
                    }
                }
            }
        }
    }
    
    func application(_ application: UIApplication, continue userActivity: NSUserActivity, restorationHandler: @escaping ([UIUserActivityRestoring]?) -> Void) -> Bool {
       
        if let url = userActivity.webpageURL {
            if ((UIApplication.getTopMostViewController() as? EnterWalletPasswordViewController) != nil) {
                _ = TGBotManager.sharedManager.isValidUserFromUrl(url: url)
            }
            else{
                tryLinkingBot(url: url)
            }
        }

        return true
    }
    
    func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
        
        tryLinkingBot(url: url)
        
        return true
    }
    
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        Messaging.messaging().apnsToken = deviceToken
    }
    
    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
    }
    
    
    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable : Any], fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        
        completionHandler(.noData)

//        if(!AppModel.sharedManager().isRestoreFlow) {
//            if let password = KeychainManager.getPassword() {
//                if NotificationManager.sharedManager.sendAutomaticMoney(data: userInfo) == false
//                {
//                    self.registerBackgroundTask()
//
//                    self.completionHandler = completionHandler
//
//                    if(AppModel.sharedManager().isLoggedin) {
//                        AppModel.sharedManager().refreshAllInfo()
//                    }
//                    else{
//                        AppModel.sharedManager().openWallet(password)
//                    }
//
//                    DispatchQueue.main.asyncAfter(deadline: .now() + 26) {
//                        self.endBackgroundTask()
//                        self.completionHandler?(.newData)
//                    }
//                }
//                else{
//                    completionHandler(.newData)
//                }
//            }
//            else{
//                completionHandler(.noData)
//            }
//        }
//        else{
//            completionHandler(.newData)
//        }
    }
    
    func application(_ application: UIApplication, performFetchWithCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        
        completionHandler(.noData)

//        if(!AppModel.sharedManager().isRestoreFlow) {
//            if let password = KeychainManager.getPassword() {
//                self.completionHandler = completionHandler
//
//                self.registerBackgroundTask()
//
//                if(AppModel.sharedManager().isLoggedin) {
//                    AppModel.sharedManager().refreshAllInfo()
//                }
//                else{
//                    AppModel.sharedManager().openWallet(password)
//                }
//
//                DispatchQueue.main.asyncAfter(deadline: .now() + 26) {
//                    self.endBackgroundTask()
//                    self.completionHandler?(.newData)
//                }
//            }
//            else{
//                completionHandler(.noData)
//            }
//        }
//        else{
//            completionHandler(.noData)
//        }
    }
    
    func application(_ application: UIApplication, handleEventsForBackgroundURLSession identifier: String, completionHandler: @escaping () -> Void) {
        print("handleEventsForBackgroundURLSession: \(identifier)")
        completionHandler()
    }
}

//MARK: - 3D TOUCH

extension AppDelegate {

    func application(_ application: UIApplication, performActionFor shortcutItem: UIApplicationShortcutItem, completionHandler: @escaping (Bool) -> Void) {
        
        ShortcutManager.launchedShortcutItem = shortcutItem
        
        if ShortcutManager.canHandle() {
           _ = ShortcutManager.handleShortcutItem()
        }

        completionHandler(true)
    }
}

extension AppDelegate : WalletModelDelegate {
   
    func onAddedDelete(_ transaction: BMTransaction) {
        DispatchQueue.main.async {
            BMSnackBar.show(data: BMSnackBar.SnackData(type: .delete_transaction, id: transaction.id), done: { (data) in
                if let result = data, result.type == .delete_transaction {
                    AppModel.sharedManager().cancelDeleteTransaction(result.id)
                }
            }, ended: { (data) in
                if let result = data, result.type == .delete_transaction {
                    AppModel.sharedManager().deleteTransaction(result.id)
                }
            })
        }
    }
    
    func onAddedDelete(_ address: BMAddress) {
        DispatchQueue.main.async {
            let isContact = address.isContact
            
            BMSnackBar.show(data: BMSnackBar.SnackData(type: isContact ? .contact : .address, id: address.walletId), done: { (data) in
                if let result = data, result.type == .address {
                    AppModel.sharedManager().cancelDeleteAddress(result.id)
                }
            }) { (data) in
                if let result = data, result.type == .address {
                    AppModel.sharedManager().deletePreparedAddresses(result.id)
                }
            }
        }
    }
    
    func onAddedPrepare(_ transaction: BMPreparedTransaction) {
        DispatchQueue.main.async {
            BMSnackBar.show(data: BMSnackBar.SnackData(type: .transaction, id: transaction.id), done: { (data) in
                if let result = data, result.type == .transaction {
                    AppModel.sharedManager().cancelPreparedTransaction(result.id)
                }
            }) { (data) in
                if let result = data, result.type == .transaction {
                    AppModel.sharedManager().sendPreparedTransaction(result.id)
                }
            }
        }
    }
    
    public func onReceivedTransactions(_ transactions: [BMTransaction]) {
        DispatchQueue.main.async {
            
            var oldTransactions = [BMTransaction]()
            
            //get old notifications
            if let data = UserDefaults.standard.data(forKey: Localizable.shared.strings.transactions) {
                if let array = NSKeyedUnarchiver.unarchiveObject(with: data) as? [BMTransaction] {
                    oldTransactions = array
                }
            }
            
            for transaction in transactions {
                if transaction.isIncome && !transaction.isSelf {
                    if let oldTransaction = oldTransactions.first(where: { $0.id == transaction.id }) {
                        if oldTransaction.status != transaction.status && UIApplication.shared.applicationState != .active {
                          
                            //NotificationManager.sharedManager.scheduleNotification(transaction: transaction)
                        }
                    }
                    else{
                        AppStoreReviewManager.incrementAppTransactions()

                        NotificationManager.sharedManager.scheduleNotification(transaction: transaction)
                    }
                }
            }
            
            UserDefaults.standard.set(NSKeyedArchiver.archivedData(withRootObject: transactions), forKey: Localizable.shared.strings.transactions)
            UserDefaults.standard.synchronize()
        }
    }
}

