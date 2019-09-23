//
// LockScreen.swift
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
import UIKit

public class LockScreen {
    
    private var inactiveDate: TimeInterval = 0
    
    public init() {
        
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(applicationActive),
                                               name: UIApplication.willEnterForegroundNotification,
                                               object: nil)
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(applicationInactive),
                                               name: UIApplication.willResignActiveNotification,
                                               object: nil)
    }
    
    @objc private func applicationActive() {
        if Settings.sharedManager().lockScreenSeconds > 0 {
            let currentTime = Date.timeIntervalSinceReferenceDate
            let diff = currentTime - inactiveDate
            if Int32(diff) >= Settings.sharedManager().lockScreenSeconds {
                if let topVc = UIApplication.getTopMostViewController() {
                    let vc = UINavigationController(rootViewController: UnlockPasswordViewController(event: .unlock))
                    vc.navigationBar.setBackgroundImage(UIImage(), for: .default)
                    vc.navigationBar.shadowImage = UIImage()
                    vc.navigationBar.isTranslucent = true
                    vc.navigationBar.backgroundColor = .clear
                    vc.navigationBar.tintColor = UIColor.white
                    vc.navigationBar.titleTextAttributes = [NSAttributedString.Key.foregroundColor: UIColor.white , NSAttributedString.Key.font: UIFont(name: "SFProDisplay-Semibold", size: 17)!]
                    
                    topVc.present(vc, animated: false, completion: nil)
                }
            }
        }
        
        inactiveDate = 0
    }
    
    @objc private func applicationInactive() {
        inactiveDate = Date.timeIntervalSinceReferenceDate
    }
}
