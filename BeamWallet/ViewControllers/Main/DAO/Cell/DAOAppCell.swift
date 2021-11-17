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
    @IBOutlet weak private var iconMainView: UIView!

    override func awakeFromNib() {
        super.awakeFromNib()
        
        selectionStyle = .none
    }
}

extension DAOAppCell: Configurable {
    
    func configure(with options: (row: Int, app:BMApp)) {
       
        iconMainView.backgroundColor = UIColor.main.marineThree
        mainView.backgroundColor = UIColor.white.withAlphaComponent(0.1)
                            
        nameLabel.text = options.app.name
        iconView.sd_setImage(with: URL(string: options.app.icon), completed: nil)
        
        if options.app.isSupported {
            detailLabel.text = options.app.desc
            detailLabel.alpha = 0.7
            detailLabel.textColor = UIColor.white
            detailLabel.font = RegularFont(size: 14)
            self.isUserInteractionEnabled = true
        }
        else {
            detailLabel.text = String.init(format:Localizable.shared.strings.app_not_supported, options.app.api_version ?? "")
            detailLabel.textColor = UIColor.main.red
            detailLabel.alpha = 1
            detailLabel.font = ItalicFont(size: 14)
            self.isUserInteractionEnabled = false
        }
    }
}

