//
//  GeneralTransactionInfoCell.swift
//  BeamWallet
//
//  Created by Denis on 3/15/19.
//  Copyright © 2019 Denis. All rights reserved.
//

import UIKit

class GeneralTransactionInfoCell: UITableViewCell {

    @IBOutlet weak private var mainView: UIView!
    @IBOutlet weak private var statusLabel: UILabel!
    @IBOutlet weak private var typeLabel: UILabel!
    @IBOutlet weak private var dateLabel: UILabel!
    @IBOutlet weak private var amountLabel: UILabel!
    @IBOutlet weak private var currencyIcon: UIImageView!
    @IBOutlet weak private var mainViewWidth: NSLayoutConstraint!
    @IBOutlet weak private var arrowImage: UIImageView!
    @IBOutlet weak private var amountOffset: NSLayoutConstraint!
    
    @IBOutlet weak private var mainWidth: NSLayoutConstraint!
    @IBOutlet weak private var senderAddressLabel: UILabel!
    @IBOutlet weak private var receiverAddressLabel: UILabel!
    @IBOutlet weak private var feeLabel: UILabel!
    @IBOutlet weak private var kernelIdLabel: UILabel!
    @IBOutlet weak private var failedView: UIView!
    @IBOutlet weak private var failedReasonLabel: UILabel!
    @IBOutlet weak private var commentView: UIView!
    @IBOutlet weak private var commentLabel: UILabel!
    @IBOutlet weak private var commentTitleLabel: UILabel!
    @IBOutlet weak private var failedYOffset: NSLayoutConstraint!

    override func awakeFromNib() {
        super.awakeFromNib()
        
        mainView.backgroundColor = UIColor.main.marineTwo

        currencyIcon.image = UIImage.init(named: "iconSymbol")?.withRenderingMode(.alwaysTemplate)

        mainWidth.constant = UIScreen.main.bounds.width
        mainViewWidth.constant = UIScreen.main.bounds.width

        arrowImage.isHidden = true
        amountOffset.constant = 0

        
        self.selectionStyle = .none
    }
}

extension GeneralTransactionInfoCell: Configurable {
    
    func configure(with transaction: BMTransaction) {

        if transaction.isIncome {
            amountLabel.text = "+" + String.currency(value: transaction.realAmount)
            amountLabel.textColor = UIColor.main.brightSkyBlue
            statusLabel.textColor = UIColor.main.brightSkyBlue
            currencyIcon.tintColor = UIColor.main.brightSkyBlue
            
            typeLabel.text = "Receive BEAM"
        }
        else{
            amountLabel.text = "-" + String.currency(value: transaction.realAmount)
            amountLabel.textColor = UIColor.main.heliotrope
            statusLabel.textColor = UIColor.main.heliotrope
            currencyIcon.tintColor = UIColor.main.heliotrope
            
            typeLabel.text = "Send BEAM"
        }
        
        if transaction.isSelf {
            statusLabel.textColor = UIColor.white
        }
        else if transaction.isFailed() {
            statusLabel.textColor = UIColor.main.red
        }
        
        dateLabel.text = transaction.formattedDate()
        statusLabel.text = transaction.status
        
        kernelIdLabel.text = transaction.kernelId
        feeLabel.text = String.currency(value: transaction.fee)
        senderAddressLabel.text = transaction.senderAddress
        receiverAddressLabel.text = transaction.receiverAddress
        
        failedView.isHidden = transaction.failureReason.isEmpty
        failedReasonLabel.text = transaction.failureReason
        
        if transaction.comment.isEmpty {
            commentView.isHidden = true
            commentLabel.text = ""
            commentTitleLabel.text = ""
            failedYOffset.constant = 5
        }
        else{
            commentLabel.text = transaction.comment
        }
    }
}
