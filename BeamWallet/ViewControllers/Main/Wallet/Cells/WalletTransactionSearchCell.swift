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

class WalletTransactionSearchCell: UITableViewCell {

    @IBOutlet weak private var mainView: UIView!
    @IBOutlet weak private var statusLabel: UILabel!
    @IBOutlet weak private var typeLabel: UILabel!
    @IBOutlet weak private var dateLabel: UILabel!
    @IBOutlet weak private var amountLabel: UILabel!
    @IBOutlet weak private var balanceView: UIView!
    @IBOutlet weak private var statusIcon: UIImageView!
    @IBOutlet weak private var secondAvailableLabel: UILabel!

    @IBOutlet weak private var searchLabel: UILabel!

    override func awakeFromNib() {
        super.awakeFromNib()
        
        secondAvailableLabel.textColor = Settings.sharedManager().isDarkMode ? UIColor.main.steel : UIColor.main.blueyGrey
        secondAvailableLabel.font = RegularFont(size: 14)
        
        let selectedView = UIView()
        selectedView.backgroundColor = UIColor.main.selectedColor
        self.selectedBackgroundView = selectedView
    }
    
    public func setSearch(searchString:String, transaction:BMTransaction) {
        if searchString.isEmpty {
            searchLabel.text = nil
            searchLabel.isHidden = true
        }
        else{
            searchLabel.isHidden = false
            searchLabel.attributedText = transaction.search(searchString)
        }
    }
}

extension WalletTransactionSearchCell: Configurable {
    
    func configure(with options: (row: Int, transaction:BMTransaction, additionalInfo:Bool)) {
     
        mainView.backgroundColor = (options.row % 2 == 0) ? UIColor.main.cellBackgroundColor : UIColor.main.marine
        secondAvailableLabel.text = AppModel.sharedManager().exchangeValue(options.transaction.realAmount)

        statusIcon.image = options.transaction.statusIcon()
        typeLabel.text = options.transaction.statusName()
        statusLabel.text = options.transaction.statusType()

        switch options.transaction.isIncome {
        case true:
            amountLabel.text = "+ " + String.currency(value: options.transaction.realAmount)
            amountLabel.textColor = UIColor.main.brightSkyBlue
        case false:
            amountLabel.text = "- " + String.currency(value: options.transaction.realAmount)
            amountLabel.textColor = UIColor.main.heliotrope
        }
        
        
        dateLabel.text = options.transaction.formattedDate()
        dateLabel.isHidden = !options.additionalInfo
        
        balanceView.isHidden = Settings.sharedManager().isHideAmounts
        
        if options.transaction.isFailed() || options.transaction.isCancelled() || options.transaction.isExpired() {
            statusLabel.textColor = UIColor.main.greyish
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
