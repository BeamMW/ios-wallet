//
//  ConfirmCell.swift
//  BeamWallet
//
//  Created by Denis on 6/4/19.
//  Copyright © 2019 Denis. All rights reserved.
//

import UIKit

class ConfirmCell: BaseCell {

    @IBOutlet weak private var nameLabel: UILabel!
    @IBOutlet weak private var valueLabel: UILabel!

    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        selectionStyle = .none
    }
}

extension ConfirmCell: Configurable {
    
    func configure(with item:ConfirmItem) {
        nameLabel.font = BoldFont(size: 14)
        nameLabel.textColor = UIColor.main.blueyGrey
        nameLabel.textAlignment = .left
        nameLabel.text = item.title
        nameLabel.letterSpacing = 2
        
        valueLabel.text = item.detail
        valueLabel.textColor = item.detailColor
        valueLabel.font = item.detailFont
        
        if item.detail == nil {
            nameLabel.letterSpacing = 1
            nameLabel.textAlignment = .center
            nameLabel.font = ItalicFont(size: 16)
            nameLabel.textColor = UIColor.white
        }
        else{
            valueLabel.adjustFontSize = true
        }
        
        nameLabel.adjustFontSize = true
    }
}
