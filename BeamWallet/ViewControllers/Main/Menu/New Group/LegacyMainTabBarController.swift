//
// LegacyMainTabBarController.swift
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

class LegacyMainTabBarController: UITabBarController {

    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.view.backgroundColor = UIColor.main.marine
        self.tabBar.tintColor = UIColor.main.green
        self.tabBar.barTintColor = UIColor.main.navy
        self.tabBar.isTranslucent = false
        self.tabBar.shadowImage = UIImage()
        self.tabBar.backgroundImage = UIImage()
        
        let walletVC = BaseNavigationController.navigationController(rootViewController: WalletViewController())
        walletVC.tabBarItem = UITabBarItem(title: LocalizableStrings.wallet, image:IconWallet(), tag: 0)
        
        let addressesVC = BaseNavigationController.navigationController(rootViewController: AddressesViewController())
        addressesVC.tabBarItem = UITabBarItem(title: LocalizableStrings.addresses, image: IconAddresses(), tag: 1)
        
        let utxoVC = BaseNavigationController.navigationController(rootViewController: UTXOViewController())
        utxoVC.tabBarItem = UITabBarItem(title: LocalizableStrings.utxo, image: IconUtxo(), tag: 2)

        let settingsVC = BaseNavigationController.navigationController(rootViewController: SettingsViewController())
        settingsVC.tabBarItem = UITabBarItem(title: LocalizableStrings.settings, image: IconSettings(), tag: 3)
        
        self.viewControllers = [walletVC, addressesVC, utxoVC, settingsVC]
    }
    

}
