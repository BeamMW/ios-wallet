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

    //TODO: all targets uses masternet!!!!
    
    public static let isEnableNewFeatures = false
    
    private var scannedTGUserId = ""

    var securityScreen = AutoSecurityScreen()
    var lockScreen = LockScreen()

    var window: UIWindow?
    var backgroundTask: UIBackgroundTaskIdentifier = .invalid
    var completionHandler: ((UIBackgroundFetchResult) -> Void)?
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
    
        UIApplication.shared.setMinimumBackgroundFetchInterval (UIApplication.backgroundFetchIntervalMinimum)
        
        //UIApplication.shared.isIdleTimerDisabled = true

        FirebaseConfiguration.shared.setLoggerLevel(.min)
        FirebaseApp.configure()

        Crashlytics().debugMode = true
        Fabric.with([Crashlytics.self()])
        
        Settings.sharedManager()
        
        NotificationManager.sharedManager.requestPermissions()
        
        AppModel.sharedManager().addDelegate(self)
        
        let added = AppModel.sharedManager().isWalletAlreadyAdded()
        
        let rootController = UINavigationController(rootViewController: added ? EnterWalletPasswordViewController() : LoginViewController())
        rootController.navigationBar.setBackgroundImage(UIImage(), for: .default)
        rootController.navigationBar.shadowImage = UIImage()
        rootController.navigationBar.isTranslucent = true
        rootController.navigationBar.backgroundColor = .clear
        rootController.navigationBar.tintColor = UIColor.white
        rootController.navigationBar.titleTextAttributes = [NSAttributedString.Key.foregroundColor: UIColor.white , NSAttributedString.Key.font: UIFont(name: "SFProDisplay-Semibold", size: 17)!]

        self.window = UIWindow(frame: UIScreen.main.bounds)
        self.window!.rootViewController = rootController
        self.window!.makeKeyAndVisible()
    
        UIView.appearance(whenContainedInInstancesOf: [UIAlertController.self]).tintColor = UIColor.main.marineTwo
        
        return true
    }

    func applicationWillResignActive(_ application: UIApplication) {
   
    }

    func applicationDidEnterBackground(_ application: UIApplication) {

        //TODO: notification - close db
        if AppModel.sharedManager().isLoggedin && !AppModel.sharedManager().isRestoreFlow
            && Settings.sharedManager().target == Testnet {
            AppModel.sharedManager().isConnecting = true
            AppModel.sharedManager().resetWallet(false)
        }
        else if AppModel.sharedManager().isRestoreFlow {
            registerBackgroundTask()
        }
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        
        if AppModel.sharedManager().isRestoreFlow {
            endBackgroundTask()
        }
    }

    func applicationDidBecomeActive(_ application: UIApplication) {

        NotificationManager.sharedManager.clearNotifications()
        
        //TODO: notification - close db
        if AppModel.sharedManager().isLoggedin && !AppModel.sharedManager().isRestoreFlow && Settings.sharedManager().target == Testnet {
            if let password = KeychainManager.getPassword() {
                if AppModel.sharedManager().isWalletInitialized() == false {
                    AppModel.sharedManager().isConnecting = true
                    AppModel.sharedManager().openWallet(password)
                }
            }
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
                    vc.alert(title: "Telegram bot", message: "Please open wallet to link telegram bot") { (_ ) in
                        
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
        
        print("didReceiveRemoteNotification")
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
        
        print("performFetchWithCompletionHandler")
        
        if(!AppModel.sharedManager().isRestoreFlow) {
            if let password = KeychainManager.getPassword() {
                self.completionHandler = completionHandler

                self.registerBackgroundTask()

                if(AppModel.sharedManager().isLoggedin) {
                    AppModel.sharedManager().refreshAllInfo()
                }
                else{
                    AppModel.sharedManager().openWallet(password)
                }

                DispatchQueue.main.asyncAfter(deadline: .now() + 26) {
                    self.endBackgroundTask()
                    self.completionHandler?(.newData)
                }
            }
            else{
                completionHandler(.noData)
            }
        }
        else{
            completionHandler(.noData)
        }
    }
}


extension AppDelegate : WalletModelDelegate {
    public func onReceivedTransactions(_ transactions: [BMTransaction]) {
        DispatchQueue.main.async {
            
            var oldTransactions = [BMTransaction]()
            
            //get old notifications
            if let data = UserDefaults.standard.data(forKey: "transactions") {
                if let array = NSKeyedUnarchiver.unarchiveObject(with: data) as? [BMTransaction] {
                    oldTransactions = array
                }
            }
            
            for transaction in transactions {
                if transaction.isIncome && !transaction.isSelf {
                    if let oldTransaction = oldTransactions.first(where: { $0.id == transaction.id }) {
                        if oldTransaction.status != transaction.status && UIApplication.shared.applicationState != .active {
                            NotificationManager.sharedManager.scheduleNotification(transaction: transaction)
                        }
                    }
                    else{
                        NotificationManager.sharedManager.scheduleNotification(transaction: transaction)
                    }
                }
            }
            
            UserDefaults.standard.set(NSKeyedArchiver.archivedData(withRootObject: transactions), forKey: "transactions")
            UserDefaults.standard.synchronize()
        }
    }
}

