//
//  DAOAppCell.swift
//  BeamWallet
//
//  Created by Denis on 08.09.2021.
//  Copyright © 2021 Denis. All rights reserved.
//

import UIKit
import SDWebImage

class DAOAppCell: RippleCell {

    @IBOutlet weak private var mainView: UIView!
    @IBOutlet weak private var nameLabel: UILabel!
    @IBOutlet weak private var detailLabel: UILabel!
    @IBOutlet weak private var iconView: UIImageView!

    override func awakeFromNib() {
        super.awakeFromNib()
        
        selectionStyle = .none
    }
}

extension DAOAppCell: Configurable {
    
    func configure(with options: (row: Int, app:BMApp)) {
       
        mainView.backgroundColor = (options.row % 2 == 0) ? UIColor.main.cellBackgroundColor : UIColor.main.marine
                
        nameLabel.text = options.app.name
        detailLabel.text = options.app.desc
        iconView.sd_setImage(with: URL(string: options.app.icon), completed: nil)
    }
}

