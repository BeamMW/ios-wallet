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
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        selectionStyle = .none
      
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
}

extension ReceiveTokenCell: Configurable {
    
    func configure(with value: String) {
        detailLabel.text = value
    }

}
