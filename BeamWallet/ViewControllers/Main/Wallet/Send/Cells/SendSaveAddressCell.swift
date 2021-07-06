//
//  SendContactAddressCell.swift
//  BeamWallet
//
//  Created by Denis on 13.04.2021.
//  Copyright © 2021 Denis. All rights reserved.
//

import UIKit

class SendSaveAddressCell: BaseCell, UITextFieldDelegate {
    @IBOutlet private weak var nameLabel: UILabel!
    @IBOutlet private weak var addressLabel: UILabel!
    @IBOutlet private weak var typeLabel: UILabel!
    @IBOutlet private weak var textField: BMField!

    private var token: String? = nil
    
    weak var delegate: BMCellProtocol?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        allowHighlighted = false

        nameLabel.text = Localizable.shared.strings.send_to.uppercased()
        nameLabel.letterSpacing = 1.5
        
        textField.placeholder = Localizable.shared.strings.enter_name_save
        textField.placeHolderFont = ItalicFont(size: 16)

        if Settings.sharedManager().isDarkMode {
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
            let vc = ShowTokenViewController(token: self.token ?? "", send: true)
            top.pushViewController(vc: vc)
        }
    }
    
    func configure(with options: (token: String, addressType: BMAddressType, name: String)) {
        addressLabel.text = "\(options.token.prefix(6))...\(options.token.suffix(6))"
        typeLabel.text =  AppModel.sharedManager().getAddressTypeString(options.addressType)
        textField.text = options.name
        token = options.token
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        
        let textFieldText: NSString = (textField.text ?? String.empty()) as NSString
        let txtAfterUpdate = textFieldText.replacingCharacters(in: range, with: string)
        
        self.delegate?.textValueDidChange?(self, txtAfterUpdate, true)
        
        return true
    }
    
    func textFieldShouldClear(_ textField: UITextField) -> Bool {
        self.delegate?.textValueDidChange?(self, String.empty(), true)
        
        return true
    }
}
