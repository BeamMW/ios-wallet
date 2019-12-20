//
//  OnboardCell.swift
//  BeamWallet
//
//  Created by Denis on 10/11/19.
//  Copyright © 2019 Denis. All rights reserved.
//

import UIKit

protocol OnboardCellDelegate: AnyObject {
    func onClickReceiveFaucet(cell:UITableViewCell)
    func onClickCloseFaucet(cell:UITableViewCell)
    func onClickMakeSecure(cell:UITableViewCell)
}


class OnboardCell: UITableViewCell {
    
    @IBOutlet weak private var mainView: UIView!
    
    @IBOutlet weak private var detailLabel: UILabel!
    
    @IBOutlet weak private var verificationButton: BMButton!
    @IBOutlet weak private var receiveButton: BMButton!

    weak var delegate: OnboardCellDelegate?

    override func awakeFromNib() {
        super.awakeFromNib()
       
        selectionStyle = .none
        
        receiveButton.setTitle(Localizable.shared.strings.get_coins.lowercased(), for: .normal)
        verificationButton.setTitle(Localizable.shared.strings.complete_verification, for: .normal)

        mainView.backgroundColor = UIColor.white.withAlphaComponent(0.05)
    }
    
    public func setIsSecure(secure: Bool) {
        if secure {
            detailLabel.text = Localizable.shared.strings.make_wallet_secure_text
            
            receiveButton.isHidden = true
            verificationButton.isHidden = false
        }
        else {           
            receiveButton.isHidden = false
            verificationButton.isHidden = true
                    
            detailLabel.text = Localizable.shared.strings.faucet_text
        }
    }
    
    @IBAction private func onClose (sender :UIButton) {
        self.delegate?.onClickCloseFaucet(cell:self)
    }
    
    @IBAction private func onVerefication (sender :UIButton) {
        self.delegate?.onClickMakeSecure(cell:self)
    }
    
    @IBAction private func onReceive (sender :UIButton) {
        self.delegate?.onClickReceiveFaucet(cell: self)
    }
}
