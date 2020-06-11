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

import CrashEye
import Crashlytics
import Fabric
import UIKit
import UserNotifications

class BeamApplication: UIApplication {
    override func sendEvent(_ event: UIEvent) {
        super.sendEvent(event)
        
        BMLockScreen.shared.onTapEvent()
    }
}

// @UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    private var scannedTGUserId = String.empty()
    
    var securityScreen = BMAutoSecurityScreen()
    
    var window: UIWindow?
    var backgroundTask: UIBackgroundTaskIdentifier = .invalid
    var completionHandler: ((UIBackgroundFetchResult) -> Void)?
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        CrashEye.add(delegate: self)
        
        UIApplication.shared.setMinimumBackgroundFetchInterval(UIApplication.backgroundFetchIntervalMinimum)
        
        UIApplication.shared.isIdleTimerDisabled = true
        
//        FirebaseConfiguration.shared.setLoggerLevel(.min)
//        FirebaseApp.configure()
        
        Localizable.shared.reset()
        Settings.sharedManager()
        
        KeyboardListener.shared.start()
        
        NotificationManager.sharedManager.requestPermissions()
        
        if Settings.sharedManager().target != Mainnet {
            CrowdinManager.updateLocalizations()
        }
        
        AppModel.sharedManager().checkRecoveryWallet()
        AppModel.sharedManager().addDelegate(self)
        Settings.sharedManager().addDelegate(self)
        
        let added = AppModel.sharedManager().isWalletAlreadyAdded()
        
        let rootController = BaseNavigationController.navigationController(rootViewController: added ? EnterWalletPasswordViewController() : WellcomeViewController())
        
        self.window = UIWindow(frame: UIScreen.main.bounds)
        self.window?.backgroundColor = UIColor.main.navy
        self.window?.rootViewController = rootController
        self.window?.makeKeyAndVisible()
        
        if #available(iOS 12.0, *) {
            let isDark = self.window?.rootViewController?.traitCollection.userInterfaceStyle == .dark
            Settings.sharedManager().setDefaultDarkMode(isDark)
        }
        else {
            Settings.sharedManager().setDefaultDarkMode(false)
        }
        
        ShortcutManager.launchWithOptions(launchOptions: launchOptions)
        
        
        if let crash = UserDefaults.standard.string(forKey: "crash"), let name = UserDefaults.standard.string(forKey: "crash_name") {
            self.window?.rootViewController?.confirmAlert(title: Localizable.shared.strings.crash_title, message: Localizable.shared.strings.crash_message, cancelTitle: Localizable.shared.strings.crash_positive, confirmTitle: Localizable.shared.strings.crash_negative, cancelHandler: { _ in
               
                Fabric.with([Crashlytics.self()])
                
                Crashlytics.sharedInstance().recordCustomExceptionName(name, reason: crash, frameArray: [])
                
                Answers.logCustomEvent(withName: "CRASH", customAttributes: ["stackTrace": crash])
                
                UserDefaults.standard.set(nil, forKey: "crash")
                UserDefaults.standard.synchronize()
                
            }, confirmHandler: { _ in
                UserDefaults.standard.set(nil, forKey: "crash")
                UserDefaults.standard.synchronize()
            })
        }
    
        if #available(iOS 13.0, *) {
            window?.overrideUserInterfaceStyle = Settings.sharedManager().isDarkMode ? .dark : .light
        }
        
        
        return true
    }
        
    public func logout() {
        AppModel.sharedManager().clearAllCategories()
        AppModel.sharedManager().clearNotifications()
        AppModel.sharedManager().isLoggedin = false
        AppModel.sharedManager().resetWallet(true)
        Settings.sharedManager().resetSettings()
        OnboardManager.shared.reset()
        
        let rootController = BaseNavigationController.navigationController(rootViewController: WellcomeViewController())
        
        self.window!.rootViewController = rootController
    }
    
    func applicationWillResignActive(_ application: UIApplication) {
        
    }
    
    func applicationDidEnterBackground(_ application: UIApplication) {
        if AppModel.sharedManager().connectionTimer != nil {
            AppModel.sharedManager().connectionTimer?.invalidate()
            AppModel.sharedManager().connectionTimer = nil
        }
        
        self.registerBackgroundTask()
        
        if let transactions = AppModel.sharedManager().preparedTransactions as? [BMPreparedTransaction] {
            if transactions.count > 0, AppModel.sharedManager().isLoggedin {
                BMSnackBar.dismiss(canceled: true)
                
                for tr in transactions {
                    AppModel.sharedManager().sendPreparedTransaction(tr.id)
                }
            }
        }
        
        if let addresses = AppModel.sharedManager().preparedDeleteAddresses as? [BMAddress] {
            if addresses.count > 0, AppModel.sharedManager().isLoggedin {
                BMSnackBar.dismiss(canceled: true)
                
                for a in addresses {
                    AppModel.sharedManager().deletePreparedAddresses(a.walletId)
                }
            }
        }
        
        if AppModel.sharedManager().isConnected {
            AppModel.sharedManager().isConnecting = true
        }
    }
    
    func applicationWillEnterForeground(_ application: UIApplication) {
        self.endBackgroundTask()
    }
    
    func applicationDidBecomeActive(_ application: UIApplication) {
        if #available(iOS 12.0, *) {
            if self.window?.rootViewController?.traitCollection.userInterfaceStyle == .dark || Settings.sharedManager().isDarkMode {
                UIView.appearance(whenContainedInInstancesOf: [UIAlertController.self]).tintColor = UIColor.white
                self.window?.tintColor = self.window?.rootViewController?.traitCollection.userInterfaceStyle == .dark ? UIColor.white : UIColor.black
            }
            else {
                UIView.appearance(whenContainedInInstancesOf: [UIAlertController.self]).tintColor = UIColor.main.marine
                self.window?.tintColor = UIColor.main.marine
            }
        }
        else {
            if Settings.sharedManager().isDarkMode {
                UIView.appearance(whenContainedInInstancesOf: [UIAlertController.self]).tintColor = UIColor.white
                self.window?.tintColor = UIColor.white
            }
            else {
                self.window?.tintColor = UIColor.main.marine
                UIView.appearance(whenContainedInInstancesOf: [UIAlertController.self]).tintColor = UIColor.main.marine
            }
        }
        
        NotificationManager.sharedManager.clearNotifications()
        
        if ShortcutManager.canHandle() {
            _ = ShortcutManager.handleShortcutItem()
        }
    }
    
    func applicationWillTerminate(_ application: UIApplication) {}
    
    private func registerBackgroundTask() {
        self.backgroundTask = UIApplication.shared.beginBackgroundTask { [weak self] in
            self?.endBackgroundTask()
        }
    }
    
    private func endBackgroundTask() {
        UIApplication.shared.endBackgroundTask(self.backgroundTask)
        self.backgroundTask = .invalid
    }
    

    func application(_ application: UIApplication, continue userActivity: NSUserActivity, restorationHandler: @escaping ([UIUserActivityRestoring]?) -> Void) -> Bool {
        return true
    }
    
    func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey: Any] = [:]) -> Bool {        
        return true
    }
    
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
    }
    
    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {}
    
    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable: Any], fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        completionHandler(.noData)
    }
    
    func application(_ application: UIApplication, performFetchWithCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        if(AppModel.sharedManager().isLoggedin) {
            AppModel.sharedManager().getWalletStatus()
            self.completionHandler = completionHandler
        }
        else {
            completionHandler(.noData)
        }
    }
    
    func application(_ application: UIApplication, handleEventsForBackgroundURLSession identifier: String, completionHandler: @escaping () -> Void) {
        print("handleEventsForBackgroundURLSession: \(identifier)")
        completionHandler()
    }
}

