//
//  Label.swift
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

extension UILabel {
    
    func checkRange(_ range: NSRange, contain index: Int) -> Bool {
        return index > range.location && index < range.location + range.length
    }
    
    func indexOfAttributedTextCharacterAtPoint(point: CGPoint) -> Int {
        guard let attributedString = self.attributedText else { return -1 }
        
        let mutableAttribString = NSMutableAttributedString(attributedString: attributedString)
        // Add font so the correct range is returned for multi-line labels
        mutableAttribString.addAttributes([NSAttributedString.Key.font: font ?? UIFont.systemFont(ofSize: 16)], range: NSRange(location: 0, length: attributedString.length))
        
        let textStorage = NSTextStorage(attributedString: mutableAttribString)
        
        let layoutManager = NSLayoutManager()
        textStorage.addLayoutManager(layoutManager)
        
        let textContainer = NSTextContainer(size: frame.size)
        textContainer.lineFragmentPadding = 0
        textContainer.maximumNumberOfLines = numberOfLines
        textContainer.lineBreakMode = lineBreakMode
        layoutManager.addTextContainer(textContainer)
        
        let index = layoutManager.characterIndex(for: point, in: textContainer, fractionOfDistanceBetweenInsertionPoints: nil)
        return index
    }
}

extension UILabel {
    
    @IBInspectable
    var localizationKey: String? {
        get {
            return self.localizationKey
        }
        set {
            if newValue != nil {
                self.text = newValue?.localized
            }
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
                
                if Device.screenType == .iPhone_XSMax || Device.screenType == .iPhones_Plus {
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



