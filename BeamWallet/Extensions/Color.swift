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
        var r: CGFloat = 0
        var g: CGFloat = 0
        var b: CGFloat = 0
        var a: CGFloat = 0
        
        getRed(&r, green: &g, blue: &b, alpha: &a)
        
        let rgb: Int = (Int)(r * 255) << 16 | (Int)(g * 255) << 8 | (Int)(b * 255) << 0
        
        return NSString(format: "#%06x", rgb) as String
    }
}

extension UIColor {
    enum category {
        static var veryLightPink50: UIColor {
            return .init(red: 216 / 255, green: 216 / 255, blue: 216 / 255, alpha: 0.5)
        }
    }
    
    enum main {
        static var veryLightPink50: UIColor {
            return .init(red: 216 / 255, green: 216 / 255, blue: 216 / 255, alpha: 0.5)
        }
        
        static var cyan15: UIColor {
            return .init(red: 0.0, green: 240.0 / 255.0, blue: 1.0, alpha: 0.15)
        }
        
        static var darkSlateBlue: UIColor {
            if Settings.sharedManager().target == Masternet {
                return UIColor.main.black
            }
            return .init(red: 28 / 255, green: 67 / 255, blue: 91 / 255, alpha: 1)
        }
        
        static var marine: UIColor {
            if Settings.sharedManager().isDarkMode {
                return UIColor.black
            }
            else if Settings.sharedManager().target == Testnet {
                return UIColor.main.dark
            }
            else if Settings.sharedManager().target == Masternet {
                return UIColor.main.blackTwo
            }
            return .init(red: 4 / 255, green: 37 / 255, blue: 72 / 255, alpha: 1)
        }
        
        static var marineThree: UIColor {
            if Settings.sharedManager().isDarkMode {
                return .init(red: 20 / 255, green: 20 / 255, blue: 20 / 255, alpha: 1)
            }
            return UIColor.white.withAlphaComponent(0.02)
        }
        
        static var cellBackgroundColor: UIColor {
             if Settings.sharedManager().isDarkMode {
                return .init(red: 12 / 255, green: 12 / 255, blue: 12 / 255, alpha: 1)
             }
             return UIColor.white.withAlphaComponent(0.02)
         }
        
        static var gasine: UIColor {
             return .init(red: 4 / 255, green: 37 / 255, blue: 72 / 255, alpha: 1)
         }
                
        static var selectedColor: UIColor {
            if Settings.sharedManager().isDarkMode {
                return .init(red: 28 / 255, green: 28 / 255, blue: 30 / 255, alpha: 1)
            }
            return .init(red: 0 / 255, green: 0 / 255, blue: 0 / 255, alpha: 0.002)
        }
        
        static var marineThree2: UIColor {
            return .init(red: 4 / 255, green: 37 / 255, blue: 72 / 255, alpha: 1)
        }
        
        static var twilightBlue2: UIColor {
            if Settings.sharedManager().isDarkMode {
                return .init(red: 28 / 255, green: 28 / 255, blue: 30 / 255, alpha: 1)
            }
            else if Settings.sharedManager().target == Testnet {
                return .init(red: 28 / 255, green: 23 / 255, blue: 41 / 255, alpha: 1)
            }
            else if Settings.sharedManager().target == Masternet {
                return .init(red: 12 / 255, green: 12 / 255, blue: 12 / 255, alpha: 1)
            }
            return .init(red: 4 / 255, green: 37 / 255, blue: 72 / 255, alpha: 1)
        }
        
        static var twilightBlue: UIColor {
            if Settings.sharedManager().isDarkMode {
                return .init(red: 28 / 255, green: 28 / 255, blue: 30 / 255, alpha: 1)
            }
            else if Settings.sharedManager().target == Testnet {
                return .init(red: 27 / 255, green: 32 / 255, blue: 57 / 255, alpha: 1)
            }
            else if Settings.sharedManager().target == Masternet {
                return .init(red: 23 / 255, green: 43 / 255, blue: 60 / 255, alpha: 1)
            }
            return .init(red: 23 / 255, green: 57 / 255, blue: 97 / 255, alpha: 1)
        }
        
        static var green: UIColor {
            return .init(red: 0, green: 246 / 255, blue: 210 / 255, alpha: 1)
        }
        
        static var red: UIColor {
            return .init(red: 255 / 255, green: 98 / 255, blue: 92 / 255, alpha: 1)
        }
        
        static var maize: UIColor {
            return .init(red: 244 / 255, green: 206 / 255, blue: 74 / 255, alpha: 1)
        }
        
        static var steelGrey: UIColor {
            return .init(red: 112 / 255, green: 128 / 255, blue: 138 / 255, alpha: 1)
        }
        
        static var brightTeal: UIColor {
            return .init(red: 0 / 255, green: 246 / 255, blue: 210 / 255, alpha: 1)
        }
        
