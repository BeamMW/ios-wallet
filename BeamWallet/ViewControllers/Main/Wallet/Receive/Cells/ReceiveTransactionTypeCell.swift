//
//  ReceiveTransactionTypeCell.swift
//  BeamWallet
//
//  Created by Denis on 08.04.2021.
//  Copyright © 2021 Denis. All rights reserved.
//

import UIKit

protocol ReceiveTransactionTypeCellDelegate: AnyObject {
    func onDidSelectTrasactionType(type: ReceiveAddressViewModel.TransactionOptions)
}

class ReceiveTransactionTypeCell: UITableViewCell {

    public weak var delegate:ReceiveTransactionTypeCellDelegate? = nil
    
    @IBOutlet private var transactionTypeLabel: UILabel!
    @IBOutlet private var errorLabel: UILabel!
    @IBOutlet private var bottomOffset: NSLayoutConstraint!

    @IBOutlet private var transactionTypeSegment: MASegmentedControl! {
        didSet {
            transactionTypeSegment.itemsWithText = true
            transactionTypeSegment.fillEqually = true
            transactionTypeSegment.roundedControl = true
            
            transactionTypeSegment.setSegmentedWith(items: [Localizable.shared.strings.regular, Localizable.shared.strings.max_privacy])
            transactionTypeSegment.padding = 0
            transactionTypeSegment.textColor = UIColor.main.blueyGrey
            transactionTypeSegment.selectedTextColor = UIColor.main.brightTeal
            transactionTypeSegment.thumbViewColor = UIColor.main.brightTeal.withAlphaComponent(0.2)
            transactionTypeSegment.titlesFont = SemiboldFont(size: 14)
            transactionTypeSegment.segmentedBackGroundColor = UIColor.white.withAlphaComponent(0.1)
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
       
        selectionStyle = .none
        
        transactionTypeLabel.text = Localizable.shared.strings.transaction_type.uppercased()
        transactionTypeLabel.letterSpacing = 2
        
        if Settings.sharedManager().isDarkMode {
            errorLabel.textColor = UIColor.main.steel
        }
        else {
            errorLabel.textColor = UIColor.main.blueyGrey
        }
    }
    
    @IBAction private func onTransactionType(sender: MASegmentedControl) {
        let type = sender.selectedSegmentIndex == 0 ? ReceiveAddressViewModel.TransactionOptions.regular : ReceiveAddressViewModel.TransactionOptions.privacy
        self.delegate?.onDidSelectTrasactionType(type: type)
    }
    
    public func disable() {
        bottomOffset.constant = (Device.isXDevice || Device.isLarge) ? 45 : 55
        errorLabel.isHidden = false
        transactionTypeSegment.isUserInteractionEnabled = false
        transactionTypeSegment.textColor = UIColor.main.blueyGrey.withAlphaComponent(0.2)
    }
}
