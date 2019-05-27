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
                    let vc = BaseNavigationController.navigationController(rootViewController: UnlockPasswordViewController(event: .unlock))
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
