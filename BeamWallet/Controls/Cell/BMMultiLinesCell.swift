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

class BMMultiLinesCell: BaseCell {
    
    weak var delegate: GeneralInfoCellDelegate?

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

extension BMMultiLinesCell: Configurable {
    
    func configure(with item:BMMultiLineItem) {
        valueLabel.isUserInteractionEnabled = item.canCopy
        valueLabel.copyText = item.detail
        valueLabel.copiedText = item.copiedText
        
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
        
        if item.title == Localizable.shared.strings.send_to || item.title == Localizable.shared.strings.outgoing_address.uppercased()  {
            
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
        else if item.title == Localizable.shared.strings.send_to {
            
            let text = (item.detail)!
            
            let length = text.lengthOfBytes(using: .utf8)
            
            let att = NSMutableAttributedString(string: text, attributes: [NSAttributedString.Key.font : RegularFont(size: 16), NSAttributedString.Key.foregroundColor : UIColor.white])
            att.addAttribute(NSAttributedString.Key.foregroundColor, value: UIColor.main.heliotrope, range: NSRange(location: 0, length: 6))
            att.addAttribute(NSAttributedString.Key.foregroundColor, value: UIColor.main.heliotrope, range: NSRange(location: length-6, length: 6))
            
            valueLabel.attributedText = att
        }
        else if item.title == Localizable.shared.strings.kernel_id.uppercased() {
            
            if !(item.detail?.contains("00000000"))! {
                valueLabel.isUserInteractionEnabled = true
                
                let text = item.detail! + "\n" + Localizable.shared.strings.open_in_explorer
                let range = (text as NSString).range(of: String(Localizable.shared.strings.open_in_explorer))
                
                let imageAttachment = NSTextAttachment()
                imageAttachment.image = ExternalLinkGreen()
                let imageString = NSAttributedString(attachment: imageAttachment)
                
                let attributedString = NSMutableAttributedString(string:text)
                attributedString.addAttribute(NSAttributedString.Key.foregroundColor, value: UIColor.main.brightTeal , range: range)
                attributedString.addAttribute(NSAttributedString.Key.font, value: RegularFont(size: 14) , range: range)

                attributedString.append(NSAttributedString(string: " "))
                attributedString.append(imageString)
                
                valueLabel.attributedText = attributedString
            }
        }
        else if item.title == Localizable.shared.strings.my_send_address.uppercased() ||
            item.title == Localizable.shared.strings.my_rec_address.uppercased() || item.title == Localizable.shared.strings.contact.uppercased() || item.title == Localizable.shared.strings.my_address.uppercased() || item.title == Localizable.shared.strings.sender.uppercased() || item.title == Localizable.shared.strings.receiver.uppercased() {

            var attributedString = NSMutableAttributedString(string:item.detail!)

            if let address = AppModel.sharedManager().findAddress(byID: item.detail!) {
                
                var fontSizeOffset:CGFloat = 0
                
                if Device.screenType == .iPhone_XSMax || Device.screenType == .iPhones_Plus {
                    fontSizeOffset = 1.0
                }
                else if Device.screenType == .iPhones_5{
                    fontSizeOffset = -1.5
                }
                
                if !address.label.isEmpty {
                    attributedString = NSMutableAttributedString(string:"")
                    
                    let style = NSMutableParagraphStyle()
                    style.lineSpacing = 8
                    style.lineBreakMode = .byCharWrapping
                    
                    let style2 = NSMutableParagraphStyle()
                    style2.lineSpacing = 0
                    style2.lineBreakMode = .byCharWrapping

                    let imageAttachment = NSTextAttachment()
                    imageAttachment.image = IconContact()
                    imageAttachment.bounds = CGRect(x: 0, y: -2, width: 16, height: 16)

                    let imageString = NSAttributedString(attachment: imageAttachment)
                    
                    let nameString = NSMutableAttributedString(string:address.label)
                    nameString.addAttribute(NSAttributedString.Key.font, value: BoldFont(size: 16 + fontSizeOffset), range: NSMakeRange(0, nameString.string.count))
                    
                    let detailString = NSMutableAttributedString(string:item.detail!)
                    detailString.addAttribute(NSAttributedString.Key.paragraphStyle, value: style2, range: NSMakeRange(0, detailString.string.count))

                    attributedString.append(imageString)
                    attributedString.append(NSAttributedString(string: "  "))
                    attributedString.append(nameString)
                    attributedString.append(NSAttributedString(string: "\n"))
                    attributedString.append(detailString)
                   
                    attributedString.addAttribute(NSAttributedString.Key.paragraphStyle, value: style, range: NSMakeRange(0, nameString.string.count))
                }
                
                if address.categories.count > 0 {
                    let style = NSMutableParagraphStyle()
                    style.lineSpacing = 3
                    
                    let categoriesString = address.categoriesName()
                    categoriesString.addAttributes([NSAttributedString.Key.font : ItalicFont(size: 14 + fontSizeOffset)], range: NSMakeRange(0, categoriesString.string.count))

                    let whiteString = NSMutableAttributedString(string: "\nwhite\n")
                    whiteString.addAttribute(NSAttributedString.Key.paragraphStyle, value: style, range: NSMakeRange(0, whiteString.string.count))
                    whiteString.addAttribute(NSAttributedString.Key.foregroundColor, value: UIColor.clear, range: NSMakeRange(0, whiteString.string.count))
                    whiteString.addAttribute(NSAttributedString.Key.font, value: RegularFont(size: 1), range: NSMakeRange(0, whiteString.string.count))

                    attributedString.append(whiteString)
                    attributedString.append(categoriesString)
                }
            }
            
            valueLabel.attributedText = attributedString
        }
        else if item.detailAttributedString != nil {
            valueLabel.attributedText = item.detailAttributedString
        }
    }
}