        static var black: UIColor {
            return .init(red: 36 / 255, green: 36 / 255, blue: 36 / 255, alpha: 1)
        }
        
        static var blackTwo: UIColor {
            return .init(red: 23 / 255, green: 23 / 255, blue: 23 / 255, alpha: 1)
        }
        
        static var navy: UIColor {
            if Settings.sharedManager().target == Testnet {
                return UIColor.main.dark
            }
            else if Settings.sharedManager().target == Masternet {
                return .init(red: 16 / 255, green: 16 / 255, blue: 16 / 255, alpha: 1)
            }
            return .init(red: 2 / 255, green: 37 / 255, blue: 60 / 255, alpha: 1)
        }
        
        static var blueyGrey: UIColor {
            if(Settings.sharedManager().isDarkMode) {
                return UIColor.main.steel
            }
            return .init(red: 141 / 255, green: 161 / 255, blue: 173 / 255, alpha: 1)
        }
        
        static var heliotrope: UIColor {
            return .init(red: 218 / 255, green: 104 / 255, blue: 245 / 255, alpha: 1)
        }
        
        static var brightSkyBlue: UIColor {
            return .init(red: 11 / 255, green: 204 / 255, blue: 247 / 255, alpha: 1)
        }
        
        static var dark: UIColor {
            return .init(red: 30 / 255, green: 23 / 255, blue: 44 / 255, alpha: 1)
        }
        
        static var darkTwo: UIColor {
            return .init(red: 40 / 255, green: 34 / 255, blue: 54 / 255, alpha: 1)
        }
        
        static var orange: UIColor {
            return .init(red: 241 / 255, green: 196 / 255, blue: 15 / 255, alpha: 1)
        }
        
        static var marineOriginal: UIColor {
            return .init(red: 13 / 255, green: 37 / 255, blue: 69 / 255, alpha: 1)
        }
        
        static var brightBlue: UIColor {
            return .init(red: 9 / 255, green: 118 / 255, blue: 255 / 255, alpha: 1)
        }
        
        static var steel: UIColor {
            return .init(red: 142 / 255, green: 142 / 255, blue: 147 / 255, alpha: 1)
        }
        
        static var orangeRed: UIColor {
            return .init(red: 255 / 255, green: 59 / 255, blue: 48 / 255, alpha: 1)
        }
        
        static var warmBlue: UIColor {
            return .init(red: 88 / 255, green: 86 / 255, blue: 214 / 255, alpha: 1)
        }
        
        static var greyish: UIColor {
            return .init(hexString: "#a4a4a4")
        }
        
        static var cyan: UIColor {
            return .init(red: 0 / 255, green: 240 / 255, blue: 255 / 255, alpha: 1)
        }
        
        static var peacockBlue: UIColor {
            if Settings.sharedManager().target == Testnet {
                return .init(red: 76 / 255, green: 54 / 255, blue: 119 / 255, alpha: 1)
            }
            else if Settings.sharedManager().target == Masternet {
                return .init(red: 66 / 255, green: 66 / 255, blue: 66 / 255, alpha: 1)
            }
            return .init(red: 3 / 255, green: 91 / 255, blue: 143 / 255, alpha: 1)
        }
        
        static var darkIndigo: UIColor {
            return .init(red: 9 / 255, green: 28 / 255, blue: 48 / 255, alpha: 1)
        }
        
        static var cerulean: UIColor {
            return .init(red: 0 / 255, green: 119 / 255, blue: 191 / 255, alpha: 1)
        }
        
        static var deepSeaBlue: UIColor {
            return .init(red: 3 / 255, green: 85 / 255, blue: 135 / 255, alpha: 1)
        }
        
        static var coral: UIColor {
            return .init(red: 242 / 255, green: 95 / 255, blue: 91 / 255, alpha: 1)
        }
        
        static var navyTwo: UIColor {
            if Settings.sharedManager().target == Testnet {
                return .init(red: 26 / 255, green: 19 / 255, blue: 45 / 255, alpha: 1)
            }
            else if Settings.sharedManager().target == Masternet {
                return .init(red: 16 / 255, green: 16 / 255, blue: 16 / 255, alpha: 1)
            }
            return .init(red: 4 / 255, green: 29 / 255, blue: 60 / 255, alpha: 1)
        }
        
        static var deepSeaBlueTwo: UIColor {
            if Settings.sharedManager().target == Testnet {
                return .init(red: 52 / 255, green: 39 / 255, blue: 77 / 255, alpha: 1)
            }
            else if Settings.sharedManager().target == Masternet {
                return .init(red: 41 / 255, green: 41 / 255, blue: 41 / 255, alpha: 1)
            }
            return .init(red: 0 / 255, green: 81 / 255, blue: 134 / 255, alpha: 1)
        }
        
        static var blurBackground: UIColor {
            return .init(red: 2 / 255, green: 37 / 255, blue: 60 / 255, alpha: 0.8)
        }
    }
}
