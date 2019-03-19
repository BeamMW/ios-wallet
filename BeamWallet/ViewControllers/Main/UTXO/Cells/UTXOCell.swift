//
//  UTXOCell.swift
//  BeamWallet
//
//  Created by Denis on 3/18/19.
//  Copyright © 2019 Denis. All rights reserved.
//

import UIKit

class UTXOCell: UITableViewCell {
    
    @IBOutlet weak private var mainView: UIView!
    @IBOutlet weak private var amountLabel: UILabel!
    @IBOutlet weak private var currencyIcon: UIImageView!
    @IBOutlet weak private var statusLabel: UILabel!
    @IBOutlet weak private var idLabel: UILabel!

    override func awakeFromNib() {
        super.awakeFromNib()
        
        currencyIcon.image = UIImage.init(named: "iconSymbol")?.withRenderingMode(.alwaysTemplate)
        currencyIcon.tintColor = UIColor.white
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
}

extension UTXOCell: Configurable {
    
    func configure(with options: (row: Int, utxo:BMUTXO)) {
        if options.row % 2 == 0 {
            mainView.backgroundColor = UIColor.main.marineTwo
        }
        else{
            mainView.backgroundColor = UIColor.main.marine
        }
        
        amountLabel.text = String.currency(value: options.utxo.realAmount)
        idLabel.text = options.utxo.stringID
        statusLabel.text = options.utxo.statusString
        
        if options.utxo.statusString == "Available" {
            statusLabel.textColor = UIColor.main.brightTeal
        }
        else if options.utxo.statusString == "Spent" {
            statusLabel.textColor = UIColor.main.heliotrope
        }
        else{
            statusLabel.textColor = UIColor.white
        }
        
        let selectedView = UIView()
        selectedView.backgroundColor = mainView.backgroundColor?.withAlphaComponent(0.9)
        self.selectedBackgroundView = selectedView
    }
}

