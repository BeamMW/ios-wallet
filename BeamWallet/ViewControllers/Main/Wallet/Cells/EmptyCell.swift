//
//  EmptyCell.swift
//  BeamWallet
//
//  Created by Denis on 5/3/19.
//  Copyright © 2019 Denis. All rights reserved.
//

import UIKit

class EmptyCell: BaseCell {

    @IBOutlet weak private var titleLabel: UILabel!
    @IBOutlet weak private var mainView: UIView!

    override func awakeFromNib() {
        super.awakeFromNib()
        
        mainView.backgroundColor = UIColor.main.marineTwo

        selectionStyle = .none
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
    
}

extension EmptyCell: Configurable {
    
    func configure(with text:String) {
        titleLabel.text = text
    }
}
