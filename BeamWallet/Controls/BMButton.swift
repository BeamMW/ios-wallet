//
//  DesignableButton.swift
//  BeamWallet
//
// 2/28/19.
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

@IBDesignable
class BMButton: UIButton {
    
    public static func defaultButton(frame:CGRect, color:UIColor) -> BMButton {
        let button = BMButton(frame: frame)
        button.cornerRadius = frame.size.height / 2
        button.backgroundColor = color
        button.awakeFromNib()
        button.titleLabel?.font = BoldFont(size: 14)
        button.adjustFontSize = true
        button.imageEdgeInsets = UIEdgeInsets(top: 0, left: 0, bottom: -1, right: 20)
        return button
    }
    
    private var _testnetColor:UIColor?

    @IBInspectable
    var testnetColor: UIColor? {
        get {
            return _testnetColor
        }
        set {
            _testnetColor = newValue
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        #if EXTENSION
        print("ignore")
        #else
        if let color = testnetColor {
            if Settings.sharedManager().target == Testnet {
                self.backgroundColor = color
            }
            else if Settings.sharedManager().target == Masternet{
                self.backgroundColor = UIColor.main.black
            }
        }
        #endif

        
        if let color = self.backgroundColor {
            self.setBackgroundColor(color: UIColor.init(red: 2/255, green: 86/255, blue: 100/255, alpha: 1), forState: .disabled)
            self.setBackgroundColor(color: color, forState: .normal)
            self.setBackgroundColor(color: color.withAlphaComponent(0.5), forState: .highlighted)
            self.backgroundColor = UIColor.clear
        }
        
        if let color = self.titleColor(for: .normal) {
            self.setTitleColor(color.withAlphaComponent(0.5), for: .highlighted)
        }
    }
}
