//
//  TransactionUTXOCell.swift
//  BeamWallet
//
//  Created by Denis on 3/29/19.
//  Copyright © 2019 Denis. All rights reserved.
//

import UIKit

class TransactionUTXOCell: BaseCell {

    @IBOutlet weak private var amountLabel: UILabel!
    @IBOutlet weak private var currencyIcon: UIImageView!
    @IBOutlet weak private var statusIcon: UIImageView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        selectionStyle = .none
        
        currencyIcon.image = IconSymbolBeam()?.withRenderingMode(.alwaysTemplate)
        currencyIcon.tintColor = UIColor.white
    }    
}

extension TransactionUTXOCell: Configurable {
    
    func configure(with utxo: BMUTXO) {        
        amountLabel.text = String.currency(value: utxo.realAmount)
        
        switch utxo.statusString {
        case LocalizableStrings.spent:
            statusIcon.image = IconSendPink()
        case LocalizableStrings.total:
            statusIcon.image = IconUtxo()
        default:
            statusIcon.image = IconReceiveLightBlue()
        }
    }
}
