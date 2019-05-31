//
// ShortcutManager.swift
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

class ShortcutManager {
    
    enum ShortcutIdentifier: String {
        case Buy
        case Scan
        case Send
        case Receive
        
        init?(fullNameForType: String) {
            guard let last = fullNameForType.components(separatedBy: ".").last else { return nil }
            
            self.init(rawValue: last)
        }
        
        var type: String {
            return Bundle.main.bundleIdentifier! + ".\(self.rawValue)"
        }
    }

    public static var launchedShortcutItem: UIApplicationShortcutItem?

    public static func canHandle() -> Bool {
        return (launchedShortcutItem != nil && AppModel.sharedManager().isLoggedin)
    }
    
    public static func launchWithOptions(launchOptions: [UIApplication.LaunchOptionsKey: Any]?) {
        
        if let shortcutItem = launchOptions?[UIApplication.LaunchOptionsKey.shortcutItem] as? UIApplicationShortcutItem {
            
            launchedShortcutItem = shortcutItem
        }
    }
    
    public static func handleShortcutItem() -> Bool {        
        var handled = false
        
        guard let topVC = UIApplication.getTopMostViewController() else { return false }
        
        guard let navigationController = topVC.sideMenuController?.rootViewController as? UINavigationController else { return false }
        
        guard let item = launchedShortcutItem else { return false }
        guard ShortcutIdentifier(fullNameForType: item.type) != nil else { return false }
        guard let shortCutType = item.type as String? else { return false }
        
        if navigationController.presentedViewController != nil {
            navigationController.dismiss(animated: false, completion: nil)
        }
        
        switch shortCutType {
        case ShortcutIdentifier.Send.type:
            handled = true
            navigationController.viewControllers = [WalletViewController(), WalletSendViewController()]
        case ShortcutIdentifier.Receive.type:
            handled = true
            navigationController.viewControllers = [WalletViewController(), LegacyWalletReceiveViewController(address: BMAddress())]
        case ShortcutIdentifier.Scan.type:
            handled = true
            navigationController.viewControllers = [WalletViewController(), WalletSendViewController(), WalletQRCodeScannerViewController()]
        case ShortcutIdentifier.Buy.type:
            handled = true
            topVC.openUrl(url: URL(string: Settings.sharedManager().whereBuyAddress)!)
        default:
            handled = false
        }
        
        if handled {
            topVC.sideMenuController?.hideLeftView()
            
            for vc in navigationController.viewControllers {
                vc.navigationItem.backBarButtonItem = UIBarButtonItem.arrowButton()
            }
            
            launchedShortcutItem = nil
        }
        
        return handled
    }
}
