//
//  BMField.swift
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

import UIKit

class BMField: UITextField {

    var line = UIView()

    private var _lineColor:UIColor?
    private var _lineHeight:CGFloat = 2

    @IBInspectable
    var lineColor: UIColor? {
        get {
            return _lineColor
        }
        set{
            _lineColor = newValue
            line.backgroundColor = _lineColor
        }
    }
    
    @IBInspectable
    var lineHeight: CGFloat {
        get {
            return _lineHeight
        }
        set{
            _lineHeight = newValue
            layoutSubviews()
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        if lineColor == nil {
            line.backgroundColor = UIColor.main.darkSlateBlue
        }
        
        addSubview(line)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()

        line.frame = CGRect(x: 0, y: self.frame.size.height-lineHeight, width: self.frame.size.width, height: lineHeight)
    }


}
