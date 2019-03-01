//
//  DesignableButton.swift
//  BeamWallet
//
//  Created by Denis on 2/28/19.
//  Copyright © 2019 Denis. All rights reserved.
//

import Foundation
import UIKit

@IBDesignable
class BMButton: UIButton {
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        if let color = self.backgroundColor {
            self.setBackgroundColor(color: UIColor.init(red: 2/255, green: 86/255, blue: 100/255, alpha: 1), forState: .disabled)
            self.setBackgroundColor(color: color, forState: .normal)
            self.setBackgroundColor(color: color.withAlphaComponent(0.5), forState: .highlighted)
            self.backgroundColor = UIColor.clear
        }
        
        if let color = self.titleColor(for: .normal) {
            self.setTitleColor(color.withAlphaComponent(0.5), for: .highlighted)
        }
    }
}
