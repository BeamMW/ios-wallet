//
// TransactionDetailCell.swift
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

class TransactionDetailCell: UITableViewCell {
    
    @IBOutlet weak private var mainView: UIView!
    @IBOutlet weak private var amountLabel: UILabel!
    @IBOutlet weak private var currencyIcon: UIImageView!
    @IBOutlet weak private var statusLabel: UILabel!
    @IBOutlet weak private var circleView: UIView!
    @IBOutlet weak private var arrowIcon: UIImageView!
    @IBOutlet weak private var securityIcon: UIImageView!

    //
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        currencyIcon.image = UIImage.init(named: "iconSymbol")?.withRenderingMode(.alwaysTemplate)
        currencyIcon.tintColor = UIColor.white
        currencyIcon.tintAdjustmentMode = .normal

        mainView.backgroundColor = UIColor.white.withAlphaComponent(0.05)
        circleView.backgroundColor = UIColor.main.marine

        selectionStyle = .none
    }
}

extension TransactionDetailCell: Configurable {
    
    func configure(with transaction:BMTransaction) {

        arrowIcon.image = transaction.statusIcon()

        amountLabel.isHidden = Settings.sharedManager().isHideAmounts
        currencyIcon.isHidden = Settings.sharedManager().isHideAmounts
        securityIcon.isHidden = !Settings.sharedManager().isHideAmounts

        amountLabel.text = String.currency(value: transaction.realAmount)
        statusLabel.text = transaction.status.capitalizingFirstLetter()

        switch transaction.isIncome {
        case true:
            amountLabel.textColor = UIColor.main.brightSkyBlue
            currencyIcon.tintColor = UIColor.main.brightSkyBlue
        case false:
            amountLabel.textColor = UIColor.main.heliotrope
            currencyIcon.tintColor = UIColor.main.heliotrope
        }
        
        if transaction.isFailed() || transaction.isCancelled() || transaction.isExpired() {
            statusLabel.textColor = UIColor.main.greyish
        }
        else if transaction.isSelf {
            statusLabel.textColor = UIColor.white
        }
        else if transaction.isIncome {
            statusLabel.textColor = UIColor.main.brightSkyBlue
        }
        else if !transaction.isIncome {
            statusLabel.textColor = UIColor.main.heliotrope
        }
        
        circleView.layer.borderColor = statusLabel.textColor.cgColor
    }
}
