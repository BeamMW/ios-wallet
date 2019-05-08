//
// Color.swift
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

extension UIColor {

    convenience init(hexString: String) {
        let hex = hexString.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int = UInt32()
        Scanner(string: hex).scanHexInt32(&int)
        let a, r, g, b: UInt32
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(red: CGFloat(r) / 255, green: CGFloat(g) / 255, blue: CGFloat(b) / 255, alpha: CGFloat(a) / 255)
    }
    
    func toHexString() -> String {
        var r:CGFloat = 0
        var g:CGFloat = 0
        var b:CGFloat = 0
        var a:CGFloat = 0
        
        getRed(&r, green: &g, blue: &b, alpha: &a)
        
        let rgb:Int = (Int)(r*255)<<16 | (Int)(g*255)<<8 | (Int)(b*255)<<0
        
        return NSString(format:"#%06x", rgb) as String
    }
}

extension UIColor {

    enum category {
        
        static var veryLightPink50: UIColor {
            return .init(red: 216/255, green: 216/255, blue: 216/255, alpha: 0.5)
        }
    }
    
    
    enum main {
        
        static var veryLightPink50: UIColor {
            return .init(red: 216/255, green: 216/255, blue: 216/255, alpha: 0.5)
        }
        
        static var darkSlateBlue: UIColor {
            if Settings.sharedManager().target == Masternet{
                return UIColor.main.black
            }
            return .init(red: 28/255, green: 67/255, blue: 91/255, alpha: 1)
        }
        
        static var marine: UIColor {
            if Settings.sharedManager().target == Testnet {
                return UIColor.main.dark
            }
            else if Settings.sharedManager().target == Masternet{
                return UIColor.main.blackTwo
            }
            return .init(red: 3/255, green: 46/255, blue: 73/255, alpha: 1)
        }
        
        static var green: UIColor {
            return .init(red: 0, green: 246/255, blue: 210/255, alpha: 1)
        }
        
        static var red: UIColor {
            return .init(red: 255/255, green: 98/255, blue: 92/255, alpha: 1)
        }
        
        static var maize: UIColor {
            return .init(red: 244/255, green: 206/255, blue: 74/255, alpha: 1)
        }
        
        static var brightTeal: UIColor {
            return .init(red: 0/255, green: 246/255, blue: 210/255, alpha: 1)
        }
        
        static var black: UIColor {
            return .init(red: 36/255, green: 36/255, blue: 36/255, alpha: 1)
        }
        
        static var blackTwo: UIColor {
            return .init(red: 23/255, green: 23/255, blue: 23/255, alpha: 1)
        }
        
        static var navy: UIColor {
            if Settings.sharedManager().target == Testnet {
                return UIColor.main.dark
            }
            else if Settings.sharedManager().target == Masternet{
                return .init(red: 16/255, green: 16/255, blue: 16/255, alpha: 1)
            }
            return .init(red: 2/255, green: 37/255, blue: 60/255, alpha: 1)
        }
        
        static var blueyGrey: UIColor {
            return .init(red: 141/255, green: 161/255, blue: 173/255, alpha: 1)
        }
        
        static var marineTwo: UIColor {
            if Settings.sharedManager().target == Testnet {
                return UIColor.main.darkTwo
            }
            else if Settings.sharedManager().target == Masternet{
                return UIColor.main.black
            }
            return .init(red: 10/255, green: 52/255, blue: 77/255, alpha: 1)
        }
        
        static var heliotrope: UIColor {
            return .init(red: 218/255, green: 104/255, blue: 245/255, alpha: 1)
        }
        
        static var brightSkyBlue: UIColor {
            return .init(red: 11/255, green: 204/255, blue: 247/255, alpha: 1)
        }
        
        static var dark: UIColor {
            return .init(red: 30/255, green: 23/255, blue: 44/255, alpha: 1)
        }
        
        static var darkTwo: UIColor {
            return .init(red: 40/255, green: 34/255, blue: 54/255, alpha: 1)
        }
        
        static var orange: UIColor {
            return .init(red: 241/255, green: 196/255, blue: 15/255, alpha: 1)
        }
    }
    
}
