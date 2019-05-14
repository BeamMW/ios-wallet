//
//  UTXOCell.swift
//  BeamWallet
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

class UTXOCell: UITableViewCell {
    
    @IBOutlet weak private var mainView: UIView!
    @IBOutlet weak private var amountLabel: UILabel!
    @IBOutlet weak private var currencyIcon: UIImageView!
    @IBOutlet weak private var statusLabel: UILabel!

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
    
        mainView.backgroundColor = (options.row % 2 == 0) ? UIColor.main.marineTwo : UIColor.main.marine
        backgroundColor = mainView.backgroundColor
        
        amountLabel.text = String.currency(value: options.utxo.realAmount)
        statusLabel.text = options.utxo.statusString
        
        if options.utxo.statusString == "available" {
            statusLabel.textColor = UIColor.white
        }
        else if options.utxo.statusString == "spent" {
            statusLabel.textColor = UIColor.main.heliotrope
        }
        else{
            statusLabel.textColor = UIColor.white
        }
        
        let selectedView = UIView()
        selectedView.backgroundColor = UIColor.black.withAlphaComponent(0.2)
        selectedBackgroundView = selectedView
    }
}

extension UTXOCell: DynamicContentHeight {
    
    static func height() -> CGFloat {
        return 60
    }
}


