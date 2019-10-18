//
// BMAutoSecurityScreen.swift
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

public class BMAutoSecurityScreen {
    private lazy var blurView: UIView = UIView()

    public init() {
        blurView.frame = UIScreen.main.bounds
        
        let blurEffect = UIBlurEffect(style: .light)
        let blurEffectView = UIVisualEffectView(effect: blurEffect)
        blurEffectView.frame = UIScreen.main.bounds
        blurEffectView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        blurView.addSubview(blurEffectView)
        
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(removeBlur),
                                               name: UIApplication.didBecomeActiveNotification,
                                               object: nil)
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(addBlur),
                                               name: UIApplication.willResignActiveNotification,
                                               object: nil)
    }

    @objc private func addBlur() {
        if !BiometricAuthorization.shared.isAuthorizationProccess {
            createBlurEffect()
        }
    }

    @objc private func removeBlur() {
        removeBlurEffect()
    }

    private func createBlurEffect() {
        blurView.alpha = 0

        if let app = UIApplication.shared.delegate as? AppDelegate, let window = app.window {
            
            window.addSubview(blurView)

            UIView.animate(withDuration: 0.3) {
                self.blurView.alpha = 1
            }
        }
    }

    private func removeBlurEffect() {
        UIView.animate(withDuration: 0.3, animations: {
            self.blurView.alpha = 0
        }) { (_ ) in
            self.blurView.removeFromSuperview()
        }
    }
}



