//
// Device.swift
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

class Device {
    
    static var isZoomed: Bool {
        let zoomed =  UIScreen.main.nativeScale > UIScreen.main.scale
        return zoomed
    }
    
    static var iPhoneX: Bool {
        return UIScreen.main.nativeBounds.height == 2436
    }
    static var iPhone: Bool {
        return UIDevice.current.userInterfaceIdiom == .phone
    }
    
    static var iPad: Bool {
        return UIDevice.current.userInterfaceIdiom == .pad
    }
    
    static var isLarge: Bool {
        return Device.screenType == .iPhone_XSMax || Device.screenType == .iPhones_Plus
    }
    
    enum ScreenType: String {
        case iPhones_4 = "iPhone 4 or iPhone 4S"
        case iPhones_5 = "iPhone 5, iPhone 5s, iPhone 5c or iPhone SE"
        case iPhones_6 = "iPhone 6, iPhone 6S, iPhone 7 or iPhone 8"
        case iPhones_Plus = "iPhone 6 Plus, iPhone 6S Plus, iPhone 7 Plus or iPhone 8 Plus"
        case iPhones_X_XS = "iPhone X or iPhone XS"
        case iPhone_XR = "iPhone XR"
        case iPhone_XSMax = "iPhone XS Max"
        case unknown
    }
    static var screenType: ScreenType {
        if Device.iPad {
            return .iPhones_5
        }
        else{
            switch UIScreen.main.nativeBounds.height {
            case 960:
                return .iPhones_4
            case 1136:
                return .iPhones_5
            case 1334:
                return .iPhones_6
            case 1792:
                return .iPhone_XR
            case 1920, 2208:
                return .iPhones_Plus
            case 2436:
                return .iPhones_X_XS
            case 2688:
                return .iPhone_XSMax
            default:
                return .unknown
            }
        }
    }
}
