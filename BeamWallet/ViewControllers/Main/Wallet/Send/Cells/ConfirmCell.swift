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
    @IBOutlet weak private var categoryLabel: UILabel!
    @IBOutlet weak private var addressNameLabel: UILabel!

    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        selectionStyle = .none
    }
}

extension ConfirmCell: Configurable {
    
    func configure(with item:ConfirmItem) {
        categoryLabel.isHidden = true
        addressNameLabel.isHidden = true
        
        nameLabel.font = BoldFont(size: 14)
        nameLabel.textColor = UIColor.main.blueyGrey
        nameLabel.textAlignment = .left
        nameLabel.text = item.title
        nameLabel.letterSpacing = 2
        
        valueLabel.text = item.detail
        valueLabel.textColor = item.detailColor
        valueLabel.font = item.detailFont
        
        if item.detail == nil {
            nameLabel.letterSpacing = 0.001
            nameLabel.textAlignment = .center
            nameLabel.font = ItalicFont(size: 16)
            nameLabel.textColor = UIColor.white
        }
        else{
            valueLabel.adjustFontSize = true
        }
        
        nameLabel.adjustFontSize = true
        
        if item.title == LocalizableStrings.send_to || item.title == LocalizableStrings.outgoing_address {
            
            if let category = AppModel.sharedManager().findCategory(byAddress: item.detail ?? String.empty())
            {
                categoryLabel.isHidden = false
                categoryLabel.textColor = UIColor.init(hexString: category.color)
                categoryLabel.text = category.name
            }
            
            if let address = AppModel.sharedManager().findAddress(byID: item.detail ?? String.empty()) {
                if !address.label.isEmpty {
                    addressNameLabel.isHidden = false
                    addressNameLabel.text = address.label
                }
            }
        }
        
        
        if item.title == LocalizableStrings.send_to {
            
            let text = (item.detail)!
            
            let length = text.lengthOfBytes(using: .utf8)
            
            let att = NSMutableAttributedString(string: text, attributes: [NSAttributedString.Key.font : RegularFont(size: 16), NSAttributedString.Key.foregroundColor : UIColor.white])
            att.addAttribute(NSAttributedString.Key.foregroundColor, value: UIColor.main.heliotrope, range: NSRange(location: 0, length: 6))
            att.addAttribute(NSAttributedString.Key.foregroundColor, value: UIColor.main.heliotrope, range: NSRange(location: length-6, length: 6))
            
            valueLabel.attributedText = att
        }
    }
}
