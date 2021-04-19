//
// BMMultiLinesCell.swift
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

class BMCopyCell: BaseCell {
    
    weak var delegate: GeneralInfoCellDelegate?
    
    @IBOutlet weak private var nameLabel: UILabel!
    @IBOutlet weak private var valueLabel: BMCopyLabel!

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
    
    public var maxLines = 0 {
        didSet {
            valueLabel.numberOfLines = maxLines
            valueLabel.adjustsFontSizeToFitWidth = false
            valueLabel.adjustFontSize = false
            valueLabel.lineBreakMode = .byTruncatingMiddle
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        
        selectionStyle = .none
    }
    
    @IBAction private func onCopy() {
        UIPasteboard.general.string = valueLabel.copyText ?? ""
                
        ShowCopied(text: Localizable.shared.strings.address_copied)
    }
}

extension BMCopyCell: Configurable {
    
    func configure(with item:BMMultiLineItem) {
        valueLabel.isUserInteractionEnabled = item.canCopy
        valueLabel.copiedText = item.copiedText
        
        if let c = item.copyValue {
            valueLabel.copyText = c
        }
        else {
            valueLabel.copyText = item.detail
        }
        
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
        
        nameLabel.adjustFontSize = true
        valueLabel.adjustFontSize = true
    }
}
