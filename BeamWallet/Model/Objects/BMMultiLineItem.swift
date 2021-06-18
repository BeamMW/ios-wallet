//
// BMMultiLineItem.swift
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

struct BMThreeLineItem {
    public var title:String
    public var detail:String
    public var subDetail:String
    
    public var titleColor:UIColor
    public var detailColor:UIColor
    public var subDetailColor:UIColor
    
    public var titleFont:UIFont
    public var detailFont:UIFont
    public var subDetailFont:UIFont

    public var hasArrow:Bool
    public var expand = true
    
    public var accessoryName:String? = nil
}

class BMMultiLineItem {
    public var title:String!
    public var detail:String?
    public var detailFont:UIFont?
    public var detailColor:UIColor?
    public var detailAttributedString:NSMutableAttributedString?
    public var canCopy = false
    public var copiedText: String? = nil
    public var copyValue: String? = nil

    required init(title:String!, detail:String?, detailFont:UIFont?, detailColor:UIColor?) {
        self.title = title
        self.detail = detail
        self.detailFont = detailFont
        self.detailColor = detailColor
    }
    
    required init(title:String!, detail:String?, detailFont:UIFont?, detailColor:UIColor?, copy:Bool) {
        self.title = title
        self.detail = detail
        self.detailFont = detailFont
        self.detailColor = detailColor
        self.canCopy = copy
    }
    
    required init(title:String!, detail:String?, detailFont:UIFont?, detailColor:UIColor?, copy:Bool, copiedText:String?) {
        self.title = title
        self.detail = detail
        self.detailFont = detailFont
        self.detailColor = detailColor
        self.canCopy = copy
        self.copiedText = copiedText
    }
}
