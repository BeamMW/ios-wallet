//
//  ReceiveAddressOptionsCell.swift
//  BeamWallet
//
//  Created by Denis on 01.07.2020.
//  Copyright © 2020 Denis. All rights reserved.
//

import UIKit

@objc protocol ReceiveAddressOptionsCellDelegate: AnyObject {
    @objc optional func onRegular()
    @objc optional func onMaxPrivacy()
    @objc optional func onOneTime()
    @objc optional func onPermament()
}

class ReceiveAddressOptionsCell: BaseCell {
    weak var delegate: ReceiveAddressOptionsCellDelegate?

    @IBOutlet weak var transactionTypeSegment: MASegmentedControl! {
        didSet {
            transactionTypeSegment.itemsWithText = true
            transactionTypeSegment.fillEqually = true
            transactionTypeSegment.roundedControl = true
            
            transactionTypeSegment.setSegmentedWith(items: [Localizable.shared.strings.regular, Localizable.shared.strings.max_privacy_title])
            transactionTypeSegment.padding = 0
            transactionTypeSegment.textColor = UIColor.main.blueyGrey
            transactionTypeSegment.selectedTextColor = UIColor.main.brightTeal
            transactionTypeSegment.thumbViewColor = UIColor.main.brightTeal.withAlphaComponent(0.2)
            transactionTypeSegment.titlesFont = SemiboldFont(size: 14)
            transactionTypeSegment.segmentedBackGroundColor = UIColor.white.withAlphaComponent(0.1)
        }
    }
    
    @IBOutlet weak var expireTypeSegment: MASegmentedControl! {
        didSet {
            expireTypeSegment.itemsWithText = true
            expireTypeSegment.fillEqually = true
            expireTypeSegment.roundedControl = true
            
            expireTypeSegment.setSegmentedWith(items: [Localizable.shared.strings.one_time, Localizable.shared.strings.permanent])
            expireTypeSegment.padding = 0
            expireTypeSegment.textColor = UIColor.main.blueyGrey
            expireTypeSegment.selectedTextColor = UIColor.main.brightTeal
            expireTypeSegment.thumbViewColor = UIColor.main.brightTeal.withAlphaComponent(0.2)
            expireTypeSegment.titlesFont = SemiboldFont(size: 14)
            expireTypeSegment.segmentedBackGroundColor = UIColor.white.withAlphaComponent(0.1)
        }
    }
    
    @IBOutlet private var transactionTypeLabel: UILabel!
    @IBOutlet private var expirationLabel: UILabel!
    @IBOutlet private var errorLabel: UILabel!
    @IBOutlet private var offset: NSLayoutConstraint!

    override func awakeFromNib() {
        super.awakeFromNib()
        
        if Settings.sharedManager().isDarkMode {
            transactionTypeLabel.textColor = UIColor.main.steel;
            expirationLabel.textColor = UIColor.main.steel;
            errorLabel.textColor = UIColor.main.steel;
        }
        
        expirationLabel.setLetterSpacingOnly(value: 2, title: Localizable.shared.strings.address_expiration.uppercased(), letter: Localizable.shared.strings.address_expiration.uppercased())

        transactionTypeLabel.setLetterSpacingOnly(value: 2, title: Localizable.shared.strings.transaction_type.uppercased(), letter: Localizable.shared.strings.transaction_type.uppercased())
        
        selectionStyle = .none
        
        if AppModel.sharedManager().checkIsOwnNode() {
            errorLabel.isHidden = true
            offset.constant = -5
        }
        else {
            offset.constant = 25
            transactionTypeSegment.isUserInteractionEnabled = false
            transactionTypeSegment.textColor = UIColor.main.blueyGrey.withAlphaComponent(0.2)
        }
        
        errorLabel.text = Localizable.shared.strings.connect_node_offline
    }
    
    @IBAction func onExpire(sender: MASegmentedControl) {
        if(sender.selectedSegmentIndex == 0) {
            self.delegate?.onOneTime?()
        }
        else {
            self.delegate?.onPermament?()
        }
    }
    
    @IBAction func onTransaction(sender: MASegmentedControl) {
        if(sender.selectedSegmentIndex == 0) {
            self.delegate?.onRegular?()
        }
        else {
            self.delegate?.onMaxPrivacy?()
        }
    }
}

extension ReceiveAddressOptionsCell: Configurable {
    
    func configure(with options: (oneTime: Bool, maxPrivacy: Bool, needReload: Bool)) {
        if options.needReload {
            transactionTypeSegment.selectedSegmentIndex = options.maxPrivacy ? 1 : 0
            expireTypeSegment.selectedSegmentIndex = options.oneTime ? 0 : 1
        }
    }
}
