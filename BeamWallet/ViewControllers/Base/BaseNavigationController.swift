//
//  BaseNavigationController.swift
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

class BaseNavigationController: UINavigationController {
    
    public static func navigationController(rootViewController:UIViewController) -> BaseNavigationController {
        let navigation = BaseNavigationController(rootViewController: rootViewController)
        navigation.navigationBar.setBackgroundImage(UIImage.fromColor(color: UIColor.main.marine), for: .default)
        navigation.navigationBar.shadowImage = UIImage()
        navigation.navigationBar.backgroundColor = UIColor.main.marine
        navigation.navigationBar.isTranslucent = false
        navigation.navigationBar.tintColor = UIColor.white
        navigation.navigationBar.titleTextAttributes = [NSAttributedString.Key.foregroundColor: UIColor.white , NSAttributedString.Key.font: SemiboldFont(size: 17)]
        return navigation
    }
    
}
