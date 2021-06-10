//
// OnboardCell.swift
// BeamWallet
//
// Copyright 2018 Beam Development
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
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
    @IBOutlet weak private var closeButton: UIButton!

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
            
            closeButton.isHidden = true
            receiveButton.isHidden = true
            verificationButton.isHidden = false
        }
        else {
            closeButton.isHidden = false
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
