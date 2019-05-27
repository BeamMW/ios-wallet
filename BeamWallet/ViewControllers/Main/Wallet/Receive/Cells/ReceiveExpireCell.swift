//
//  ReceiveExpireCell.swift
//  BeamWallet
//
//  Created by Denis on 5/27/19.
//  Copyright © 2019 Denis. All rights reserved.
//

import UIKit

class ReceiveExpireCell: BaseCell {
    
    @IBOutlet weak private var timeLabel: UILabel!

    override func awakeFromNib() {
        super.awakeFromNib()
       
        selectionStyle = .none
    }
}

extension ReceiveExpireCell: Configurable {
    
    func configure(with address: BMAddress) {
        timeLabel.text = address.duration > 0 ? LocalizableStrings.hours_24 : LocalizableStrings.never
    }
}

