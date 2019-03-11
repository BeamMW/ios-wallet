//
//  WalletAvailableCell.swift
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

protocol WalletAvailableCellDelegate: AnyObject {
    func onExpandAvailable()
}

class WalletAvailableCell: UITableViewCell {

    weak var delegate: WalletAvailableCellDelegate?

    @IBOutlet weak private var balanceLabel: UILabel!
    @IBOutlet weak private var balanceIcon: UIImageView!
    @IBOutlet weak private var arrowIcon: UIImageView!
    @IBOutlet weak private var currencyIcon: UIImageView!

    override func awakeFromNib() {
        super.awakeFromNib()
        
        selectionStyle = .none
        
        currencyIcon.image = UIImage.init(named: "iconSymbol")?.withRenderingMode(.alwaysTemplate)
        currencyIcon.tintColor = UIColor.white
    }
    
    @IBAction func onExpand(sender :UIButton) {
        if balanceIcon.alpha == 1 {
            UIView.animate(withDuration: 0.3) {
                self.balanceIcon.alpha = 0
                self.balanceLabel.alpha = 0
                self.currencyIcon.alpha = 0
                self.arrowIcon.transform = CGAffineTransform(rotationAngle: CGFloat(-90 * Double.pi/180))
            }
        }
        else{
            UIView.animate(withDuration: 0.3) {
                self.balanceIcon.alpha = 1
                self.balanceLabel.alpha = 1
                self.currencyIcon.alpha = 1
                self.arrowIcon.transform = CGAffineTransform(rotationAngle: CGFloat(0 * Double.pi/180))
            }
        }
        self.delegate?.onExpandAvailable()
    }
}

extension WalletAvailableCell: Configurable {
    
    func configure(with options: (expand: Bool, status:BMWalletStatus?)) {
        if let status = options.status {
            balanceLabel.text = String.currency(value: status.realAmount)
        }
        else{
            balanceLabel.text = "0"
        }
        
        if options.expand {
            balanceIcon.alpha = 1
            balanceLabel.alpha = 1
            currencyIcon.alpha = 1
            arrowIcon.transform = CGAffineTransform(rotationAngle: CGFloat(0 * Double.pi/180))
        }
        else{
            balanceIcon.alpha = 0
            balanceLabel.alpha = 0
            currencyIcon.alpha = 0
            arrowIcon.transform = CGAffineTransform(rotationAngle: CGFloat(-90 * Double.pi/180))
        }
    }
}
