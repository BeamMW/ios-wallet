//
//  UTXOBlockCell.swift
//  BeamWallet
//
//  Created by Denis on 3/19/19.
//  Copyright © 2019 Denis. All rights reserved.
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
