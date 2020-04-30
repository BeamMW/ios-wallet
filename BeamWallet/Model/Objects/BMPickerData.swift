//
// BMPickerData.swift
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

class BMPickerData: NSObject {
    
    enum ArrowType {
         case none
         case unselected
         case selected
     }
    
    public var title:String!
    public var detail:String?
    public var titleColor:UIColor?
    public var arrowType:ArrowType?
    public var unique:Any?
    public var multiplie:Bool = false
    public var isSwitch:Bool = false

    required init(title:String!, detail:String?, titleColor:UIColor?, arrowType:ArrowType?, unique:Any?, multiplie:Bool = false, isSwitch:Bool = false) {
        self.title = title
        self.detail = detail
        self.arrowType = arrowType
        self.titleColor = titleColor
        self.unique = unique
        self.multiplie = multiplie
        self.isSwitch = isSwitch
    }
}
