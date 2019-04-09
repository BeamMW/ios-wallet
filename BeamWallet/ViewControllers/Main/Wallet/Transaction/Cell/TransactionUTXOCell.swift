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
        
        currencyIcon.image = UIImage.init(named: "iconSymbol")?.withRenderingMode(.alwaysTemplate)
        currencyIcon.tintColor = UIColor.white
    }    
}

extension TransactionUTXOCell: Configurable {
    
    func configure(with utxo: BMUTXO) {        
        amountLabel.text = String.currency(value: utxo.realAmount)
        
        if utxo.statusString == "spent"
        {
            statusIcon.image = UIImage.init(named: "iconSendPink")
        }
        else if utxo.statusString == "total"
        {
            statusIcon.image = UIImage.init(named: "iconUtxo")
        }
        else{
            statusIcon.image = UIImage.init(named: "iconReceiveLightBlue")
        }
    }
}
