//
// ReceiveAddressListCell.swift
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

class ReceiveAddressListCell: BaseCell {

    @IBOutlet weak private var mainView: UIView!
    @IBOutlet weak private var nameLabel: UILabel!
    @IBOutlet weak private var idLabel: UILabel!
    @IBOutlet weak private var categoryLabel: UILabel!
    
    @IBOutlet weak private var transactionCommentIcon: UIImageView!
    @IBOutlet weak private var transactionCommentLabel: UILabel!
    @IBOutlet weak private var transactionCommentDate: UILabel!

    @IBOutlet weak private var transactionCommentIconY: NSLayoutConstraint!
    @IBOutlet weak private var transactionCommentLabelY: NSLayoutConstraint!
    @IBOutlet weak private var transactionCommentDateY: NSLayoutConstraint!
    
    @IBOutlet weak private var transactionCommentIconHeight: NSLayoutConstraint!
    @IBOutlet weak private var transactionCommentIconWidth: NSLayoutConstraint!

    override func awakeFromNib() {
        super.awakeFromNib()
        
        let selectedView = UIView()
        selectedView.backgroundColor = UIColor.black.withAlphaComponent(0.2)
        self.selectedBackgroundView = selectedView
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
    
}

extension ReceiveAddressListCell: Configurable {
    
    func configure(with options: (row: Int, address:BMAddress)) {
        
        mainView.backgroundColor = (options.row % 2 == 0) ? UIColor.main.marineTwo : UIColor.main.marine
        
        backgroundColor = mainView.backgroundColor
        
        idLabel.text = options.address.walletId
        
        if options.address.label.isEmpty {
            nameLabel.text = " "
        }
        else{
            nameLabel.text = options.address.label
        }
        
        if let category = AppModel.sharedManager().findCategory(byId: options.address.category) {
            categoryLabel.textColor = UIColor.init(hexString: category.color)
            categoryLabel.text = category.name
        }
        else{
            categoryLabel.text = ""
        }
        
        transactionCommentIcon.image = nil
        transactionCommentLabel.text = nil
        transactionCommentDate.text = nil
        
        transactionCommentIconY.constant = 0
        transactionCommentLabelY.constant = 0
        transactionCommentDateY.constant = 0
        
        transactionCommentIconHeight.constant = 0
        transactionCommentIconWidth.constant = 0
    }
}

extension ReceiveAddressListCell: DynamicContentHeight {
    
    static func height() -> CGFloat {
        return 66
    }
}
