//
//  ReceiveTokenCell.swift
//  BeamWallet
//
//  Created by Denis on 04.11.2020.
//  Copyright © 2020 Denis. All rights reserved.
//

import UIKit

@objc protocol ReceiveAddressTokensCellDelegate: AnyObject {
    @objc optional func onShowToken(token:String)
    @objc optional func onShowQR(token:String)
    @objc optional func onShareToken(token:String)
}

class ReceiveTokenCell: BaseCell {

    weak var delegate: ReceiveAddressTokensCellDelegate?

    @IBOutlet private var nameLabel: UILabel!
    @IBOutlet private var detailLabel: UILabel!
    @IBOutlet private var infoLabel: UILabel!
    @IBOutlet private var topConstraint: NSLayoutConstraint!
    @IBOutlet private var botConstraint: NSLayoutConstraint!
    @IBOutlet private var qrButton: UIButton!

    override func awakeFromNib() {
        super.awakeFromNib()
        
        selectionStyle = .none
        
        if Settings.sharedManager().isDarkMode {
            nameLabel.textColor = UIColor.main.steel;
        }
        
        infoLabel.textColor = nameLabel.textColor
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
    
    @IBAction func onShowToken(sender: UIButton) {
        if let token = detailLabel.text {
            self.delegate?.onShowToken?(token: token)
        }
    }
    
    @IBAction func onCopyToken(sender: UIButton) {
        if let token = detailLabel.text {
            self.delegate?.onShareToken?(token: token)
        }
    }
    
    @IBAction func onQRToken(sender: UIButton) {
        if let token = detailLabel.text {
            self.delegate?.onShowQR?(token: token)
        }
    }
}

extension ReceiveTokenCell: Configurable {
    
    func configure(with options: (title: String, value: String, index: Int, info: String)) {
        nameLabel.text = options.title
        detailLabel.text = options.value
        topConstraint.constant = options.index == 0 ? 25 : 15
        
        let split = options.title.split(separator: "(")
        nameLabel.setLetterSpacingOnly(value: 1.5, title: options.title, letter: String(split[0]))
        
        if options.info.isEmpty {
            botConstraint.constant = 15
            infoLabel.isHidden = true
            qrButton.isHidden = false
        }
        else {
            botConstraint.constant = 30
            infoLabel.isHidden = false
            qrButton.isHidden = true
            infoLabel.text = options.info
        }
    }

}