// MARK: - 3D TOUCH

extension AppDelegate {
    func application(_ application: UIApplication, performActionFor shortcutItem: UIApplicationShortcutItem, completionHandler: @escaping (Bool) -> Void) {
        ShortcutManager.launchedShortcutItem = shortcutItem
        
        if ShortcutManager.canHandle() {
            _ = ShortcutManager.handleShortcutItem()
        }
        
        completionHandler(true)
    }
}

extension AppDelegate: WalletModelDelegate {
    func onAddedDelete(_ transaction: BMTransaction) {
        DispatchQueue.main.async {
            BMSnackBar.show(data: BMSnackBar.SnackData(type: .delete_transaction, id: transaction.id), done: { data in
                if let result = data, result.type == .delete_transaction {
                    AppModel.sharedManager().cancelDeleteTransaction(result.id)
                }
            }, ended: { data in
                if let result = data, result.type == .delete_transaction {
                    AppModel.sharedManager().deleteTransaction(result.id)
                }
            })
        }
    }
    
    func onAddedDelete(_ address: BMAddress) {
        DispatchQueue.main.async {
            let isContact = address.isContact
            
            BMSnackBar.show(data: BMSnackBar.SnackData(type: isContact ? .contact : .address, id: address.walletId), done: { data in
                if let result = data, result.type == .address {
                    AppModel.sharedManager().cancelDeleteAddress(result.id)
                }
            }) { data in
                if let result = data, result.type == .address {
                    AppModel.sharedManager().deletePreparedAddresses(result.id)
                }
            }
        }
    }
    
