//
//  Field.swift
//  BeamWallet
//
// 3/2/19.
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

//extension UITextField {
//
//    var clearButtonTintColor: UIColor? {
//        get {
//            return clearButton?.tintColor
//        }
//        set {
//        }
//    }
//}

extension UITextField {
    
    public func disablePasswordAutoFill () {
        if #available(iOS 12, *) {
            // iOS 12: Not the best solution, but it works.
            self.textContentType = .oneTimeCode
        } else {
            // iOS 11: Disables the autofill accessory view.
            self.textContentType = .init(rawValue: "")
        }
    }
}

extension UITextField {
    
    @IBInspectable
    var localizationKey: String? {
        get {
            return self.localizationKey
        }
        set {
            if newValue != nil {
                self.placeholder = newValue?.localized
                self.placeHolderColor = UIColor.main.blueyGrey
            }
        }
    }
    
    @IBInspectable var placeHolderColor: UIColor? {
        get {
            return self.placeHolderColor
        }
        set {
            self.attributedPlaceholder = NSAttributedString(string:self.placeholder != nil ? self.placeholder! : String.empty(), attributes:[NSAttributedString.Key.foregroundColor: newValue!])
        }
    }
    
    @IBInspectable var placeHolderFont: UIFont? {
        get {
            return self.placeHolderFont
        }
        set {
            self.attributedPlaceholder = NSAttributedString(string:self.placeholder != nil ? self.placeholder! : String.empty(), attributes:[NSAttributedString.Key.foregroundColor: UIColor.white.withAlphaComponent(0.2), NSAttributedString.Key.font : ItalicFont(size: 16)])
        }
    }
    
    
    @IBInspectable
    var adjustFontSize: Bool {
        get {
            return self.adjustFontSize
        }
        set {
            if newValue {
                guard let font = self.font else {
                    return
                }
                var newFontSize = font.pointSize
                
                if Device.screenType == .iPhone_XSMax{
                    newFontSize = newFontSize + 1.0
                }
                else if Device.screenType == .iPhones_5{
                    newFontSize = newFontSize - 1.5
                }
                
                let oldFontName = font.fontName
                self.font = UIFont(name: oldFontName, size: newFontSize)
            }
        }
    }
    
}
