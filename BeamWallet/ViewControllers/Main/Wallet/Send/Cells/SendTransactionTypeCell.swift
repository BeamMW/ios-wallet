//
//  SendTransactionTypeCell.swift
//  BeamWallet
//
//  Created by Denis on 20.04.2021.
//  Copyright © 2021 Denis. All rights reserved.
//

import UIKit

protocol SendTransactionTypeCellDelegate: AnyObject {
    func onDidSelectTrasactionType(maxPrivacy: Bool)
}

class SendTransactionTypeCell: UITableViewCell {
    
    public weak var delegate:SendTransactionTypeCellDelegate? = nil

    @IBOutlet private var transactionTypeLabel: UILabel!

    public var selectedIndex = 1
    
    @IBOutlet private var transactionTypeSegment: MASegmentedControl! {
        didSet {
            transactionTypeSegment.itemsWithText = true
            transactionTypeSegment.fillEqually = true
            transactionTypeSegment.roundedControl = true
            
            transactionTypeSegment.setSegmentedWith(items: [Localizable.shared.strings.regular, Localizable.shared.strings.offline])
            transactionTypeSegment.padding = 0
            transactionTypeSegment.textColor = UIColor.main.blueyGrey
            transactionTypeSegment.selectedTextColor = UIColor.main.brightTeal
            transactionTypeSegment.thumbViewColor = UIColor.main.brightTeal.withAlphaComponent(0.2)
            transactionTypeSegment.titlesFont = SemiboldFont(size: 14)
            transactionTypeSegment.segmentedBackGroundColor = UIColor.white.withAlphaComponent(0.1)
        }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        transactionTypeSegment.selectedSegmentIndex = selectedIndex
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        selectionStyle = .none
        
        transactionTypeLabel.text = Localizable.shared.strings.transaction_type.uppercased()
        transactionTypeLabel.letterSpacing = 2
        transactionTypeSegment.selectedSegmentIndex = selectedIndex
    }
    
    @IBAction private func onTransactionType(sender: MASegmentedControl) {
        self.delegate?.onDidSelectTrasactionType(maxPrivacy: sender.selectedSegmentIndex == 1)
    }
}
