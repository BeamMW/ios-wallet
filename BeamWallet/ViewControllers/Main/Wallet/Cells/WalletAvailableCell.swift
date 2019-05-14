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

class WalletAvailableCell: BaseCell {

    weak var delegate: WalletAvailableCellDelegate?

    @IBOutlet weak private var mainView: UIView!

    @IBOutlet weak private var balanceLabel: UILabel!
    @IBOutlet weak private var balanceIcon: UIImageView!
    @IBOutlet weak private var arrowIcon: UIImageView!
    @IBOutlet weak private var currencyIcon: UIImageView!
    
    @IBOutlet weak private var maturingLabel: UILabel!
    @IBOutlet weak private var maturingIcon: UIImageView!
    @IBOutlet weak private var maturingCurrencyIcon: UIImageView!
    @IBOutlet weak private var maturingDescriptionLabel: UILabel!

    
    public static func hideHeight() -> CGFloat {
        return 80
    }
    
    public static func mainHeight() -> CGFloat {
        return 175.0
    }
    
    public static func singleHeight() -> CGFloat {
        return 130.0
    }
        
    override func awakeFromNib() {
        super.awakeFromNib()
        
        selectionStyle = .none
        
        currencyIcon.image = UIImage.init(named: "iconSymbol")?.withRenderingMode(.alwaysTemplate)
        currencyIcon.tintColor = UIColor.white
        
        maturingCurrencyIcon.image = UIImage.init(named: "iconSymbol")?.withRenderingMode(.alwaysTemplate)
        maturingCurrencyIcon.tintColor = UIColor.white
    }
    
    @IBAction func onExpand(sender :UIButton) {
        if balanceIcon.alpha == 1 {
            UIView.animate(withDuration: 0.3) {
                self.maturingLabel.alpha = 0
                self.maturingIcon.alpha = 0
                self.maturingCurrencyIcon.alpha = 0
                self.maturingDescriptionLabel.alpha = 0

                self.balanceIcon.alpha = 0
                self.balanceLabel.alpha = 0
                self.currencyIcon.alpha = 0
                self.arrowIcon.transform = CGAffineTransform(rotationAngle: CGFloat(-90 * Double.pi/180))
            }
        }
        else{
            UIView.animate(withDuration: 0.3) {
                if self.maturingLabel.text != "" {
                    self.maturingLabel.alpha = 1
                    self.maturingIcon.alpha = 1
                    self.maturingCurrencyIcon.alpha = 1
                    self.maturingDescriptionLabel.alpha = 1
                }
                
                
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
            maturingLabel.text = String.currency(value: status.realMaturing)
        }
        else{
            balanceLabel.text = "0"
            maturingLabel.text = ""
        }
        
        if options.expand {
            if maturingLabel.text != "" {
                maturingLabel.alpha = 1
                maturingIcon.alpha = 1
                maturingCurrencyIcon.alpha = 1
                maturingDescriptionLabel.alpha = 1
            }
      
            
            balanceIcon.alpha = 1
            balanceLabel.alpha = 1
            currencyIcon.alpha = 1
            arrowIcon.transform = CGAffineTransform(rotationAngle: CGFloat(0 * Double.pi/180))
        }
        else{
            maturingLabel.alpha = 0
            maturingIcon.alpha = 0
            maturingCurrencyIcon.alpha = 0
            maturingDescriptionLabel.alpha = 0
            
            balanceIcon.alpha = 0
            balanceLabel.alpha = 0
            currencyIcon.alpha = 0
            arrowIcon.transform = CGAffineTransform(rotationAngle: CGFloat(-90 * Double.pi/180))
        }
        
        arrowIcon.alpha = Settings.sharedManager().isHideAmounts ? 0 : 1
        mainView.alpha =  Settings.sharedManager().isHideAmounts ? 0.7 : 1
        mainView.isUserInteractionEnabled =  Settings.sharedManager().isHideAmounts ? false : true
    }
}
