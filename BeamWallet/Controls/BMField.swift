//
//  BMField.swift
//  BeamWallet
//
//  Created by Denis on 3/1/19.
//  Copyright © 2019 Denis. All rights reserved.
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
