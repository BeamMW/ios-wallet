//
//  ReceiveCategoryCell.swift
//  BeamWallet
//
//  Created by Denis on 5/27/19.
//  Copyright © 2019 Denis. All rights reserved.
//

import UIKit

class ReceiveCategoryCell: BaseCell {

    @IBOutlet weak private var categoryLabel: UILabel!

    override func awakeFromNib() {
        super.awakeFromNib()
        
        selectionStyle = .none      
    }
}

extension ReceiveCategoryCell: Configurable {
    
    func configure(with address: BMAddress) {
        if address.category == LocalizableStrings.zero {
            categoryLabel.textColor = UIColor.main.steelGrey
            categoryLabel.text = "None"
        }
        else{
            if let category = AppModel.sharedManager().findCategory(byId: address.category) {
                categoryLabel.text = category.name
                categoryLabel.textColor = UIColor.init(hexString: category.color)
            }
            else{
                categoryLabel.text = ""
            }
        }
    }
}
