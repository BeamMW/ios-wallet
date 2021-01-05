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
    @objc optional func onCopyToken(token: String)
}

class ReceiveTokenCell: BaseCell {

    weak var delegate: ReceiveAddressTokensCellDelegate?

    @IBOutlet private var nameLabel: UILabel!
    @IBOutlet private var detailLabel: UILabel!
    @IBOutlet private var infoLabel: UILabel!
    @IBOutlet private var topConstraint: NSLayoutConstraint!
    @IBOutlet private var botConstraint: NSLayoutConstraint!
    @IBOutlet private var topConstraintView: NSLayoutConstraint!
    @IBOutlet private var botConstraintView: NSLayoutConstraint!

    
    @IBOutlet private var qrButton: UIButton!
    @IBOutlet private var view_1: UIView!

    override func awakeFromNib() {
        super.awakeFromNib()
        
        selectionStyle = .none
        
        view_1.backgroundColor = UIColor.main.marineThree

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
            self.delegate?.onCopyToken?(token: token)
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
     //   topConstraint.constant = options.index == 0 ? 0 : 15
        
        if !options.title.isEmpty {
            view_1.backgroundColor = UIColor.main.marineThree
            self.contentView.backgroundColor = UIColor.clear

            let split = options.title.split(separator: "(")
            nameLabel.setLetterSpacingOnly(value: 1.5, title: options.title, letter: String(split[0]))
        }
        else {
            view_1.backgroundColor = UIColor.clear
            self.contentView.backgroundColor = UIColor.main.marineThree

            botConstraint.constant = 15
            topConstraint.constant = -10
        }
 
        if options.info.isEmpty {
          //  botConstraint.constant = 15
            infoLabel.isHidden = true
            qrButton.isHidden = false
        }
        else {
            botConstraint.constant = 45
            infoLabel.isHidden = false
            qrButton.isHidden = true
            infoLabel.text = options.info
        }
        
        if options.index == 1 {
            topConstraintView.constant = 20
            topConstraint.constant = 35
        }
        else if options.index == 2 {
            topConstraintView.constant = 5
            topConstraint.constant = 15
        }
        
        if options.title == Localizable.shared.strings.max_privacy_address.uppercased() {
            topConstraintView.constant = 20
            topConstraint.constant = 35
            
            botConstraintView.constant = 20
            botConstraint.constant = 35
        }
    }

}
