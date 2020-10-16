//
//  ReceiveAddressOptionsCell_2.swift
//  BeamWallet
//
//  Created by Denis on 01.07.2020.
//  Copyright © 2020 Denis. All rights reserved.
//

import UIKit


class ReceiveAddressOptionsCell_2: BaseCell {
    weak var delegate: ReceiveAddressOptionsCellDelegate?
    
    @IBOutlet weak var transactionTypeSegment: MASegmentedControl! {
        didSet {
            transactionTypeSegment.itemsWithText = true
            transactionTypeSegment.fillEqually = true
            transactionTypeSegment.roundedControl = true
            transactionTypeSegment.setSegmentedWith(items: [Localizable.shared.strings.regular, Localizable.shared.strings.max_privacy_title])
            transactionTypeSegment.padding = 2
            transactionTypeSegment.textColor = UIColor.main.blueyGrey
            transactionTypeSegment.selectedTextColor = UIColor.main.brightTeal
            transactionTypeSegment.thumbViewColor = UIColor.main.brightTeal.withAlphaComponent(0.2)
            transactionTypeSegment.titlesFont = SemiboldFont(size: 14)
            transactionTypeSegment.segmentedBackGroundColor = UIColor.white.withAlphaComponent(0.1)
            transactionTypeSegment.selectedSegmentIndex = 1
        }
    }
    
    
    @IBOutlet private var transactionTypeLabel: UILabel!
    @IBOutlet private var infoLabel: UILabel!

    override func awakeFromNib() {
        super.awakeFromNib()
        
        if Settings.sharedManager().isDarkMode {
            transactionTypeLabel.textColor = UIColor.main.steel;
            infoLabel.textColor = UIColor.main.steel;
        }
        
        
        transactionTypeLabel.setLetterSpacingOnly(value: 2, title: Localizable.shared.strings.transaction_type.uppercased(), letter: Localizable.shared.strings.transaction_type.uppercased())
        
        selectionStyle = .none        
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        transactionTypeSegment.buttonTappedWithoutAction(button: transactionTypeSegment.buttons[1])
        transactionTypeSegment.selectedSegmentIndex = 1
    }
    
    @IBAction func onTransaction(sender: MASegmentedControl) {
        if(sender.selectedSegmentIndex == 0) {
            self.delegate?.onRegular?()
        }
    }
    
    public func configure() {
        transactionTypeSegment.buttonTappedWithoutAction(button: transactionTypeSegment.buttons[1])
        transactionTypeSegment.selectedSegmentIndex = 1
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.transactionTypeSegment.buttonTappedWithoutAction(button: self.transactionTypeSegment.buttons[1])
        }
    }
}
