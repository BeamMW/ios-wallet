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

class WalletTransactionSearchCell: RippleCell {

    @IBOutlet weak private var mainView: UIView!
    @IBOutlet weak private var statusLabel: UILabel!
    @IBOutlet weak private var typeLabel: UILabel!
    @IBOutlet weak private var dateLabel: UILabel!
    @IBOutlet weak private var statusIcon: UIImageView!
    @IBOutlet weak private var secondAvailableLabel: UILabel!
    @IBOutlet weak private var searchLabel: UILabel!

    @IBOutlet weak private var commentView: UIStackView!
    @IBOutlet weak private var commentLabel: UILabel!
    
    @IBOutlet weak private var assetIconsWidth: NSLayoutConstraint!
    @IBOutlet weak private var assetIcon1: AssetIconView!
    @IBOutlet weak private var assetIcon2: AssetIconView!
    @IBOutlet weak private var assetIcon3: AssetIconView!

    override func awakeFromNib() {
        super.awakeFromNib()
        
        secondAvailableLabel.textColor = Settings.sharedManager().isDarkMode ? UIColor.main.steel : UIColor.main.blueyGrey
        secondAvailableLabel.font = RegularFont(size: 14)
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
                
        statusIcon.image = options.transaction.statusIcon()
        
        assetIcon2.isHidden = true
        assetIcon3.isHidden = true

        if options.transaction.isMultiAssets() {
            let assets = options.transaction.multiAssets as! [BMAsset]
            if assets.count >= 3 {
                assetIconsWidth.constant = 58
            }
            else {
                assetIconsWidth.constant = 42
            }
            var index = 1
            assets.forEach { asset in
                if index == 1 {
                    assetIcon1.setAsset(asset)
                }
                else if index == 2 {
                    assetIcon2.isHidden = false
                    assetIcon2.setAsset(asset)
                }
                else if index == 3 {
                    assetIcon3.isHidden = false
                    assetIcon3.setAsset(asset)
                }
                index += 1
            }
            typeLabel.attributedText = options.transaction.attributedAmountString()
        }
        else {
            assetIconsWidth.constant = 26
            assetIcon1.setAsset(asset)
            typeLabel.text = options.transaction.amountString()
        }
        
        dateLabel.text = options.transaction.formattedDate()
        dateLabel.isHidden = !options.additionalInfo
        statusLabel.text = options.transaction.statusType()
        
        if !options.transaction.comment.isEmpty {
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
