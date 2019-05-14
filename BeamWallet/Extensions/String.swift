//
// String.swift
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

import UIKit
import Network

protocol Localizable {
    var localized: String { get }
}

extension String: Localizable {
    var localized: String {
        return NSLocalizedString(self, comment: "")
    }
}

extension String {
    func countInstances(of stringToFind: String) -> Int {
        assert(!stringToFind.isEmpty)
        var count = 0
        var searchRange: Range<String.Index>?
        while let foundRange = range(of: stringToFind, options: [], range: searchRange) {
            count += 1
            searchRange = Range(uncheckedBounds: (lower: foundRange.upperBound, upper: endIndex))
        }
        return count
    }
}

extension String {
    func isValidPort() -> Bool {
        if let d = Int(self) {
            if(d > 0 && d <= 65535) {
                return true
            }
        }
        
        return false
    }
    
    func isNumeric() -> Bool {
        let allowedCharacters = CharacterSet(charactersIn:"0123456789")
        let characterSet = CharacterSet(charactersIn: self)
        
        if (!allowedCharacters.isSuperset(of: characterSet)) {
            return false
        }
        
        return true
    }
    
    func isDecimial() -> Bool {
        let allowedCharacters = CharacterSet(charactersIn:".0123456789")
        let characterSet = CharacterSet(charactersIn: self)
        
        if (!allowedCharacters.isSuperset(of: characterSet)) {
            return false
        }
        
        return true
    }
}

extension String {
    
    static let formatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.currencyCode = ""
        formatter.currencySymbol = ""
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = 10
        formatter.numberStyle = .currencyAccounting
        formatter.locale = Locale(identifier: "en_US")

        return formatter
    }()
    
    static func currency(value:Double) -> String {
        return formatter.string(from: NSNumber(value: value)) ?? "0.00"
    }
    
    func isValidUrl() -> Bool {
        let urlRegEx = "^(https?://)?(www\\.)?([-a-z0-9]{1,63}\\.)*?[a-z0-9][-a-z0-9]{0,61}[a-z0-9]\\.[a-z]{2,6}(/[-\\w@\\+\\.~#\\?&/=%]*)?$"
        let urlTest = NSPredicate(format:"SELF MATCHES %@", urlRegEx)
        let result = urlTest.evaluate(with: self)
        return result
    }
    
    func isValidIp() -> Bool {
        if #available(iOS 12.0, *) {
            if let _ = IPv4Address(self) {
                return true
            } else if let _ = IPv6Address(self) {
                return true
            } else {
                return false
            }
        } else {
            return true
        }
    }
}

extension NSAttributedString {
    func rangesOf(subString: String) -> [NSRange] {
        var nsRanges: [NSRange] = []
        let ranges = string.ranges(of: subString, options: .caseInsensitive, locale: nil)
        
        for range in ranges {
            nsRanges.append(NSRange(range, in: self.string))
        }
        
        return nsRanges
    }
}

extension String {
    func ranges(of substring: String, options: CompareOptions = [], locale: Locale? = nil) -> [Range<Index>] {
        var ranges: [Range<Index>] = []
        while let range = self.range(of: substring, options: options, range: (ranges.last?.upperBound ?? self.startIndex) ..< self.endIndex, locale: locale) {
            ranges.append(range)
        }
        return ranges
    }
}

extension String {
    
    static func empty() -> String {
        return ""
    }
}
