//
//  BMMultiLinesCell.swift
//  BeamWallet
//
//  Created by Denis on 6/4/19.
//  Copyright © 2019 Denis. All rights reserved.
//

import UIKit

class BMMultiLinesCell: BaseCell {

    @IBOutlet weak private var nameLabel: UILabel!
    @IBOutlet weak private var valueLabel: BMCopyLabel!
    @IBOutlet weak private var categoryLabel: UILabel!
    @IBOutlet weak private var addressNameLabel: UILabel!
    @IBOutlet weak private var stackView: UIStackView!
    @IBOutlet weak private var topOffset: NSLayoutConstraint!
    @IBOutlet weak private var botOffset: NSLayoutConstraint!

    public var increaseSpace = false {
        didSet {
            if increaseSpace {
                stackView.spacing = 10
                topOffset.constant = 15
                botOffset.constant = 15
            }
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        selectionStyle = .none
    }
}

extension BMMultiLinesCell: Configurable {
    
    func configure(with item:BMMultiLineItem) {
        valueLabel.isUserInteractionEnabled = item.canCopy
        
        categoryLabel.isHidden = true
        addressNameLabel.isHidden = true
        nameLabel.isHidden = false

        nameLabel.font = BoldFont(size: 14)
        nameLabel.textColor = UIColor.main.blueyGrey
        nameLabel.textAlignment = .left
       
        if item.detail == nil {
            nameLabel.text = item.title
        }
        else if item.title != nil {
            nameLabel.text = item.title.uppercased()
        }
        else if item.title == nil {
            nameLabel.isHidden = true
        }
        
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
        
        if item.title == Localizable.shared.strings.send_to || item.title == Localizable.shared.strings.outgoing_address.uppercased() {
            
            let address = AppModel.sharedManager().findAddress(byID: item.detail ?? String.empty())
            
            if address?.categories.count ?? 0 > 0
            {
                categoryLabel.isHidden = false
                categoryLabel.attributedText = address?.categoriesName()
            }
            
            if let address = AppModel.sharedManager().findAddress(byID: item.detail ?? String.empty()) {
                if !address.label.isEmpty {
                    addressNameLabel.isHidden = false
                    addressNameLabel.text = address.label
                }
            }
        }
        
        
        if item.title == Localizable.shared.strings.send_to {
            
            let text = (item.detail)!
            
            let length = text.lengthOfBytes(using: .utf8)
            
            let att = NSMutableAttributedString(string: text, attributes: [NSAttributedString.Key.font : RegularFont(size: 16), NSAttributedString.Key.foregroundColor : UIColor.white])
            att.addAttribute(NSAttributedString.Key.foregroundColor, value: UIColor.main.heliotrope, range: NSRange(location: 0, length: 6))
            att.addAttribute(NSAttributedString.Key.foregroundColor, value: UIColor.main.heliotrope, range: NSRange(location: length-6, length: 6))
            
            valueLabel.attributedText = att
        }
        
        if item.detailAttributedString != nil {
            valueLabel.attributedText = item.detailAttributedString
        }
    }
}
