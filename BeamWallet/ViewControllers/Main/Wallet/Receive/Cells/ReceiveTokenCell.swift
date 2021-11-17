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
    @IBOutlet private var detailLabel: BMCopyLabel!
    @IBOutlet private var detailButton: UIButton!
    @IBOutlet private var hintLabel: UILabel!
    @IBOutlet private var hintLabelTopOffset: NSLayoutConstraint!

    override func awakeFromNib() {
        super.awakeFromNib()
        
        if Settings.sharedManager().isDarkMode {
            hintLabel.textColor = UIColor.main.steel;
        }
        else {
            hintLabel.textColor = UIColor.main.blueyGrey
        }
        
        selectionStyle = .none
        allowHighlighted = false

        detailButton.setTitle(Localizable.shared.strings.address_details.lowercased(), for: .normal)
        
        nameLabel.text = Localizable.shared.strings.address.uppercased()
        nameLabel.letterSpacing = 2
        
        detailLabel.copiedText = Localizable.shared.strings.address_copied
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
    
    func configure(with value: String, title:String, showHint:Bool) {
        detailLabel.text = value
        nameLabel.text = title
        nameLabel.letterSpacing = 2
        hintLabel.isHidden = !showHint
        hintLabel.text = showHint ? Localizable.shared.strings.receive_address_hint : nil
        hintLabelTopOffset.constant = showHint ? 10 : 0
    }
}
