//
//  GeneralInfoCell.swift
//  BeamWallet
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

struct GeneralInfo {
    var text:String!
    var detail:String!
    var failed:Bool!
    var canCopy:Bool!
    var color = UIColor.white
}

protocol GeneralInfoCellDelegate: AnyObject {
    func onClickToCell(cell:UITableViewCell)
}

class GeneralInfoCell: BaseCell {
    
    weak var delegate: GeneralInfoCellDelegate?

    @IBOutlet weak private var titleLabel: UILabel!
    @IBOutlet weak private var detailLabel: BMCopyLabel!
    @IBOutlet weak private var titleWidth: NSLayoutConstraint!

    override func awakeFromNib() {
        super.awakeFromNib()
        
        selectionStyle = .none
        
        detailLabel.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(titleLabelTapGestureAction(_:))))
        
        if Device.isLarge {
            titleWidth.constant = 150
        }
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
    
    @objc private func titleLabelTapGestureAction(_ sender: UITapGestureRecognizer) {

        if let text = self.detailLabel.attributedText {
            let title = NSString(string: text.string)
            
            let tapRange = title.range(of: Localizables.shared.strings.open_in_explorer)
            
            if tapRange.location != NSNotFound {
                let tapLocation = sender.location(in: self.detailLabel)
                let tapIndex = self.detailLabel.indexOfAttributedTextCharacterAtPoint(point: tapLocation)
                
                if let ranges = self.detailLabel.attributedText?.rangesOf(subString: Localizables.shared.strings.open_in_explorer) {
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

extension GeneralInfoCell: Configurable {
    
    func configure(with info:GeneralInfo) {
        titleLabel.text = info.text
        detailLabel.text = info.detail
        detailLabel.copyText = nil
        detailLabel.isUserInteractionEnabled = info.canCopy
        
        if info.failed {
            titleLabel.textColor = UIColor.main.red
            detailLabel.textColor = UIColor.main.red
        }
        else{
            titleLabel.textColor = UIColor.main.blueyGrey
            detailLabel.textColor = UIColor.white
            detailLabel.textColor = info.color
        }
        
        if info.text == Localizables.shared.strings.addDots(value:Localizables.shared.strings.my_rec_address) ||  info.text == Localizables.shared.strings.addDots(value:Localizables.shared.strings.my_send_address) || info.text == Localizables.shared.strings.addDots(value:Localizables.shared.strings.my_address) || info.text == Localizables.shared.strings.addDots(value:Localizables.shared.strings.contact) {
            
            let address = AppModel.sharedManager().findAddress(byID: info.detail)
            let category = AppModel.sharedManager().findCategory(byAddress: info.detail)

            let categoryName = category?.name ?? String.empty()
            let addressName = address?.label ?? String.empty()

            detailLabel.copyText = info.detail
            
            var strings = [String]()
            
            if !addressName.isEmpty {
                strings.append(addressName)
            }
            
            strings.append(info.detail)

            if !categoryName.isEmpty {
                strings.append(categoryName)
            }
            
            let text = (strings.count == 1 ? info.detail : strings.joined(separator: "\n"))!

            let rangeCategory = (text as NSString).range(of: String(categoryName))
            let rangeName = (text as NSString).range(of: String(addressName))
           
            let attributedString = NSMutableAttributedString(string:text)
           
//            let style1 = NSMutableParagraphStyle()
//            style1.lineSpacing = 5
//            style1.lineBreakMode = .byCharWrapping
//
            let style2 = NSMutableParagraphStyle()
            style2.lineSpacing = 5
            style2.lineBreakMode = .byCharWrapping
            
            let allStyle = NSMutableParagraphStyle()
            allStyle.lineBreakMode = .byCharWrapping

            attributedString.addAttribute(NSAttributedString.Key.paragraphStyle, value: allStyle, range: NSMakeRange(0, text.count))

            if !categoryName.isEmpty {
           //     let rangeCategory2 = (text as NSString).range(of: String("\n" + categoryName))

                attributedString.addAttribute(NSAttributedString.Key.foregroundColor, value: UIColor.init(hexString: category!.color) , range: rangeCategory)
                attributedString.addAttribute(NSAttributedString.Key.font, value: ItalicFont(size: 14) , range: rangeCategory)
             //   attributedString.addAttribute(NSAttributedString.Key.paragraphStyle, value: style1, range: rangeCategory2)
            }
            
            if !addressName.isEmpty {
                attributedString.addAttribute(NSAttributedString.Key.foregroundColor, value: UIColor.white , range: rangeName)
                attributedString.addAttribute(NSAttributedString.Key.font, value: BoldFont(size: 14) , range: rangeName)
                attributedString.addAttribute(NSAttributedString.Key.paragraphStyle, value: style2, range: rangeName)
            }
            
            detailLabel.attributedText = attributedString
        }
        else if info.text == Localizables.shared.strings.addDots(value:Localizables.shared.strings.contact) {
            let split = info.detail.split(separator: "\n")
            if split.count == 2 {
                let contact = split[0]
                
                let range = (info.detail as NSString).range(of: String(contact))
               
                let attributedString = NSMutableAttributedString(string:info.detail)
                attributedString.addAttribute(NSAttributedString.Key.font, value: UIFont(name: "SFProDisplay-Bold", size: 15) ?? UIFont.boldSystemFont(ofSize: 15) , range: range)
                detailLabel.attributedText = attributedString
            }
        }
        else if info.text == Localizables.shared.strings.addDots(value:Localizables.shared.strings.kernel_id)  {
            detailLabel.copyText = info.detail

            if !info.detail.contains("00000000") {
                detailLabel.isUserInteractionEnabled = true
                
                let text = info.detail + "\n" + Localizables.shared.strings.open_in_explorer
                let range = (text as NSString).range(of: String(Localizables.shared.strings.open_in_explorer))
                
                let imageAttachment = NSTextAttachment()
                imageAttachment.image = UIImage(named: "iconExternalLinkGreen")
                let imageString = NSAttributedString(attachment: imageAttachment)
                
                let attributedString = NSMutableAttributedString(string:text)
                attributedString.addAttribute(NSAttributedString.Key.foregroundColor, value: UIColor.main.brightTeal , range: range)
                
                attributedString.append(NSAttributedString(string: " "))
                attributedString.append(imageString)
                
                detailLabel.attributedText = attributedString
            }
        }
        
    }
}

