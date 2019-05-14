//
// UTXODetailCell.swift
// BeamWallet
//
// Copyright 2018 Beam Development
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//

import UIKit

class UTXODetailCell: UITableViewCell {
    
    @IBOutlet weak private var mainView: UIView!
    @IBOutlet weak private var amountLabel: UILabel!
    @IBOutlet weak private var currencyIcon: UIImageView!
    @IBOutlet weak private var statusLabel: UILabel!
    @IBOutlet weak private var idLabel: BMCopyLabel!

    override func awakeFromNib() {
        super.awakeFromNib()
        
        currencyIcon.image = UIImage.init(named: "iconSymbol")?.withRenderingMode(.alwaysTemplate)
        currencyIcon.tintColor = UIColor.white
        
        selectionStyle = .none
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
}

extension UTXODetailCell: Configurable {
    
    func configure(with options: (row: Int, utxo:BMUTXO)) {
        if options.row % 2 == 0 {
            mainView.backgroundColor = UIColor.main.marineTwo
        }
        else{
            mainView.backgroundColor = UIColor.main.marine
        }
        
        idLabel.text = options.utxo.stringID
        amountLabel.text = String.currency(value: options.utxo.realAmount)
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
    }
}

extension UTXODetailCell: DynamicContentHeight {
    
    static func height() -> CGFloat {
        return 80
    }
}
