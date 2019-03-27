//
//  MainTabBarController.swift
//  BeamWallet
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

class MainTabBarController: UITabBarController {

    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.view.backgroundColor = UIColor.main.marine
        self.tabBar.tintColor = UIColor.main.green
        self.tabBar.barTintColor = UIColor.main.navy
        self.tabBar.isTranslucent = false
        self.tabBar.shadowImage = UIImage()
        self.tabBar.backgroundImage = UIImage()
        
        let walletVC = UINavigationController(rootViewController: WalletViewController())
        walletVC.navigationBar.setBackgroundImage(UIImage(), for: .default)
        walletVC.navigationBar.shadowImage = UIImage()
        walletVC.navigationBar.isTranslucent = true
        walletVC.navigationBar.backgroundColor = .clear
        walletVC.navigationBar.tintColor = UIColor.white
        walletVC.navigationBar.titleTextAttributes = [NSAttributedString.Key.foregroundColor: UIColor.white , NSAttributedString.Key.font: UIFont(name: "SFProDisplay-Semibold", size: 17)!]
        walletVC.tabBarItem = UITabBarItem(title: "Wallet", image: UIImage.init(named: "iconWallet"), tag: 0)
        
        let addressesVC = UINavigationController(rootViewController: AddressesViewController())
        addressesVC.navigationBar.setBackgroundImage(UIImage(), for: .default)
        addressesVC.navigationBar.shadowImage = UIImage()
        addressesVC.navigationBar.isTranslucent = true
        addressesVC.navigationBar.backgroundColor = .clear
        addressesVC.navigationBar.tintColor = UIColor.white
        addressesVC.navigationBar.titleTextAttributes = [NSAttributedString.Key.foregroundColor: UIColor.white , NSAttributedString.Key.font: UIFont(name: "SFProDisplay-Semibold", size: 17)!]
        addressesVC.tabBarItem = UITabBarItem(title: "Addresses", image: UIImage.init(named: "iconAddresses"), tag: 0)

        let utxoVC = UINavigationController(rootViewController: UTXOViewController())
        utxoVC.navigationBar.setBackgroundImage(UIImage(), for: .default)
        utxoVC.navigationBar.shadowImage = UIImage()
        utxoVC.navigationBar.isTranslucent = true
        utxoVC.navigationBar.backgroundColor = .clear
        utxoVC.navigationBar.tintColor = UIColor.white
        utxoVC.navigationBar.titleTextAttributes = [NSAttributedString.Key.foregroundColor: UIColor.white , NSAttributedString.Key.font: UIFont(name: "SFProDisplay-Semibold", size: 17)!]
        utxoVC.tabBarItem = UITabBarItem(title: "UTXO", image: UIImage.init(named: "iconUtxo"), tag: 1)

        let settingsVC = UINavigationController(rootViewController: SettingsViewController())
        settingsVC.navigationBar.setBackgroundImage(UIImage(), for: .default)
        settingsVC.navigationBar.shadowImage = UIImage()
        settingsVC.navigationBar.isTranslucent = true
        settingsVC.navigationBar.backgroundColor = .clear
        settingsVC.navigationBar.tintColor = UIColor.white
        settingsVC.navigationBar.titleTextAttributes = [NSAttributedString.Key.foregroundColor: UIColor.white , NSAttributedString.Key.font: UIFont(name: "SFProDisplay-Semibold", size: 17)!]
        settingsVC.tabBarItem = UITabBarItem(title: "Settings", image: UIImage.init(named: "iconSettings"), tag: 2)
        
        self.viewControllers = [walletVC, addressesVC, utxoVC, settingsVC]
    }
    

}
