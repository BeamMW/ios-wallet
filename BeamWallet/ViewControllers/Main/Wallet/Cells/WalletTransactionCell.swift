//
//  WalletTransactionCell.swift
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

class WalletTransactionCell: UITableViewCell {

    @IBOutlet weak private var mainView: UIView!
    @IBOutlet weak private var statusLabel: UILabel!
    @IBOutlet weak private var typeLabel: UILabel!
    @IBOutlet weak private var dateLabel: UILabel!
    @IBOutlet weak private var amountLabel: UILabel!
    @IBOutlet weak private var currencyIcon: UIImageView!

    override func awakeFromNib() {
        super.awakeFromNib()
        
        currencyIcon.image = UIImage.init(named: "iconSymbol")?.withRenderingMode(.alwaysTemplate)
    }
}

extension WalletTransactionCell: Configurable {
    
    func configure(with options: (row: Int, transaction:BMTransaction)) {
        if options.row % 2 == 0 {
            mainView.backgroundColor = UIColor.main.marineTwo
        }
        else{
            mainView.backgroundColor = UIColor.main.marine
        }
        
        if options.transaction.isIncome {
            amountLabel.text = "+" + String.currency(value: options.transaction.realAmount)
            amountLabel.textColor = UIColor.main.brightSkyBlue
            statusLabel.textColor = UIColor.main.brightSkyBlue
            currencyIcon.tintColor = UIColor.main.brightSkyBlue

            typeLabel.text = "Receive BEAM"
        }
        else{
            amountLabel.text = "-" + String.currency(value: options.transaction.realAmount)
            amountLabel.textColor = UIColor.main.heliotrope
            statusLabel.textColor = UIColor.main.heliotrope
            currencyIcon.tintColor = UIColor.main.heliotrope

            typeLabel.text = "Send BEAM"
        }
        
        dateLabel.text = options.transaction.formattedDate()
        statusLabel.text = options.transaction.status
        
        let selectedView = UIView()
        selectedView.backgroundColor = mainView.backgroundColor?.withAlphaComponent(0.5)
        self.selectedBackgroundView = selectedView
    }
}
