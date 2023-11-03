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
import CommonCrypto


extension String {
    func convertStringToDictionary() -> [String:AnyObject]? {
        if let data = self.data(using: .utf8) {
            do {
                let json = try JSONSerialization.jsonObject(with: data, options: .mutableContainers) as? [String:AnyObject]
                return json
            } catch {
                print("Something went wrong")
            }
        }
        return nil
    }
}

extension String {
    var md5Value: String {
        let length = Int(CC_MD5_DIGEST_LENGTH)
        var digest = [UInt8](repeating: 0, count: length)
        
        if let d = self.data(using: .utf8) {
            _ = d.withUnsafeBytes { body -> String in
                CC_MD5(body.baseAddress, CC_LONG(d.count), &digest)
                return ""
            }
        }
        return (0 ..< length).reduce("") {
            $0 + String(format: "%02x", digest[$1])
        }
    }
}

extension String {
    var localized: String {
        let lang = Settings.sharedManager().language
        
        let remotePath = CrowdinManager.localizationPath.appendingPathComponent(lang)

        var result = ""
        
        if FileManager.default.fileExists(atPath: remotePath.path) {
            if let bundle = Bundle(path: remotePath.path) {
                result =  NSLocalizedString(self, tableName: nil, bundle: bundle, value: "", comment: "")
            }
        }
        else {
            let path = Bundle.main.path(forResource: lang, ofType: "lproj")
            if(path == nil )
            {
                let bundle =  Bundle(path: Bundle.main.path(forResource: "en", ofType: "lproj")!)!
                result = NSLocalizedString(self, tableName: nil, bundle: bundle, value: "", comment: "")
            }
            else{
                let bundle = Bundle(path: path!)
                result = NSLocalizedString(self, tableName: nil, bundle: bundle!, value: "", comment: "")
            }
        }
        
        if result == self {
            let bundle =  Bundle(path: Bundle.main.path(forResource: "en", ofType: "lproj")!)!
            result = NSLocalizedString(self, tableName: nil, bundle: bundle, value: "", comment: "")
        }
        
        return result
    }
}

extension String {
    
    func capitalizingFirstLetter() -> String {
        let lowerCasedString = self.lowercased()
        return lowerCasedString.replacingCharacters(in: lowerCasedString.startIndex...lowerCasedString.startIndex, with: String(lowerCasedString[lowerCasedString.startIndex]).uppercased())
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
    
    static func currencyWithoutName(value:Double) -> String {
        return (formatter.string(from: NSNumber(value: value)) ?? "0.00")
    }
    
    static func currency(value:Double) -> String {
        if Settings.sharedManager().isHideAmounts {
            return "BEAM"
        }
        return (formatter.string(from: NSNumber(value: value)) ?? "0.00") + " BEAM"
    }
    
    static func currencyWithoutPrivacy(value:Double, name: String) -> String {
        var assetName = name
        if assetName == "assets" {
            assetName = "BEAM"
        }
        return (formatter.string(from: NSNumber(value: value)) ?? "0.00") + " \(assetName)"
    }
    
    static func currency(value:Double, name: String) -> String {
        var assetName = name
        if assetName == "assets" {
            assetName = "BEAM"
        }
        if Settings.sharedManager().isHideAmounts {
            return assetName
        }
        return ((formatter.string(from: NSNumber(value: value)) ?? "0.00") + " \(assetName)").replacingOccurrences(of: "(", with: "").replacingOccurrences(of: ")", with: "")
    }
    
    static func currencyShort(value:Double, name: String) -> String {
        var assetName = name
        if assetName == "assets" {
            assetName = "BEAM"
        }
        if assetName.count > 10 {
            assetName = assetName.prefix(10) + "..."
        }
        if Settings.sharedManager().isHideAmounts {
            return assetName
        }
        return ((formatter.string(from: NSNumber(value: value)) ?? "0.00") + " \(assetName)").replacingOccurrences(of: "(", with: "").replacingOccurrences(of: ")", with: "")
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
    
    static func coma() -> String {
        return ","
    }
    
    static func dot() -> String {
        return "."
    }
}


extension String {
    
    var trailingSpacesTrimmed: String {
        var newString = self
        
        while newString.last?.isWhitespace == true {
            newString = String(newString.dropLast())
        }
        
        return newString
    }
    
    func isCorrectAmount(fee:Double = 0) -> Bool {
        let mainCount = 9
        let comaCount = 8
        
        let txtAfterUpdate = self
        
        if Double(txtAfterUpdate) == nil && !txtAfterUpdate.isEmpty {
            return false
        }
        
        if (!txtAfterUpdate.isDecimial()) {
            return false
        }
        
        if !txtAfterUpdate.isEmpty {
            let split = txtAfterUpdate.split(separator: ".")
            if split[0].lengthOfBytes(using: .utf8) > mainCount {
                return false
            }
            else if split.count > 1 {
                if split[1].lengthOfBytes(using: .utf8) > comaCount {
                    return false
                }
                else if split[1].lengthOfBytes(using: .utf8) == comaCount && Double(txtAfterUpdate) == 0 {
                    return false
                }
            }
        }
        
        if let amount = Double(txtAfterUpdate) {
           
            if AppModel.sharedManager().canReceive(amount, fee: fee) != nil {
                return false
            }
            else if amount == 0 && txtAfterUpdate.contains(".") == false && txtAfterUpdate.lengthOfBytes(using: .utf8) > 1 {
                return false
            }
            else if amount > 0 && txtAfterUpdate.contains(".") == false && txtAfterUpdate.lengthOfBytes(using: .utf8) > 1 && txtAfterUpdate.first == "0" {
                return false
            }
        }
        
        return true
    }
}

extension String {
    func boundingWidth(with font: UIFont, kern:CGFloat = 0.1) -> CGFloat {
        let size = CGSize(width: CGFloat.greatestFiniteMagnitude, height: font.lineHeight)
        let preferredRect = (self as NSString).boundingRect(with: size, options: [.usesLineFragmentOrigin, .usesFontLeading], attributes: [NSAttributedString.Key.font: font, NSAttributedString.Key.kern: kern], context: nil)
        return ceil(preferredRect.width)
    }
    
    func height(withConstrainedWidth width: CGFloat, font: UIFont) -> CGFloat {
        let constraintRect = CGSize(width: width, height: .greatestFiniteMagnitude)
        let boundingBox = (self as NSString).boundingRect(with: constraintRect, options: .usesLineFragmentOrigin, attributes: [NSAttributedString.Key.font: font], context: nil)
        return ceil(boundingBox.height)
    }
}

extension String {
    func splitAddress() -> String {
        return "\(self.prefix(6))...\(self.suffix(6))"
    }
    
    func to_base58() -> String {
        let str = self
        return str
    }

}
