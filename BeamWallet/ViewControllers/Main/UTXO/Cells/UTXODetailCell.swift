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

    override func awakeFromNib() {
        super.awakeFromNib()
        
        currencyIcon.image = UIImage.init(named: "iconSymbol")?.withRenderingMode(.alwaysTemplate)
        currencyIcon.tintColor = UIColor.white
        mainView.backgroundColor = UIColor.white.withAlphaComponent(0.05)

        selectionStyle = .none
    }
}

extension UTXODetailCell: Configurable {
    
    func configure(with utxo:BMUTXO) {
        amountLabel.text = String.currency(value: utxo.realAmount)
        statusLabel.text = utxo.statusString.replacingOccurrences(of: "\n", with: " ")
        
        if utxo.status == 1 || utxo.status == 2 {
            statusLabel.textColor = UIColor.white
        }
        else if utxo.status == 6 || utxo.status == 3 {
            statusLabel.textColor = UIColor.main.heliotrope
        }
        else if utxo.status == 4 {
            statusLabel.textColor = UIColor.main.brightSkyBlue
        }
        else{
            statusLabel.textColor = UIColor.main.blueyGrey
        }
    }
}
