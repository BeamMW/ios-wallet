//
//  ReceiveAddressTokensCell.swift
//  BeamWallet
//
//  Created by Denis on 28.07.2020.
//  Copyright © 2020 Denis. All rights reserved.
//

import UIKit

@objc protocol ReceiveAddressTokensCellDelegate: AnyObject {
    @objc optional func onShowToken(token:String)
    @objc optional func onShowQR(token:String)
    @objc optional func onSwitchToPool()
    @objc optional func onShareToken()
}

class ReceiveAddressTokensCell: BaseCell, BMCopyLabelDelegate {

    weak var delegate: ReceiveAddressTokensCellDelegate?

    @IBOutlet private var switchButton: UIButton!
    @IBOutlet private var qrButton2: UIButton!

    @IBOutlet private var onlineTokenView: UIView!
    @IBOutlet private var offlineTokenView: UIView!
    @IBOutlet private var exchangeTokenView: UIView!
    
    @IBOutlet private var onlineTokenLabel: UILabel!
    @IBOutlet private var onlineTokenValueLabel: BMCopyLabel!
    
    @IBOutlet private var offlineTokenLabel: UILabel!
    @IBOutlet private var offlineTokenValueLabel: BMCopyLabel!
    
    @IBOutlet private var exchangeTokenLabel: UILabel!
    @IBOutlet private var exchangeTokenValueLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        offlineTokenValueLabel.delegate = self
        onlineTokenValueLabel.delegate = self
        
        if Settings.sharedManager().isDarkMode {
            onlineTokenLabel.textColor = UIColor.main.steel;
            offlineTokenLabel.textColor = UIColor.main.steel;
            exchangeTokenLabel.textColor = UIColor.main.steel;
            exchangeTokenValueLabel.textColor = UIColor.main.steel;
        }
        
        onlineTokenLabel.setLetterSpacingOnly(value: 2, title: "\(Localizable.shared.strings.online_token.uppercased()) (\(Localizable.shared.strings.for_wallet.lowercased()))", letter: Localizable.shared.strings.online_token.uppercased())
        
        offlineTokenLabel.setLetterSpacingOnly(value: 2, title: "\(Localizable.shared.strings.offline_token.uppercased()) (\(Localizable.shared.strings.for_pool.lowercased()))", letter: Localizable.shared.strings.offline_token.uppercased())
        
        exchangeTokenLabel.setLetterSpacingOnly(value: 2, title: "\(Localizable.shared.strings.offline_token.uppercased()) (\(Localizable.shared.strings.for_pool.lowercased()))", letter: Localizable.shared.strings.offline_token.uppercased())
        
        selectionStyle = .none
    }
}

extension ReceiveAddressTokensCell: Configurable {
    
    func configure(with options: (oneTime: Bool, maxPrivacy: Bool, address: BMAddress)) {
        onlineTokenValueLabel.text = options.address.token
        onlineTokenValueLabel.copiedText = Localizable.shared.strings.address_copied
        offlineTokenValueLabel.copiedText = Localizable.shared.strings.address_copied

        switchButton.setTitle(Localizable.shared.strings.switch_to_permanent, for: .normal)
        qrButton2.isHidden = true
        
        if(!options.maxPrivacy && options.oneTime) {
            offlineTokenValueLabel.text = options.address.offlineToken
            offlineTokenView.isHidden = true
            exchangeTokenView.isHidden = false
            onlineTokenView.isHidden = false

            exchangeTokenLabel.setLetterSpacingOnly(value: 2, title: "\(Localizable.shared.strings.online_token.uppercased()) (\(Localizable.shared.strings.for_pool.lowercased()))", letter: Localizable.shared.strings.online_token.uppercased())
            exchangeTokenValueLabel.text = Localizable.shared.strings.for_pool_permanent
        }
        else if(options.maxPrivacy && options.oneTime) {
            offlineTokenValueLabel.text = options.address.offlineToken
            offlineTokenView.isHidden = false
            exchangeTokenView.isHidden = false
            
            offlineTokenLabel.setLetterSpacingOnly(value: 2, title: "\(Localizable.shared.strings.offline_token.uppercased()) (\(Localizable.shared.strings.for_wallet.lowercased()))", letter: Localizable.shared.strings.offline_token.uppercased())
            exchangeTokenLabel.setLetterSpacingOnly(value: 2, title: "\(Localizable.shared.strings.online_token.uppercased()) (\(Localizable.shared.strings.for_pool.lowercased()))", letter: Localizable.shared.strings.online_token.uppercased())
            exchangeTokenValueLabel.text = Localizable.shared.strings.for_pool_permanent
        }
        else if(!options.maxPrivacy && !options.oneTime) {
            offlineTokenValueLabel.text = options.address.walletId
            exchangeTokenView.isHidden = true
            offlineTokenView.isHidden = false
            qrButton2.isHidden = false

            offlineTokenLabel.setLetterSpacingOnly(value: 2, title: "\(Localizable.shared.strings.online_token.uppercased()) (\(Localizable.shared.strings.for_pool.lowercased()))", letter: Localizable.shared.strings.online_token.uppercased())
            exchangeTokenValueLabel.text = Localizable.shared.strings.for_pool_permanent
        }
        else if(options.maxPrivacy && !options.oneTime) {
            offlineTokenValueLabel.text = options.address.offlineToken
            exchangeTokenView.isHidden = true
            onlineTokenView.isHidden = true
            offlineTokenView.isHidden = false
            
            offlineTokenLabel.setLetterSpacingOnly(value: 2, title: "\(Localizable.shared.strings.offline_token.uppercased()) (\(Localizable.shared.strings.for_wallet.lowercased()))", letter: Localizable.shared.strings.offline_token.uppercased())
            exchangeTokenLabel.setLetterSpacingOnly(value: 2, title: "\(Localizable.shared.strings.online_token.uppercased()) (\(Localizable.shared.strings.for_pool.lowercased()))", letter: Localizable.shared.strings.online_token.uppercased())
            exchangeTokenValueLabel.text = Localizable.shared.strings.for_pool_regular
            switchButton.setTitle(Localizable.shared.strings.switch_to_regular, for: .normal)
        }
        
        exchangeTokenView.isHidden = true
    }
    
    @IBAction func onShowToken_1(sender: UIButton) {
        if let token = onlineTokenValueLabel.text {
            self.delegate?.onShowToken?(token: token)
        }
    }
    
    @IBAction func onShowToken_2(sender: UIButton) {
        if let token = offlineTokenValueLabel.text {
            self.delegate?.onShowToken?(token: token)
        }
    }
    
    @IBAction func onShowQR_1(sender: UIButton) {
        if let token = onlineTokenValueLabel.text {
            self.delegate?.onShowQR?(token: token)
        }
    }
    
    @IBAction func onShowQR_2(sender: UIButton) {
        if let token = offlineTokenValueLabel.text {
            self.delegate?.onShowQR?(token: token)
        }
    }
    
    @IBAction func onSwitch(sender: UIButton) {
        self.delegate?.onSwitchToPool?()
    }
    
    func onCopied() {
        self.delegate?.onShareToken?()
    }
}
