//
//  Color.swift
//  BeamWallet
//
// 3/1/19.
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

    enum main {
        
        static var veryLightPink50: UIColor {
            return .init(red: 216/255, green: 216/255, blue: 216/255, alpha: 0.5)
        }
        
        static var darkSlateBlue: UIColor {
            return .init(red: 28/255, green: 67/255, blue: 91/255, alpha: 1)
        }
        
        static var marine: UIColor {
            if AppDelegate.CurrentTarget == .Test {
                return UIColor.main.dark
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
        
        static var navy: UIColor {
            if AppDelegate.CurrentTarget == .Test {
                return UIColor.main.dark
            }
            return .init(red: 2/255, green: 37/255, blue: 60/255, alpha: 1)
        }
        
        static var blueyGrey: UIColor {
            return .init(red: 141/255, green: 161/255, blue: 173/255, alpha: 1)
        }
        
        static var marineTwo: UIColor {
            if AppDelegate.CurrentTarget == .Test {
                return UIColor.main.darkTwo
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
    }
    
}
