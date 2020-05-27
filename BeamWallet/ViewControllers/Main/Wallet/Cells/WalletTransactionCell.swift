//
// WalletTransactionCell.swift
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

class WalletTransactionCell: UITableViewCell {

    @IBOutlet weak private var mainView: UIView!
    @IBOutlet weak private var statusLabel: UILabel!
    @IBOutlet weak private var typeLabel: UILabel!
    @IBOutlet weak private var dateLabel: UILabel!
    @IBOutlet weak private var amountLabel: UILabel!
    @IBOutlet weak private var currencyIcon: UIImageView!
    @IBOutlet weak private var balanceView: UIView!
    @IBOutlet weak private var statusIcon: UIImageView!

    @IBOutlet weak private var commentView: UIStackView!
    @IBOutlet weak private var commentLabel: UILabel!

    override func awakeFromNib() {
        super.awakeFromNib()
        
        currencyIcon.image = IconSymbolBeam()?.withRenderingMode(.alwaysTemplate)
        currencyIcon.tintAdjustmentMode = .normal
        
        let selectedView = UIView()
        selectedView.backgroundColor = UIColor.main.selectedColor
        self.selectedBackgroundView = selectedView
    }
}

extension WalletTransactionCell: Configurable {
    
    func configure(with options: (row: Int, transaction:BMTransaction, additionalInfo:Bool)) {
     
        mainView.backgroundColor = (options.row % 2 == 0) ? UIColor.main.cellBackgroundColor : UIColor.main.marine
                
        statusIcon.image = options.transaction.statusIcon()
        
        switch options.transaction.isIncome {
        case true:
            amountLabel.text = "+ " + String.currency(value: options.transaction.realAmount)
            amountLabel.textColor = UIColor.main.brightSkyBlue
            currencyIcon.tintColor = UIColor.main.brightSkyBlue
            typeLabel.text = Localizable.shared.strings.receive
        case false:
            if (options.transaction.enumType == BMTransactionTypePushTransaction ||
                options.transaction.enumType == BMTransactionTypePullTransaction) {
                amountLabel.text = String.currency(value: options.transaction.realAmount)
                amountLabel.textColor = UIColor.main.brightTeal
                currencyIcon.tintColor = UIColor.main.brightTeal
                typeLabel.text = Localizable.shared.strings.unlink
            }
            else {
                amountLabel.text = "- " + String.currency(value: options.transaction.realAmount)
                amountLabel.textColor = UIColor.main.heliotrope
                currencyIcon.tintColor = UIColor.main.heliotrope
                typeLabel.text = Localizable.shared.strings.send
            }
        }
        
        
        dateLabel.text = options.transaction.formattedDate()
        dateLabel.isHidden = !options.additionalInfo
        statusLabel.text = options.transaction.status
        
        balanceView.isHidden = Settings.sharedManager().isHideAmounts
        
        if options.additionalInfo && !options.transaction.comment.isEmpty {
            commentView.isHidden = false
            commentLabel.text = "”" + options.transaction.comment + "”"
        }
        else{
            commentView.isHidden = true
        }
        
        if options.transaction.isFailed() || options.transaction.isCancelled() || options.transaction.isExpired() {
            statusLabel.textColor = UIColor.main.greyish
        }
        else if (options.transaction.enumType == BMTransactionTypePushTransaction ||
            options.transaction.enumType == BMTransactionTypePullTransaction) {
            statusLabel.textColor = UIColor.main.brightTeal
        }
        else if options.transaction.isSelf {
            statusLabel.textColor = UIColor.white
        }
        else if options.transaction.isIncome {
            statusLabel.textColor = UIColor.main.brightSkyBlue
        }
        else if !options.transaction.isIncome {
            statusLabel.textColor = UIColor.main.heliotrope
        }
    }
}
