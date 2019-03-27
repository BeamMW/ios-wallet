//
//  WalletProgressCell.swift
//  BeamWallet
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

protocol WalletProgressCellDelegate: AnyObject {
    func onExpandProgress()
}


class WalletProgressCell: BaseCell {
    
    weak var delegate: WalletProgressCellDelegate?
    
    
    @IBOutlet weak private var receivingLabel: UILabel!
    @IBOutlet weak private var sentLabel: UILabel!
    @IBOutlet weak private var maturingLabel: UILabel!

    @IBOutlet weak private var arrowIcon: UIImageView!
    
    @IBOutlet weak private var receivingStack: UIStackView!
    @IBOutlet weak private var sentStack: UIStackView!
    @IBOutlet weak private var maturingStack: UIStackView!
    @IBOutlet weak private var mainStackView: UIStackView!

    @IBOutlet weak private var currencyReceivingIcon: UIImageView!
    @IBOutlet weak private var currencySendingIcon: UIImageView!
    @IBOutlet weak private var currencyMaturingIcon: UIImageView!

    override func awakeFromNib() {
        super.awakeFromNib()
        
        currencyReceivingIcon.image = UIImage.init(named: "iconSymbol")?.withRenderingMode(.alwaysTemplate)
        currencyReceivingIcon.tintColor = receivingLabel.textColor
        
        currencySendingIcon.image = UIImage.init(named: "iconSymbol")?.withRenderingMode(.alwaysTemplate)
        currencySendingIcon.tintColor = sentLabel.textColor
        
        currencyMaturingIcon.image = UIImage.init(named: "iconSymbol")?.withRenderingMode(.alwaysTemplate)
        currencyMaturingIcon.tintColor = maturingLabel.textColor
        
        selectionStyle = .none

    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
    }
    
    @IBAction func onExpand(sender :UIButton) {
        if receivingStack.alpha == 1 {
            UIView.animate(withDuration: 0.3) {
                self.mainStackView.alpha = 0
                self.arrowIcon.transform = CGAffineTransform(rotationAngle: CGFloat(-90 * Double.pi/180))
            }
        }
        else{
            UIView.animate(withDuration: 0.3) {
                self.mainStackView.alpha = 1
                self.arrowIcon.transform = CGAffineTransform(rotationAngle: CGFloat(0 * Double.pi/180))
            }
        }
        self.delegate?.onExpandProgress()
    }
}

extension WalletProgressCell: Configurable {
    
    func configure(with options: (expand: Bool, status:BMWalletStatus?)) {
        if let status = options.status {
            receivingLabel.text = "+" + String.currency(value: status.realReceiving)
            sentLabel.text = "-" + String.currency(value: status.realSending)
            maturingLabel.text = String.currency(value: status.realMaturing)
            
            maturingStack.isHidden = status.realMaturing == 0 ? true : false
            sentStack.isHidden = status.realSending == 0 ? true : false
            receivingStack.isHidden = status.realReceiving == 0 ? true : false
        }
        else{
            sentLabel.text = "0"
            maturingLabel.text = "0"
            receivingLabel.text = "0"
        }
        
        if !options.expand {
            mainStackView.alpha = 0
            arrowIcon.transform = CGAffineTransform(rotationAngle: CGFloat(-90 * Double.pi/180))
        }
        else{
            mainStackView.alpha = 1
            arrowIcon.transform = CGAffineTransform(rotationAngle: CGFloat(0 * Double.pi/180))
        }
    }
}
