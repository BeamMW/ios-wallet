//
//  ReceiveAddressOptionsCell.swift
//  BeamWallet
//
//  Created by Denis on 01.07.2020.
//  Copyright © 2020 Denis. All rights reserved.
//

import UIKit

@objc protocol ReceiveAddressOptionsCellDelegate: AnyObject {
    @objc optional func onWallet()
    @objc optional func onPool()
    @objc optional func onOneTime()
    @objc optional func onPermament()
    @objc optional func onShowToken()
}

class ReceiveAddressOptionsCell: BaseCell {
    weak var delegate: ReceiveAddressOptionsCellDelegate?

    @IBOutlet private var generalLabel: UILabel!
    @IBOutlet private var fromLabel: UILabel!
    @IBOutlet private var tokenLabel: UILabel!
    @IBOutlet private var tokenValueLabel: UILabel!

    @IBOutlet private var oneTimeWidth: NSLayoutConstraint!
    @IBOutlet private var walletWidth: NSLayoutConstraint!

    @IBOutlet private var oneTimeButton: UIButton!
    @IBOutlet private var permButton: UIButton!
    @IBOutlet private var walletButton: UIButton!
    @IBOutlet private var poolButton: UIButton!

    private var oneTime = false
    private var wallet = false
    private var token = ""

    override func awakeFromNib() {
        super.awakeFromNib()
        
        permButton.setTitle(Localizable.shared.strings.permanent, for: .normal)
        oneTimeButton.setTitle(Localizable.shared.strings.one_time, for: .normal)
        walletButton.setTitle(Localizable.shared.strings.wallet, for: .normal)
        poolButton.setTitle(Localizable.shared.strings.pool, for: .normal)

        if Settings.sharedManager().isDarkMode {
            fromLabel.textColor = UIColor.main.steel;
            tokenLabel.textColor = UIColor.main.steel;
            generalLabel.textColor = UIColor.main.steel;
        }
        
        generalLabel.text = Localizable.shared.strings.general.uppercased()
        generalLabel.letterSpacing = 2
        
        fromLabel.text = Localizable.shared.strings.receive_from.uppercased()
        fromLabel.letterSpacing = 2
        
        tokenLabel.text = Localizable.shared.strings.transaction_token.uppercased()
        tokenLabel.letterSpacing = 2
        
        selectionStyle = .none
    }
    
    @IBAction func onWallet(sender: UIButton) {
        delegate?.onWallet?()
    }
    
    @IBAction func onPool(sender: UIButton) {
        delegate?.onPool?()
    }
    
    @IBAction func onOneTime(sender: UIButton) {
        delegate?.onOneTime?()
    }
    
    @IBAction func onPerm(sender: UIButton) {
        delegate?.onPermament?()
    }
    
    @IBAction func onShowToken(sender: UIButton) {
        delegate?.onShowToken?()
    }
}

extension ReceiveAddressOptionsCell: Configurable {
    
    func configure(with options: (oneTime: Bool, wallet: Bool, token: String)) {
        oneTime = options.oneTime
        wallet = options.wallet
        token = options.token
        
        if options.oneTime {
            oneTimeWidth.constant = 120
            oneTimeButton.setBackgroundColor(color: UIColor.main.brightTeal.withAlphaComponent(0.1), forState: .normal)
            oneTimeButton.setTitleColor(UIColor.main.brightTeal, for: .normal)
            oneTimeButton.borderWidth = 1
            oneTimeButton.borderColor = UIColor.main.brightTeal
            oneTimeButton.contentHorizontalAlignment = .center
            
            permButton.setBackgroundColor(color: UIColor.clear, forState: .normal)
            permButton.setTitleColor(UIColor.white, for: .normal)
            permButton.borderWidth = 0
            permButton.borderColor = UIColor.clear
        }
        else {
            permButton.setBackgroundColor(color: UIColor.main.brightTeal.withAlphaComponent(0.1), forState: .normal)
            permButton.setTitleColor(UIColor.main.brightTeal, for: .normal)
            permButton.borderWidth = 1
            permButton.borderColor = UIColor.main.brightTeal
            
            oneTimeButton.setBackgroundColor(color: UIColor.clear, forState: .normal)
            oneTimeButton.setTitleColor(UIColor.white, for: .normal)
            oneTimeButton.borderWidth = 0
            oneTimeButton.borderColor = UIColor.clear
            oneTimeButton.contentHorizontalAlignment = .left
            oneTimeWidth.constant = 100
        }
        
        if options.wallet {
            walletWidth.constant = 120
            walletButton.setBackgroundColor(color: UIColor.main.brightTeal.withAlphaComponent(0.1), forState: .normal)
            walletButton.setTitleColor(UIColor.main.brightTeal, for: .normal)
            walletButton.borderWidth = 1
            walletButton.borderColor = UIColor.main.brightTeal
            walletButton.contentHorizontalAlignment = .center

            poolButton.setBackgroundColor(color: UIColor.clear, forState: .normal)
            poolButton.setTitleColor(UIColor.white, for: .normal)
            poolButton.borderWidth = 0
            poolButton.borderColor = UIColor.clear
        }
        else {
            poolButton.setBackgroundColor(color: UIColor.main.brightTeal.withAlphaComponent(0.1), forState: .normal)
            poolButton.setTitleColor(UIColor.main.brightTeal, for: .normal)
            poolButton.borderWidth = 1
            poolButton.borderColor = UIColor.main.brightTeal
            
            walletButton.setBackgroundColor(color: UIColor.clear, forState: .normal)
            walletButton.setTitleColor(UIColor.white, for: .normal)
            walletButton.borderWidth = 0
            walletButton.borderColor = UIColor.clear
            walletButton.contentHorizontalAlignment = .left
            walletWidth.constant = 60
        }
        
        tokenValueLabel.text = options.token
    }
}