    func onAddedPrepare(_ transaction: BMPreparedTransaction) {
        DispatchQueue.main.async {
            BMSnackBar.show(data: BMSnackBar.SnackData(type: .transaction, id: transaction.id), done: { data in
                if let result = data, result.type == .transaction {
                    AppModel.sharedManager().cancelPreparedTransaction(result.id)
                }
            }) { data in
                if let result = data, result.type == .transaction {
                    AppModel.sharedManager().sendPreparedTransaction(result.id)
                }
            }
        }
    }
    
    public func onReceivedTransactions(_ transactions: [BMTransaction]) {
        DispatchQueue.main.async {
            var oldTransactions = [BMTransaction]()
            
            if let data = UserDefaults.standard.data(forKey: Localizable.shared.strings.transactions) {
                if let array = NSKeyedUnarchiver.unarchiveObject(with: data) as? [BMTransaction] {
                    oldTransactions = array
                }
            }
            
            for transaction in transactions {
                if transaction.isIncome, !transaction.isSelf {
                    if oldTransactions.first(where: { $0.id == transaction.id }) == nil {
                        NotificationManager.sharedManager.scheduleNotification(transaction: transaction)
                    }
                }
            }
            
            UserDefaults.standard.set(NSKeyedArchiver.archivedData(withRootObject: transactions), forKey: Localizable.shared.strings.transactions)
            UserDefaults.standard.synchronize()
            
            self.completionHandler?(.newData)
        }
    }
}

// MARK: - Crash

extension AppDelegate: CrashEyeDelegate {
    public static func isCrashed() -> Bool {
        return UserDefaults.standard.string(forKey: "crash") != nil
    }
    
    func crashEyeDidCatchCrash(with model: CrashModel) {
        UserDefaults.standard.set(model.callStack, forKey: "crash")
        UserDefaults.standard.set(model.name, forKey: "crash_name")
        UserDefaults.standard.synchronize()
    }
}

extension AppDelegate: SettingsModelDelegate {
    func onChangeDarkMode() {
        if Settings.sharedManager().isDarkMode {
            UIView.appearance(whenContainedInInstancesOf: [UIAlertController.self]).tintColor = UIColor.white
            if #available(iOS 12.0, *) {
                self.window?.tintColor = self.window?.rootViewController?.traitCollection.userInterfaceStyle == .dark ? UIColor.white : UIColor.black
            }
            else {
                self.window?.tintColor = UIColor.white
            }
        }
        else {
            if #available(iOS 12.0, *) {
                self.window?.tintColor = self.window?.rootViewController?.traitCollection.userInterfaceStyle == .dark ? UIColor.white : UIColor.main.marine
            }
            else {
                self.window?.tintColor = UIColor.main.marine
            }
            
            UIView.appearance(whenContainedInInstancesOf: [UIAlertController.self]).tintColor = UIColor.main.marine
        }
        
        if #available(iOS 13.0, *) {
            window?.overrideUserInterfaceStyle = Settings.sharedManager().isDarkMode ? .dark : .light
        }
    }
}
