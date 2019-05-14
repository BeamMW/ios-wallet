//
// Button.swift
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

extension UIButton {
    
    @IBInspectable
    var adjustFontSize: Bool {
        get {
            return self.adjustFontSize
        }
        set {
            #if EXTENSION
            print("ignore")
            #else
            if newValue {
                if Device.screenType == .iPhone_XSMax || Device.screenType == .iPhones_Plus {
                    self.titleLabel?.adjustFontSize = true
                }
            }
            #endif
       
        }
    }
    
    @IBInspectable
    var localizationKey: String? {
        get {
            return self.localizationKey
        }
        set {
            if newValue != nil {
                self.setTitle(newValue?.localized, for: .normal)
            }
        }
    }
}

extension UIButton {
    
    func setBackgroundColor(color: UIColor, forState: UIControl.State) {
        self.clipsToBounds = true
        self.setBackgroundImage(UIImage.fromColor(color:color), for: forState)
    }
}
