//
// BMAddressCell.swift
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

class BMAddressCell: BaseCell {

    @IBOutlet weak private var mainView: UIView!
    @IBOutlet weak private var nameLabel: UILabel!
    @IBOutlet weak private var idLabel: UILabel!
    @IBOutlet weak private var expiredLabel: UILabel!

    @IBOutlet weak private var arrowImage: UIImageView!

    @IBOutlet weak private var transactionCommentIcon: UIImageView!
    @IBOutlet weak private var transactionCommentLabel: UILabel!
    @IBOutlet weak private var transactionCommentDate: UILabel!

    @IBOutlet weak private var transactionCommentIconY: NSLayoutConstraint!
    
    @IBOutlet weak private var transactionCommentIconHeight: NSLayoutConstraint!
    @IBOutlet weak private var transactionCommentIconWidth: NSLayoutConstraint!

    override func awakeFromNib() {
        super.awakeFromNib()
        
        let selectedView = UIView()
        selectedView.backgroundColor = UIColor.main.selectedColor
        self.selectedBackgroundView = selectedView
        
        if(Settings.sharedManager().isDarkMode) {
            idLabel.textColor =  UIColor.main.steel
           // expiredLabel.textColor =  UIColor.main.steel
            transactionCommentLabel.textColor =  UIColor.main.steel
            transactionCommentDate.textColor =  UIColor.main.steel
        }
    }
    
    override func setHighlighted(_ highlighted: Bool, animated: Bool) {
        super.setHighlighted(highlighted, animated: animated)
        
        mainView.backgroundColor = highlighted ? UIColor.main.selectedColor : backgroundColor
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
    
    public func setItalic(autoGenerated:Bool, italic:Bool)
    {
        if (italic || autoGenerated)
        {
            nameLabel.font = ItalicFont(size: 17)
            if autoGenerated {
                nameLabel.text = Localizable.shared.strings.autogenerated
            }
        }
        else{
            nameLabel.font = RegularFont(size: 17)
        }
    }
}

extension BMAddressCell: Configurable {
    
    func configure(with options: (row: Int, address:BMAddress, displayTransaction:Bool)) {
        
        mainView.backgroundColor = (options.row % 2 == 0) ? UIColor.main.cellBackgroundColor : UIColor.main.marine
        
        backgroundColor = mainView.backgroundColor
        
        if options.address.label.isEmpty {
            nameLabel.text = Localizable.shared.strings.no_name
        }
        else{
            nameLabel.text = options.address.label
        }
        
        idLabel.text = options.address.walletId

        transactionCommentIcon.image = nil
        transactionCommentLabel.text = nil
        transactionCommentDate.text = nil
        
        transactionCommentIconY.constant = 0
        
        transactionCommentIconHeight.constant = 0
        transactionCommentIconWidth.constant = 0
                
        if options.displayTransaction {
            if let last = AppModel.sharedManager().lastTransaction(fromAddress: options.address.walletId)
            {
                if(!last.comment.isEmpty) {
                    transactionCommentIconY.constant = 10
                    
                    transactionCommentIconHeight.constant = 16
                    transactionCommentIconWidth.constant = 16
                    transactionCommentIcon.image = IconComment()

                    transactionCommentLabel.text =  "”" + last.comment + "”"

                    transactionCommentDate.text = last.shortDate()
                }
            }
        }
        
        expiredLabel.isHidden = true
    }
}
