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

    @IBOutlet weak private var receivingLabelMaxWidth: NSLayoutConstraint!
    @IBOutlet weak private var sentLabelMaxWidth: NSLayoutConstraint!
    @IBOutlet weak private var maturingLabelMaxWidth: NSLayoutConstraint!
    
    @IBOutlet weak private var receivingLabel: UILabel!
    @IBOutlet weak private var sentLabel: UILabel!
    @IBOutlet weak private var maturingLabel: UILabel!

    @IBOutlet weak private var arrowIcon: UIImageView!
    @IBOutlet weak private var receivingStack: UIStackView!
    @IBOutlet weak private var sentStack: UIStackView!
    @IBOutlet weak private var maturingStack: UIStackView!

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
        
        receivingLabelMaxWidth.constant = (UIScreen.main.bounds.size.width - 110)/3
        sentLabelMaxWidth.constant = (UIScreen.main.bounds.size.width - 110)/3
        maturingLabelMaxWidth.constant = (UIScreen.main.bounds.size.width - 110)/3

    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
    }
    
    @IBAction func onExpand(sender :UIButton) {
        if receivingStack.alpha == 1 {
            UIView.animate(withDuration: 0.3) {
                self.receivingStack.alpha = 0
                self.sentStack.alpha = 0
                self.maturingStack.alpha = 0
                self.arrowIcon.transform = CGAffineTransform(rotationAngle: CGFloat(-90 * Double.pi/180))
            }
        }
        else{
            UIView.animate(withDuration: 0.3) {
                self.receivingStack.alpha = 1
                self.sentStack.alpha = 1
                self.maturingStack.alpha = 1
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
        }
        else{
            sentLabel.text = "0.00"
            maturingLabel.text = "0.00"
            receivingLabel.text = "0.00"
        }
        
        if !options.expand {
            receivingStack.alpha = 0
            sentStack.alpha = 0
            maturingStack.alpha = 0
            arrowIcon.transform = CGAffineTransform(rotationAngle: CGFloat(-90 * Double.pi/180))
        }
        else{
            receivingStack.alpha = 1
            sentStack.alpha = 1
            maturingStack.alpha = 1
            arrowIcon.transform = CGAffineTransform(rotationAngle: CGFloat(0 * Double.pi/180))
        }
    }
}
