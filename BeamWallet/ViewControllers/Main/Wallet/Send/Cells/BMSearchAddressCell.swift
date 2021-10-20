//
// BMSearchAddressCell.swift
// BeamWallet
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

class BMSearchAddressCell: BaseCell {
    weak var delegate: BMCellProtocol?
    
    @IBOutlet private weak var textField: BMField!
    @IBOutlet private weak var nameLabel: UILabel!
    @IBOutlet private weak var showTokenButton: UIButton!
    @IBOutlet private weak var additionalErrorLabel: UILabel!
    @IBOutlet private weak var addressTypeLabel: UILabel!

    @IBOutlet private weak var contactView: UIStackView!
    @IBOutlet private weak var contactName: UILabel!
    @IBOutlet private weak var contactCategory: UILabel!
    @IBOutlet private weak var iconView: UIView!
    @IBOutlet private weak var qrButton: UIButton!
    
    @IBOutlet var nameLabelTopOffset: NSLayoutConstraint!
    @IBOutlet var stackBotOffset: NSLayoutConstraint!

    private var token = ""
    
    public var validateAddress = false
    
    public var copyText: String?
    public var titleColor: UIColor? {
        didSet {
            if let color = titleColor {
                nameLabel.textColor = color
            }
        }
    }
    
    public var placeholder: String? {
        didSet {
            if let placeholder = placeholder {
                textField.placeholder = placeholder
            }
        }
    }

    override func awakeFromNib() {
        super.awakeFromNib()
        
        selectionStyle = .none
        allowHighlighted = false

        showTokenButton.frame = CGRect(x: 200, y: 0, width: 110, height: 45)
        textField.addSubview(showTokenButton)
        
        nameLabel.isUserInteractionEnabled = true
        nameLabel.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(onTap(_:))))
        
        if Settings.sharedManager().isDarkMode {
            nameLabel.textColor = UIColor.main.steel;
            addressTypeLabel.textColor = UIColor.main.steel;
            additionalErrorLabel.textColor = UIColor.main.steel;
        }
        
        NotificationCenter.default.addObserver(forName: UITextField.textDidChangeNotification, object: textField, queue: nil) { [weak self] notification in
            guard let strongSelf = self else { return }
            
            strongSelf.showTokenButton.isHidden = true
            strongSelf.delegate?.textValueDidChange?(strongSelf, strongSelf.textField.text ?? String.empty(), true)
        }
        
        contentView.backgroundColor = UIColor.main.marineThree
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        showTokenButton.frame = CGRect(x: self.frame.size.width - 195, y: 0, width: 110, height: 45)
    }
    
    @objc private func onTap(_ sender: UITapGestureRecognizer) {
        _ = textField.becomeFirstResponder()
    }
    
    public func beginEditing(text: String?) {
        copyText = text
        _ = textField.becomeFirstResponder()
    }
    
    
    public var addressType: BMAddressType = BMAddressType(BMAddressTypeRegular) 
    
    public func setAddressType(_ type:BMAddressType, _ offline:Bool, _ left:Int) {
        addressType = type
        
        let text = textField.text ?? ""
        if(!text.isEmpty && type != BMAddressTypeUnknown) {
            let title = AppModel.sharedManager().getAddressTypeString(type)
            addressTypeLabel.isHidden = false
            if offline && type == BMAddressTypeShielded {
                if left <= 3 {
                    addressTypeLabel.text = String(format: Localizable.shared.strings.offline_left_address_warning, left)
                }
                else {
                    addressTypeLabel.text = String(format: Localizable.shared.strings.offline_left_address, left)
                }
            }
            else if type == BMAddressTypeShielded {
                addressTypeLabel.text = Localizable.shared.strings.online_address + "."
            }
            else if type == BMAddressTypeMaxPrivacy {
                addressTypeLabel.text = Localizable.shared.strings.send_max_privacy_title
            }
            else if type == BMAddressTypeRegular {
                addressTypeLabel.text = Localizable.shared.strings.online_address + "."
            }
            else {
                addressTypeLabel.text = "\(title)."
            }
            addressTypeLabel.font = ItalicFont(size: 14)
        }
        else {
            addressTypeLabel.isHidden = true
        }
    }
    
    public var contact: BMContact? {
        didSet {
            if contact == nil {
                contactView.isHidden = true
            }
            else {
                contactName.numberOfLines = 1
                contactView.isHidden = false
                contactName.font = ProMediumFont(size: 14)
                contactName.text = contact?.address.label
                iconView.isHidden = false

                if contactName.text?.isEmpty ?? true {
                    contactName.text = Localizable.shared.strings.no_name
                }
                contactCategory.text = nil
            }
        }
    }
    
    public var error: String? {
        didSet {
            if error != nil {
                stackBotOffset.constant = 10
                textField.error = error
                textField.status = .error
            }
            else {
                textField.error = nil
                textField.status = .normal
            }
        }
    }
    
    public var additionalError: String? {
        didSet {
            if additionalError != nil {
                additionalErrorLabel.text = additionalError
                additionalErrorLabel.isHidden = false
            }
            else {
                additionalErrorLabel.isHidden = true
            }
        }
    }
    
    private func checkAttributes(string: String?) {
        showTokenButton.isHidden = true
        if let text = string {
            token = text
            if AppModel.sharedManager().isValidAddress(text) {
                textField.text = "\(text.prefix(6))...\(text.suffix(6))"
                showTokenButton.isHidden = false
            }
            else {
                textField.text = string
            }
        }
        else {
            token = ""
            textField.text = string
        }
    }
    
    @IBAction func onRightButton(sender: UIButton) {
        if sender.tag == 1 {
            _ = self.textField.becomeFirstResponder()
        }
        else {
            delegate?.onRightButton?(self)
        }
    }
    
    @IBAction func onShowToken(sender: UIButton) {
        if let top = UIApplication.getTopMostViewController() {
            let vc = ShowTokenViewController(token: token, send: true)
            top.pushViewController(vc: vc)
        }
    }
}

