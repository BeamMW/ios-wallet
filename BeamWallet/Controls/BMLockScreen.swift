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

public class BMLockScreen {
    
    static let shared = BMLockScreen()

    var isScreenLocked = false
    
    private var timer: Timer?
    private var seconds = 0
    private var inactiveDate: TimeInterval = 0

    public init() {
        timer = Timer.scheduledTimer(timeInterval: 1, target: self as Any, selector: #selector(applicationActive), userInfo: nil, repeats: true)
        
        NotificationCenter.default.addObserver(self,
                                                  selector: #selector(applicationActive),
                                                  name: UIApplication.willEnterForegroundNotification,
                                                  object: nil)
        NotificationCenter.default.addObserver(self,
                                                  selector: #selector(applicationInactive),
                                                  name: UIApplication.willResignActiveNotification,
                                                  object: nil)
    }
    
    func onTapEvent() {
        seconds = 0
    }
    
    @objc private func applicationInactive() {
          inactiveDate = Date.timeIntervalSinceReferenceDate
      }
    
    @objc private func applicationActive() {
        seconds = seconds + 1
        
        if Settings.sharedManager().lockScreenSeconds > 0 && AppModel.sharedManager().isLoggedin {
            let currentTime = Date.timeIntervalSinceReferenceDate
            let diff = inactiveDate > 0 ? currentTime - inactiveDate : 0
            
            if (seconds >= Settings.sharedManager().lockScreenSeconds || Int32(diff) >= Settings.sharedManager().lockScreenSeconds) && !isScreenLocked {
                
                if let topVc = UIApplication.getTopMostViewController() {
                    if let alert = topVc as? UIAlertController {
                        alert.dismiss(animated: true) {
                            self.show()
                        }
                    }
                    else{
                        self.show()
                    }
                }
            }
        }
    }
    
    private func show() {
        if let topVc = UIApplication.getTopMostViewController() {
            
            isScreenLocked = true
            
            timer?.invalidate()
            timer = nil
            seconds = 0
            inactiveDate = 0
            
            let unlock = UnlockPasswordViewController(event: .unlock)
            unlock.disableMenu = true
            unlock.completion = { [weak self]
                obj in
                
                guard let strongSelf = self else { return }

                strongSelf.isScreenLocked = false
                
                strongSelf.timer = Timer.scheduledTimer(timeInterval: 1, target: strongSelf, selector: #selector(strongSelf.applicationActive), userInfo: nil, repeats: true)
            }
            
            let vc = UINavigationController(rootViewController: unlock)
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
