//
//  OnboardCell.swift
//  BeamWallet
//
//  Created by Denis on 10/11/19.
//  Copyright © 2019 Denis. All rights reserved.
//

import UIKit

protocol OnboardCellDelegate: AnyObject {
    func onClickReceiveFaucet()
    func onClickCloseFaucet()
    func onClickMakeSecure()
}


class OnboardCell: UITableViewCell {
    
    @IBOutlet weak private var mainView: UIView!
    @IBOutlet weak private var titleLabel: UILabel!
    @IBOutlet weak private var detailLabel: UILabel!
    @IBOutlet weak private var nextButton: BMButton!
    @IBOutlet weak private var receiveButton: BMButton!
    @IBOutlet weak private var noButton: BMButton!

    weak var delegate: OnboardCellDelegate?

    override func awakeFromNib() {
        super.awakeFromNib()
       
        selectionStyle = .none
        
        titleLabel.text = Localizable.shared.strings.faucet_title
        titleLabel.letterSpacing = 1.5
        
        noButton.setTitle(Localizable.shared.strings.no.lowercased(), for: .normal)
        receiveButton.setTitle(Localizable.shared.strings.yes_please.lowercased(), for: .normal)
        
        mainView.backgroundColor = UIColor.white.withAlphaComponent(0.05)
    }
    
    public func setIsSecure(secure:Bool) {        
        if secure {
            mainView.backgroundColor = UIColor.main.cyan.withAlphaComponent(0.3)
            titleLabel.text = Localizable.shared.strings.make_wallet_secure_title
            detailLabel.text = Localizable.shared.strings.make_wallet_secure_text
            noButton.isHidden = true
            receiveButton.isHidden = true
            nextButton.isHidden = false
        }
    }
    
    @IBAction private func onClose (sender :UIButton) {
        self.delegate?.onClickCloseFaucet()
    }
    
    @IBAction private func onVerefication (sender :UIButton) {
        self.delegate?.onClickMakeSecure()
    }
    
    @IBAction private func onReceive (sender :UIButton) {
        self.delegate?.onClickReceiveFaucet()
    }
}