extension BMSearchAddressCell: UITextFieldDelegate {
    
    func textFieldShouldBeginEditing(_ textField: UITextField) -> Bool {
        textField.inputAccessoryView = nil
        
        if let copy = copyText {
            let inputBar = BMInputCopyBar(frame: CGRect(x: 0, y: 0, width: UIScreen.main.bounds.size.width, height: 44), copy: copy)
            
            inputBar.completion = {
                (obj: String?) -> Void in
                if let text = obj {
                    self.delegate?.textValueDidChange?(self, text, false)
                    _ = self.textField.resignFirstResponder()
                    self.checkAttributes(string: text)
                }
            }
            textField.inputAccessoryView = inputBar
            textField.layoutIfNeeded()
            textField.layoutSubviews()
        }
        
        return true
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        qrButton.isHidden = false
        delegate?.textValueDidReturn?(self)
    }
    

    func textFieldDidBeginEditing(_ textField: UITextField) {
        delegate?.textValueDidBegin?(self)
        showTokenButton.isHidden = true
        qrButton.isHidden = true
    }

    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        if string == Localizable.shared.strings.new_line {
            textField.resignFirstResponder()
            return false
        }
        else if string == UIPasteboard.general.string {
            delegate?.textValueDidChange?(self, string, false)
            _ = textField.resignFirstResponder()
            checkAttributes(string: string)
            return false
        }
        else if validateAddress {
            let alphaNumericSet = CharacterSet(charactersIn: "abcdefABCDEF0123456789")
            if string.rangeOfCharacter(from: alphaNumericSet.inverted) != nil {
                return false
            }
        }
                
        return true
    }
}

extension BMSearchAddressCell: Configurable {
    
    func setData(with options: (name: String, value: String)) {
        nameLabel.text = options.name
        nameLabel.letterSpacing = 2
        checkAttributes(string: options.value)
    }
    
    func configure(with options: (name: String, value: String, rightIcons: [UIImage?]?)) {
        nameLabel.text = options.name
        nameLabel.letterSpacing = 2
        
        if options.rightIcons == nil {
            qrButton.isHidden = true
        }
        else {
            qrButton.isHidden = false
        }
        
        checkAttributes(string: options.value)
    }
}
