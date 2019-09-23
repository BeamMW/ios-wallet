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

    private var timer: Timer?
    private var seconds = 0

    public init() {
        timer = Timer.scheduledTimer(timeInterval: 1, target: self as Any, selector: #selector(applicationActive), userInfo: nil, repeats: true)
    }
    
    func onTapEvent() {
        seconds = 0
    }
    
    @objc private func applicationActive() {
        seconds = seconds + 1
        
        if Settings.sharedManager().lockScreenSeconds > 0 && AppModel.sharedManager().isLoggedin {
            if seconds >= Settings.sharedManager().lockScreenSeconds {
                if let topVc = UIApplication.getTopMostViewController() {
                    
                    timer?.invalidate()
                    timer = nil
                    seconds = 0
                    
                    let unlock = UnlockPasswordViewController(event: .unlock)
                    unlock.completion = { [weak self]
                        obj in
                        
                        guard let strongSelf = self else { return }

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
    }
}
