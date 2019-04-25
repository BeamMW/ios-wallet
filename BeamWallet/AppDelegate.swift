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

    var securityScreen = AutoSecurityScreen()
    var lockScreen = LockScreen()

    var window: UIWindow?
    var backgroundTask: UIBackgroundTaskIdentifier = .invalid
    var completionHandler: ((UIBackgroundFetchResult) -> Void)?

    static let targetName = Bundle.main.infoDictionary?["CFBundleExecutable"] as! String

    enum Target: String {
        case Main = "Main"
        case Test = "BeamWalletTestNet"
        case Master = "BeamWalletMasterNet"
    }
    
    static var CurrentTarget: Target {
        switch targetName {
        case Target.Test.rawValue:
            return .Test
        case Target.Master.rawValue:
            return .Master
        default:
            return .Main
        }
    }
    
    static var disableApns = false
   // static var enableNewFeatures = true
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        
        UIApplication.shared.setMinimumBackgroundFetchInterval (UIApplication.backgroundFetchIntervalMinimum)
        
        UIApplication.shared.isIdleTimerDisabled = true

        AnalyticsConfiguration.shared().setAnalyticsCollectionEnabled(false)
        FirebaseApp.configure()

        Crashlytics().debugMode = true
        Fabric.with([Crashlytics.self()])
        
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
        
        if AppModel.sharedManager().isRestoreFlow {
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
        
    }

    func applicationWillTerminate(_ application: UIApplication) {
    }

    func registerBackgroundTask() {
        backgroundTask = UIApplication.shared.beginBackgroundTask { [weak self] in
            self?.endBackgroundTask()
        }
    }
    
    func endBackgroundTask() {
        UIApplication.shared.endBackgroundTask(backgroundTask)
        backgroundTask = .invalid
    }
    
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        Messaging.messaging().apnsToken = deviceToken
    }
    
    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
    }
    
    
    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable : Any], fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        
        print("didReceiveRemoteNotification")

        if(!AppModel.sharedManager().isRestoreFlow) {
            if let password = KeychainManager.getPassword() {
                if NotificationManager.sharedManager.sendAutomaticMoney(data: userInfo) == false
                {
                    self.registerBackgroundTask()
                    
                    self.completionHandler = completionHandler
                    
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
                    completionHandler(.newData)
                }
            }
            else{
                completionHandler(.noData)
            }
        }
        else{
            completionHandler(.newData)
        }
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

