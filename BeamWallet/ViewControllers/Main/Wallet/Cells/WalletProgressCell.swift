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
    
    @IBOutlet weak private var mainView: UIView!

    @IBOutlet weak private var titleLabel: UILabel!

    @IBOutlet weak private var receivingLabel: UILabel!
    @IBOutlet weak private var sentLabel: UILabel!

    @IBOutlet weak private var arrowIcon: UIImageView!
    
    @IBOutlet weak private var receivingStack: UIStackView!
    @IBOutlet weak private var sentStack: UIStackView!
    @IBOutlet weak private var mainStackView: UIStackView!

    @IBOutlet weak private var mainButton: UIButton!
    
    @IBOutlet weak private var secondSendLabel: UILabel!
    @IBOutlet weak private var secondReceiveLabel: UILabel!

    public static func hideHeight() -> CGFloat {
        return 63
    }
    
    public static func mainHeight() -> CGFloat {
        return 200
    }
    
    public static func singleHeight() -> CGFloat {
        return 135
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        selectionStyle = .none

        secondSendLabel.textColor = Settings.sharedManager().isDarkMode ? UIColor.main.steel : UIColor.main.blueyGrey
        secondReceiveLabel.textColor = Settings.sharedManager().isDarkMode ? UIColor.main.steel : UIColor.main.blueyGrey
        secondSendLabel.font = RegularFont(size: 14)
        secondReceiveLabel.font = RegularFont(size: 14)
        
        mainButton.setBackgroundImage(UIImage.fromColor(color: UIColor.black.withAlphaComponent(0.3)), for: .highlighted)

        mainView.backgroundColor = UIColor.white.withAlphaComponent(0.05)
        
        titleLabel.text = Localizable.shared.strings.in_progress.uppercased()
        titleLabel.letterSpacing = 1.5
        
        arrowIcon.image = IconDownArrow()
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
            receivingLabel.text = "+ " + String.currency(value: status.realReceiving) + " BEAM"
            sentLabel.text = "- " + String.currency(value: status.realSending) + " BEAM"
            
            let secondReceive = AppModel.sharedManager().exchangeValue(status.realReceiving)
            let secondSent = AppModel.sharedManager().exchangeValue(status.realSending)

            secondReceiveLabel.text = "+ " + secondReceive
            secondSendLabel.text = "- " + secondSent
            
            if secondReceive.isEmpty == true {
                secondReceiveLabel.isHidden = true
            }
            else {
                secondReceiveLabel.isHidden = false
            }
            
            if secondSent.isEmpty == true {
                secondSendLabel.isHidden = true
            }
            else {
                secondSendLabel.isHidden = false
            }

            sentStack.isHidden = status.realSending == 0 ? true : false
            receivingStack.isHidden = status.realReceiving == 0 ? true : false
        }
        else{
            sentLabel.text = Localizable.shared.strings.zero
            receivingLabel.text = Localizable.shared.strings.zero
        }
        
        if !options.expand {
            mainStackView.alpha = 0
            arrowIcon.transform = CGAffineTransform(rotationAngle: CGFloat(-90 * Double.pi/180))
        }
        else{
            mainStackView.alpha = 1
            arrowIcon.transform = CGAffineTransform(rotationAngle: CGFloat(0 * Double.pi/180))
        }
        
        arrowIcon.alpha = Settings.sharedManager().isHideAmounts ? 0 : 1
        mainView.alpha =  Settings.sharedManager().isHideAmounts ? 0.7 : 1
        mainView.isUserInteractionEnabled =  Settings.sharedManager().isHideAmounts ? false : true
    }
}
