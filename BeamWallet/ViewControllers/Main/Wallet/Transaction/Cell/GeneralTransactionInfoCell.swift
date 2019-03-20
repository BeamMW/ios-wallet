//
//  GeneralTransactionInfoCell.swift
//  BeamWallet
//
//  Created by Denis on 3/19/19.
//  Copyright © 2019 Denis. All rights reserved.
//

import UIKit

class GeneralTransactionInfoCell: BaseCell {
    
    @IBOutlet weak private var titleLabel: UILabel!
    @IBOutlet weak private var detailLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        selectionStyle = .none
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
}

extension GeneralTransactionInfoCell: Configurable {
    
    func configure(with info:TransactionViewController.TransactionGeneralInfo) {
        titleLabel.text = info.text
        detailLabel.text = info.detail
        
        if info.failed {
            titleLabel.textColor = UIColor.main.red
            detailLabel.textColor = UIColor.main.red
        }
        else{
            titleLabel.textColor = UIColor.main.blueyGrey
            detailLabel.textColor = UIColor.white
        }
    }
}

