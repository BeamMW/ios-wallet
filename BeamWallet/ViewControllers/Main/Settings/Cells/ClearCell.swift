//
//  ClearCell.swift
//  BeamWallet
//
//  Created by Denis on 9/23/19.
//  Copyright © 2019 Denis. All rights reserved.
//

import UIKit

class ClearCell: UITableViewCell {
    public static let height:CGFloat = 50
    
    @IBOutlet private weak var nameLabel: UILabel!
    @IBOutlet private weak var checkButton: UIButton!
    @IBOutlet private weak var mainView: UIView!

    override func awakeFromNib() {
        super.awakeFromNib()
        
        selectionStyle = .none
        
        backgroundColor = UIColor.main.marineThree
        mainView.backgroundColor = UIColor.main.marineThree
    }
}


extension ClearCell: Configurable {
    
    func configure(with item:ClearDataViewController.ClearItem) {
        nameLabel.text = item.title
        checkButton.isSelected = item.isSelected
    }
}
