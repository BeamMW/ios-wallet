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

class WalletTransactionCell: RippleCell {

    @IBOutlet weak private var mainView: UIView!
    @IBOutlet weak private var statusLabel: UILabel!
    @IBOutlet weak private var typeLabel: UILabel!
    @IBOutlet weak private var dateLabel: UILabel!
    @IBOutlet weak private var assetIcon: AssetIconView!
    @IBOutlet weak private var statusIcon: UIImageView!

    @IBOutlet weak private var detailView: UIView!
    @IBOutlet weak private var commentView: UIStackView!
    @IBOutlet weak private var commentLabel: UILabel!
    @IBOutlet weak private var secondAvailableLabel: UILabel!

    override func awakeFromNib() {
        super.awakeFromNib()
        
        selectionStyle = .none
    }
}

extension WalletTransactionCell: Configurable {
    
    func configure(with options: (row: Int, transaction:BMTransaction, additionalInfo:Bool)) {
        guard let asset = options.transaction.asset else {
            return
        }
        
        let rate = options.transaction.realRate
        
        if rate > 0 {
            let second = ExchangeManager.shared().exchangeValueAsset(withCurrency: Int64(options.transaction.realRate), amount: options.transaction.realAmount, assetID: UInt64(options.transaction.assetId))
            secondAvailableLabel.text = second
        }
        else {
            secondAvailableLabel.text = ""
        }
        

        mainView.backgroundColor = (options.row % 2 == 0) ? UIColor.main.cellBackgroundColor : UIColor.main.marine
                
        assetIcon.setAsset(asset)
        
        statusIcon.image = options.transaction.statusIcon()
        
        typeLabel.text = options.transaction.amountString()
        
        dateLabel.text = options.transaction.formattedDate()
        dateLabel.isHidden = !options.additionalInfo
        statusLabel.text = options.transaction.statusType()
        detailView.isHidden = !options.additionalInfo

        if options.additionalInfo && !options.transaction.comment.isEmpty {
            commentView.isHidden = false
            commentLabel.text = "”" + options.transaction.comment + "”"
        }
        else{
            commentView.isHidden = true
        }
        
        if options.transaction.isFailed() || options.transaction.isCancelled() || options.transaction.isExpired() {
            if options.transaction.isFailed() && !options.transaction.isCancelled() && !options.transaction.isExpired() {
                statusLabel.textColor = UIColor.main.failed
            }
            else {
                statusLabel.textColor = UIColor.main.greyish
            }
        }
        else if (options.transaction.enumType == BMTransactionTypeUnlink) {
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
