//
//  String.swift
//  BeamWallet
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

import UIKit

extension String {
    static func currency(value:Double) -> String {
        let formatter = NumberFormatter()
        formatter.currencyCode = ""
        formatter.currencySymbol = ""
        formatter.minimumFractionDigits =  2
        formatter.maximumFractionDigits = 10
        formatter.numberStyle = .currencyAccounting
        
        var s = formatter.string(from: NSNumber(value: value))!
        
        return s
        
//        let currencyFormatter = NumberFormatter()
//        currencyFormatter.usesGroupingSeparator = true
//        currencyFormatter.numberStyle = .decimal
//        currencyFormatter.locale = Locale.current
//        currencyFormatter.currencyCode = ""
//        currencyFormatter.currencySymbol = ""
//        currencyFormatter.minimumIntegerDigits = 0;
//        currencyFormatter.minimumFractionDigits = 0;
//        currencyFormatter.minimumSignificantDigits = 0;
//        currencyFormatter.maximumIntegerDigits = 15;
//        currencyFormatter.maximumFractionDigits = 15;
//        currencyFormatter.maximumSignificantDigits = 15;
//        currencyFormatter.roundingMode = .floor
//
//        var s = currencyFormatter.string(from: NSNumber(value: value))!
//
//        //hack for 0.999999999 -> 0.9
//        if s.contains(".")
//        {
//            let array = s.split(separator: ".")
//            let last = array[array.count-1]
//            let characters = Array(last)
//            var isSame = true
//            let first = characters[0]
//
//            for ch in characters {
//                if ch != first {
//                    isSame = false
//                }
//            }
//
//            if isSame {
//                s = s.replacingOccurrences(of: last, with: String(first))
//            }
//        }
//
//        return s
    }
}
