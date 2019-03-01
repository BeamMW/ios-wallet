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

    override func awakeFromNib() {
        super.awakeFromNib()
        
        line.backgroundColor = UIColor.main.darkSlateBlue
        
        addSubview(line)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()

        line.frame = CGRect(x: 0, y: self.frame.size.height-1, width: self.frame.size.width, height: 1)

//        if(isEditing)
//        {
//            line.frame = CGRect(x: 0, y: self.frame.size.height-2, width: self.frame.size.width, height: 2)
//        }
//        else{
//            line.frame = CGRect(x: 0, y: self.frame.size.height-1, width: self.frame.size.width, height: 1)
//        }
    }

    
//    override func resignFirstResponder() -> Bool {
//        line.frame = CGRect(x: 0, y: self.frame.size.height-1, width: self.frame.size.width, height: 1)
//
//        return super.resignFirstResponder()
//    }
//
//    override func becomeFirstResponder() -> Bool {
//        line.frame = CGRect(x: 0, y: self.frame.size.height-2, width: self.frame.size.width, height: 2)
//
//        return super.becomeFirstResponder()
//    }
}
