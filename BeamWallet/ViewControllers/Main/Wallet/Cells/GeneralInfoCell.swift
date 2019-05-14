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
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        selectionStyle = .none
        
        if AppDelegate.isEnableNewFeatures {
            detailLabel.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(titleLabelTapGestureAction(_:))))
        }
     
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
    
    @objc private func titleLabelTapGestureAction(_ sender: UITapGestureRecognizer) {

        if let text = self.detailLabel.attributedText {
            let title = NSString(string: text.string)
            
            let tapRange = title.range(of: "Open in Block Explorer")
            
            if tapRange.location != NSNotFound {
                let tapLocation = sender.location(in: self.detailLabel)
                let tapIndex = self.detailLabel.indexOfAttributedTextCharacterAtPoint(point: tapLocation)
                
                if let ranges = self.detailLabel.attributedText?.rangesOf(subString: "Open in Block Explorer") {
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
        
        if info.text == "Sending address:" ||  info.text == "Receiving address:" {
            if let category = AppModel.sharedManager().findCategory(byAddress: info.detail)
            {
                detailLabel.copyText = info.detail
                
                let text = info.detail + "\n" + category.name
                let range = (text as NSString).range(of: String(category.name))
                
                let attributedString = NSMutableAttributedString(string:text)
                attributedString.addAttribute(NSAttributedString.Key.foregroundColor, value: UIColor.init(hexString: category.color) , range: range)
                attributedString.addAttribute(NSAttributedString.Key.font, value: UIFont(name: "SFProDisplay-Italic", size: 14) ?? UIFont.italicSystemFont(ofSize: 14) , range: range)

                detailLabel.attributedText = attributedString
            }
        }
        else if info.text == "Contact:" {
            let split = info.detail.split(separator: "\n")
            if split.count == 2 {
                let contact = split[0]
                
                let range = (info.detail as NSString).range(of: String(contact))
               
                let attributedString = NSMutableAttributedString(string:info.detail)
                attributedString.addAttribute(NSAttributedString.Key.font, value: UIFont(name: "SFProDisplay-Bold", size: 15) ?? UIFont.boldSystemFont(ofSize: 15) , range: range)
                detailLabel.attributedText = attributedString
            }
        }
        else if info.text == "Kernel ID:" && AppDelegate.isEnableNewFeatures {
            detailLabel.copyText = info.detail

            if !info.detail.contains("00000000") {
                detailLabel.isUserInteractionEnabled = true
                
                let text = info.detail + "\n" + "Open in Block Explorer"
                let range = (text as NSString).range(of: String("Open in Block Explorer"))
                
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

