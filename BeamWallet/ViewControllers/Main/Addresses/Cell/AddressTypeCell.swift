//
//  AddressTypeCell.swift
//  BeamWallet
//
//  Created by Denis on 27.07.2020.
//  Copyright © 2020 Denis. All rights reserved.
//

import UIKit

protocol AddressTypeCellDelegate: AnyObject {
    func onAddressType(permanent:Bool)
}


class AddressTypeCell: BaseCell {

    @IBOutlet weak private var titleLabel: UILabel!
    @IBOutlet weak private var detailLabel: UILabel!
    @IBOutlet weak private var descriptionLabel: UILabel!
    @IBOutlet weak private var switchView: UISwitch!

    weak var delegate: AddressTypeCellDelegate?

    override func awakeFromNib() {
        super.awakeFromNib()

        selectionStyle = .none

        descriptionLabel.textColor = UIColor.main.blueyGrey

        titleLabel.text = Localizable.shared.strings.type.uppercased()
        detailLabel.text = Localizable.shared.strings.perm_out_address_title
        descriptionLabel.text = Localizable.shared.strings.perm_out_address_text

        switchView.onTintColor = UIColor.main.brightTeal
        switchView.tintColor = (Settings.sharedManager().target == Testnet || Settings.sharedManager().isDarkMode) ? UIColor(hexString: "#0F0D17") : UIColor.main.marine
    }
    
    public func setIsPermanent(_ value:Bool) {
        switchView.isOn = value
    }
    
    @IBAction func onSwitch(sender: UISwitch) {
        delegate?.onAddressType(permanent: sender.isOn)
    }
}
