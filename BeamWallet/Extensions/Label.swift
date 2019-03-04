//
//  Label.swift
//  BeamWallet
//
//  Created by Denis on 3/2/19.
//  Copyright © 2019 Denis. All rights reserved.
//

import Foundation
import UIKit

extension UILabel {
    
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
                else if Device.screenType == .iPhones_5_5s_5c_SE{
                    newFontSize = newFontSize - 1.5
                }
                
                let oldFontName = font.fontName
                self.font = UIFont(name: oldFontName, size: newFontSize)
            }
        }
    }
}



