//
// AddressCell.swift
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

class AddressCell: UITableViewCell {

    @IBOutlet weak private var mainView: UIView!
    @IBOutlet weak private var arrowImage: UIImageView!
    @IBOutlet weak private var nameLabel: UILabel!
    @IBOutlet weak private var idLabel: UILabel!
    @IBOutlet weak private var expiredLabel: UILabel!
    @IBOutlet weak private var categoryLabel: UILabel!
    @IBOutlet weak private var categoryTopY: NSLayoutConstraint!

    override func awakeFromNib() {
        super.awakeFromNib()
    }
}

extension AddressCell: Configurable {
    
    func configure(with options: (row: Int, address:BMAddress, single:Bool, displayCategory:Bool)) {

        mainView.backgroundColor = (options.row % 2 == 0) ? UIColor.main.marineThree : UIColor.main.marine
        
        arrowImage.isHidden = options.single
        
        idLabel.text = options.address.walletId
        
        if options.address.createTime == 0 {
            expiredLabel.text = String.empty()
        }
        else{
            let expired:String = (options.address.isExpired()) ? options.address.formattedDate() : (options.address.duration == 0 ? Localizable.shared.strings.never_expires.lowercased() : (Localizable.shared.strings.expires_in.lowercased() + " " + options.address.agoDate().lowercased()))
            
            let imageAttachment = NSTextAttachment()
            imageAttachment.image = options.address.duration == 0 ? IconInfinity() : IconExpires()
            imageAttachment.bounds = CGRect(x: 0, y: options.address.duration == 0 ? (-4) : (-3), width: 16, height: 16)
            
            let imageString = NSAttributedString(attachment: imageAttachment)
            
            let attributedString = NSMutableAttributedString()
            attributedString.append(imageString)
            attributedString.append(NSAttributedString(string: "   "))
            attributedString.append(NSAttributedString(string: expired))
            
            expiredLabel.attributedText = attributedString
        }
        
        if options.address.label.isEmpty {
            nameLabel.text = Localizable.shared.strings.no_name
        }
        else{
            nameLabel.text = options.address.label
        }
        
        if options.single {
            self.selectionStyle = .none
        }
        else{
            let selectedView = UIView()
            selectedView.backgroundColor = UIColor.black.withAlphaComponent(0.2)
            self.selectedBackgroundView = selectedView
        }
        
        if options.displayCategory {
            if let category = AppModel.sharedManager().findCategory(byId: options.address.category) {
                categoryLabel.textColor = UIColor.init(hexString: category.color)
                categoryLabel.text = category.name
            }
            else{
                categoryLabel.text = nil
            }
        }
        else{
            categoryLabel.text = nil
        }
        
    }
}

extension AddressCell: DynamicContentHeight {
    
    static func height() -> CGFloat {
        return 90
    }
}
