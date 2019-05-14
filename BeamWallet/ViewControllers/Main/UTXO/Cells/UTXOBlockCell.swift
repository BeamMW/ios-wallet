//
//  UTXOBlockCell.swift
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

protocol UTXOBlockCellDelegate: AnyObject {
    func onClickExpand()
}


class UTXOBlockCell: BaseCell {

    weak var delegate: UTXOBlockCellDelegate?

    @IBOutlet weak private var heightLabel: UILabel!
    @IBOutlet weak private var hashLabel: UILabel!
    @IBOutlet weak private var hashTitleLabel: UILabel!
    @IBOutlet weak private var arrowIcon: UIImageView!

    public static func hideHeight() -> CGFloat {
        return 70
    }
    
    public static func mainHeight() -> CGFloat {
        return 123
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        self.selectionStyle = .none
    }
    
    @IBAction func onExpand(sender :UIButton) {
        if hashLabel.alpha == 1 {
            UIView.animate(withDuration: 0.3) {
                self.hashLabel.alpha = 0
                self.hashTitleLabel.alpha = 0
                self.arrowIcon.transform = CGAffineTransform(rotationAngle: CGFloat(-90 * Double.pi/180))
            }
        }
        else{
            UIView.animate(withDuration: 0.3) {
                self.hashLabel.alpha = 1
                self.hashTitleLabel.alpha = 1
                self.arrowIcon.transform = CGAffineTransform(rotationAngle: CGFloat(0 * Double.pi/180))
            }
        }
        
        self.delegate?.onClickExpand()
    }
}

extension UTXOBlockCell: Configurable {
    
    func configure(with options: (status:BMWalletStatus? , expand:Bool)) {
                
        if let walletStatus = options.status {
            heightLabel.text = walletStatus.currentHeight
            hashLabel.text = walletStatus.currentStateHash
        }
        else{
            heightLabel.text = ""
            hashLabel.text = ""
        }
        
        if options.expand {
            hashLabel.alpha = 1
            hashTitleLabel.alpha = 1
            arrowIcon.transform = CGAffineTransform(rotationAngle: CGFloat(0 * Double.pi/180))
        }
        else{
            hashLabel.alpha = 0
            hashTitleLabel.alpha = 0
            arrowIcon.transform = CGAffineTransform(rotationAngle: CGFloat(-90 * Double.pi/180))
        }
    }
}
