//
//  SendContactAddressCell.swift
//  BeamWallet
//
//  Created by Denis on 13.04.2021.
//  Copyright © 2021 Denis. All rights reserved.
//

import UIKit

class SendContactAddressCell: BaseCell {
    @IBOutlet private weak var nameLabel: UILabel!
    @IBOutlet private weak var contactNameLabel: UILabel!
    @IBOutlet private weak var addressLabel: UILabel!
    @IBOutlet private weak var typeLabel: UILabel!

    private var contact: BMContact? = nil
    
    weak var delegate: BMCellProtocol?

    override func awakeFromNib() {
        super.awakeFromNib()

        nameLabel.text = Localizable.shared.strings.send_to.uppercased()
        nameLabel.letterSpacing = 1.5

        if Settings.sharedManager().isDarkMode {
            addressLabel.textColor = UIColor.main.steel;
            typeLabel.textColor = UIColor.main.steel;
        }
        
        contentView.backgroundColor = UIColor.main.marineThree

        selectionStyle = .none
    }
    
    @IBAction private func onClear(sender: UIButton) {
        delegate?.onRightButton?(self)
    }

    @IBAction private func onShowToken(sender: UIButton) {
        if let top = UIApplication.getTopMostViewController() {
            let vc = ShowTokenViewController(token: self.contact?.address.walletId ?? "", send: true)
            top.pushViewController(vc: vc)
        }
    }
    
    func configure(with options: (contact: BMContact?, addressType: BMAddressType)) {
        self.contact = options.contact
        
        if let name = contact?.name, !name.isEmpty {
            contactNameLabel.text = name
        }
        else {
            contactNameLabel.text = Localizable.shared.strings.no_name
        }
        
        if let address = contact?.address.walletId {
            addressLabel.text = "\(address.prefix(6))...\(address.suffix(6))"
        }
        else {
            addressLabel.text = ""
        }
        
        typeLabel.text =  AppModel.sharedManager().getAddressTypeString(options.addressType)
    }
}
