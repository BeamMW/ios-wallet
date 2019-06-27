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
    @IBOutlet weak private var arrowImage: UIImageView!
    @IBOutlet weak private var amountOffset: NSLayoutConstraint!
    @IBOutlet weak private var balanceView: UIView!
    @IBOutlet weak private var searchLabel: UILabel!
    @IBOutlet weak private var searchLabelWidth: NSLayoutConstraint!

    override func awakeFromNib() {
        super.awakeFromNib()
        
        currencyIcon.image = UIImage.init(named: "iconSymbol")?.withRenderingMode(.alwaysTemplate)
        currencyIcon.tintAdjustmentMode = .normal
        
        searchLabelWidth.constant = UIScreen.main.bounds.size.width - 200
    }
}

extension WalletTransactionCell: Configurable {
    
    func configure(with options: (row: Int, transaction:BMTransaction, single:Bool, searchString:String?)) {
     
        mainView.backgroundColor = (options.row % 2 == 0) ? UIColor.main.marineTwo : UIColor.main.marine
        
        backgroundColor = mainView.backgroundColor
        
        arrowImage.isHidden = options.single
        
        switch options.transaction.isIncome {
        case true:
            amountLabel.text = "+" + String.currency(value: options.transaction.realAmount)
            amountLabel.textColor = UIColor.main.brightSkyBlue
            statusLabel.textColor = UIColor.main.brightSkyBlue
            currencyIcon.tintColor = UIColor.main.brightSkyBlue
            typeLabel.text = Localizable.shared.strings.receive_beam
        case false:
            amountLabel.text = "-" + String.currency(value: options.transaction.realAmount)
            amountLabel.textColor = UIColor.main.heliotrope
            statusLabel.textColor = UIColor.main.heliotrope
            currencyIcon.tintColor = UIColor.main.heliotrope
            typeLabel.text = Localizable.shared.strings.send_beam
        }
        
        
        
        if options.transaction.isSelf || options.transaction.isFailed() || options.transaction.isCancelled() {
            statusLabel.textColor = UIColor.white
        }
        
        dateLabel.text = options.transaction.formattedDate()
        statusLabel.text = options.transaction.status
        
        if options.single {
            amountOffset.constant = 0
            self.selectionStyle = .none
        }
        else{
            let selectedView = UIView()
            selectedView.backgroundColor = UIColor.black.withAlphaComponent(0.2)
            self.selectedBackgroundView = selectedView
        }
        
        balanceView.isHidden = Settings.sharedManager().isHideAmounts
        searchLabel.isHidden = true
        
        if let string = options.searchString, string.isEmpty == false {
            searchLabel.isHidden = false
            
            var mainText = String.empty()
            
            if options.transaction.receiverAddress.lowercased().starts(with: string.lowercased()) {
                mainText = options.transaction.receiverAddress
            }
            else if options.transaction.senderAddress.lowercased().starts(with: string.lowercased()) {
                mainText = options.transaction.senderAddress
            }
            else if options.transaction.id.lowercased().starts(with: string.lowercased()) {
                mainText = options.transaction.id
            }
            else if options.transaction.receiverContactName.lowercased().starts(with: string.lowercased()) {
                mainText = options.transaction.receiverContactName
            }
            else if options.transaction.senderContactName.lowercased().starts(with: string.lowercased()) {
                mainText = options.transaction.senderContactName
            }
            
            let range = (mainText as NSString).range(of: String(string))
            
            let attributedString = NSMutableAttributedString(string:mainText)
            attributedString.addAttribute(NSAttributedString.Key.foregroundColor, value: UIColor.white , range: range)
            searchLabel.attributedText = attributedString
        }
        
        if AppDelegate.newFeaturesEnabled {
            if options.transaction.isFailed() || options.transaction.isCancelled() || options.transaction.isExpired() {
                statusLabel.textColor = UIColor.main.greyish
            }
            else if options.transaction.isSelf {
                statusLabel.textColor = UIColor.white
            }
            else if options.transaction.isIncome
            {
                statusLabel.textColor = UIColor.main.brightSkyBlue
            }
            else if !options.transaction.isIncome
            {
                statusLabel.textColor = UIColor.main.heliotrope
            }
        }
    }
}

extension WalletTransactionCell: DynamicContentHeight {
    
    static func height() -> CGFloat {
        return 86
    }
    
    static func searchHeight() -> CGFloat {
        return 96
    }
}
