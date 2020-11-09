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

    @IBOutlet weak var addressTypeSegment: MASegmentedControl! {
        didSet {
            addressTypeSegment.itemsWithText = true
            addressTypeSegment.fillEqually = true
            addressTypeSegment.roundedControl = true
            
            addressTypeSegment.setSegmentedWith(items: [Localizable.shared.strings.regular, Localizable.shared.strings.max_privacy])
            addressTypeSegment.padding = 0
            addressTypeSegment.textColor = UIColor.main.blueyGrey
            addressTypeSegment.selectedTextColor = UIColor.main.brightTeal
            addressTypeSegment.thumbViewColor = UIColor.main.brightTeal.withAlphaComponent(0.2)
            addressTypeSegment.titlesFont = SemiboldFont(size: 14)
            addressTypeSegment.segmentedBackGroundColor = UIColor.white.withAlphaComponent(0.1)
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
    
    @IBOutlet private var addressTypeLabel: UILabel!
    @IBOutlet private var expirationLabel: UILabel!
    @IBOutlet private var errorLabel: UILabel!
    @IBOutlet private var offset: NSLayoutConstraint!

    override func awakeFromNib() {
        super.awakeFromNib()
        
        if Settings.sharedManager().isDarkMode {
            addressTypeLabel.textColor = UIColor.main.steel;
            expirationLabel.textColor = UIColor.main.steel;
            errorLabel.textColor = UIColor.main.steel;
        }
        
        expirationLabel.setLetterSpacingOnly(value: 1.5, title: Localizable.shared.strings.address_expiration.uppercased(), letter: Localizable.shared.strings.address_expiration.uppercased())

        addressTypeLabel.setLetterSpacingOnly(value: 1.5, title: Localizable.shared.strings.address_type.uppercased(), letter: Localizable.shared.strings.address_type.uppercased())
        
        selectionStyle = .none
        
        if AppModel.sharedManager().checkIsOwnNode() {
            errorLabel.isHidden = true
            offset.constant = -5
        }
        else {
            offset.constant = 25
            addressTypeSegment.isUserInteractionEnabled = false
            addressTypeSegment.textColor = UIColor.main.blueyGrey.withAlphaComponent(0.2)
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
            addressTypeSegment.selectedSegmentIndex = options.maxPrivacy ? 1 : 0
            expireTypeSegment.selectedSegmentIndex = options.oneTime ? 0 : 1
        }
    }
}
