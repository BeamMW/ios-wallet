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

class BMMultiLinesCell2: BaseCell {
    
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
        
        valueLabel.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(titleLabelTapGestureAction(_:))))
        
        selectionStyle = .none
    }
    
    @objc private func titleLabelTapGestureAction(_ sender: UITapGestureRecognizer) {
        
        if let text = self.valueLabel.attributedText {
            let title = NSString(string: text.string)
            
            let tapRange = title.range(of: Localizable.shared.strings.open_in_explorer)
            
            if tapRange.location != NSNotFound {
                let tapLocation = sender.location(in: self.valueLabel)
                let tapIndex = self.valueLabel.indexOfAttributedTextCharacterAtPoint(point: tapLocation)
                
                if let ranges = self.valueLabel.attributedText?.rangesOf(subString: Localizable.shared.strings.open_in_explorer) {
                    for range in ranges {
                        if tapIndex > range.location && tapIndex < range.location + range.length {
                            self.delegate?.onClickToCell(cell: self)
                            return
                        }
                    }
                }
            }
        }
    }
}

extension BMMultiLinesCell2: Configurable {
    
    func configure(with item:BMMultiLineItem) {
        valueLabel.isUserInteractionEnabled = item.canCopy
        valueLabel.copyText = item.detail
        valueLabel.copiedText = item.copiedText
        
        nameLabel.isHidden = false
        
        nameLabel.font = BoldFont(size: 14)
        nameLabel.textColor = UIColor.main.blueyGrey
        nameLabel.textAlignment = .left
        
        if item.title == Localizable.shared.strings.change_locked {
            nameLabel.adjustFontSize = true

            let size: CGFloat = Device.isLarge ? 15 : 14
            let split = item.title.split(separator: "\n")
            let full = String(split[0]) + "\nspace\n" + String(split[1])

            let spaceRange = (full as NSString).range(of: String("space"))
            let detailRange = (full as NSString).range(of: String(split[1]))

            let attributedString = NSMutableAttributedString(string: full)
            attributedString.addAttribute(NSAttributedString.Key.kern, value: CGFloat(2), range: NSRange(location: 0, length: String(split[0]).count))
            
            attributedString.addAttribute(NSAttributedString.Key.font, value: ItalicFont(size: size), range: detailRange)
            
            attributedString.addAttribute(NSAttributedString.Key.font, value: LightFont(size: 5), range: spaceRange)
            attributedString.addAttribute(NSAttributedString.Key.foregroundColor, value: UIColor.clear, range: spaceRange)
            
            nameLabel.attributedText = attributedString
        }
        else {
            nameLabel.text = item.title.uppercased()
            nameLabel.letterSpacing = 2
            nameLabel.adjustFontSize = true
        }
        
        
        
        valueLabel.text = item.detail
        valueLabel.textColor = item.detailColor
        valueLabel.font = item.detailFont
        valueLabel.adjustFontSize = true
        
        if item.detailAttributedString != nil {
            valueLabel.attributedText = item.detailAttributedString
        }
    }
}
