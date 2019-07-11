//
//  AddressCategoryCell.swift
//  BeamWallet
//
//  Created by Denis on 5/8/19.
//  Copyright © 2019 Denis. All rights reserved.
//

import UIKit

class AddressCategoryCell: UITableViewCell {
    
    @IBOutlet weak private var categoryLabel: UILabel!
    @IBOutlet weak private var titleLabel: UILabel!

    override func awakeFromNib() {
        super.awakeFromNib()
        
        self.backgroundColor = UIColor.main.marineThree
        
        selectionStyle = .default
        
        let selectedView = UIView()
        selectedView.backgroundColor = UIColor.black.withAlphaComponent(0.2)
        self.selectedBackgroundView = selectedView
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
    
}

extension AddressCategoryCell: Configurable {
    
    func configure(with address: BMAddress) {
        categoryLabel.attributedText = address.categoriesName()
        titleLabel.text = (address.categories.count <= 1 ? Localizable.shared.strings.tag : Localizable.shared.strings.categories)
    }
}

extension AddressCategoryCell: DynamicContentHeight {
    
    static func height() -> CGFloat {
        return 50
    }
}

