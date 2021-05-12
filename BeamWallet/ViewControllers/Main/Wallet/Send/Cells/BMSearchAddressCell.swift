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
    
    @IBOutlet private weak var textField: BMTextView!
    @IBOutlet private weak var nameLabel: UILabel!
    @IBOutlet private weak var errorLabel: UILabel!
    @IBOutlet private weak var showTokenButton: UIButton!
    @IBOutlet private weak var additionalErrorLabel: UILabel!
    @IBOutlet private weak var addressTypeLabel: UILabel!

    @IBOutlet private weak var contactView: UIStackView!
    @IBOutlet private weak var contactName: UILabel!
    @IBOutlet private weak var contactCategory: UILabel!
    @IBOutlet private weak var iconView: UIView!
    @IBOutlet private weak var buttonsStackView: UIStackView!
    @IBOutlet private weak var qrButton: UIButton!

   // private var rightButtons = [UIButton]()
    
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
        
        nameLabel.isUserInteractionEnabled = true
        nameLabel.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(onTap(_:))))
        
        textField.alwaysVisibleClearButton = true
        textField.placholderFont = ItalicFont(size: 16)
        textField.placholderColor = UIColor.white.withAlphaComponent(0.2)
        textField.placeholder = Localizable.shared.strings.send_address_placholder
        textField.allowsEditingTextAttributes = true
        textField.defaultOffset = 4
        textField.lineColor = UIColor.white.withAlphaComponent(0.1)
        
        if Settings.sharedManager().isDarkMode {
            nameLabel.textColor = UIColor.main.steel;
            addressTypeLabel.textColor = UIColor.main.steel;
            additionalErrorLabel.textColor = UIColor.main.steel;
        }
        
        contentView.backgroundColor = UIColor.main.marineThree
    }
    
    @objc private func onTap(_ sender: UITapGestureRecognizer) {
        _ = textField.becomeFirstResponder()
    }
    
    public func beginEditing(text: String?) {
        copyText = text
        _ = textField.becomeFirstResponder()
    }
    
    
    public var addressType: BMAddressType = BMAddressType(BMAddressTypeRegular) {
        didSet {
            if(!textField.text.isEmpty && addressType != BMAddressTypeUnknown) {
                let title = AppModel.sharedManager().getAddressTypeString(addressType)
                addressTypeLabel.isHidden = false
                addressTypeLabel.text = "\(title)."
                addressTypeLabel.font = ItalicFont(size: 14)
            }
            else {
                addressTypeLabel.isHidden = true
            }
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
                textField.lineColor = UIColor.main.red
                textField.textColor = UIColor.main.red
                errorLabel.textColor = UIColor.main.red
                errorLabel.text = error
                errorLabel.isHidden = false
            }
            else {
                textField.lineColor = UIColor.white.withAlphaComponent(0.1)
                textField.textColor = UIColor.white
                errorLabel.text = nil
                errorLabel.textColor = UIColor.main.red
                errorLabel.isHidden = true
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
                
//                for btn in rightButtons {
//                    btn.isHidden = true
//                }
            }
            else {
                textField.text = string
            }
        }
        else {
//            for btn in rightButtons {
//                btn.isHidden = false
//            }
//
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

extension BMSearchAddressCell: UITextViewDelegate {
    func textViewShouldBeginEditing(_ textView: UITextView) -> Bool {
        textView.inputAccessoryView = nil
        
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
            textView.inputAccessoryView = inputBar
            textView.layoutIfNeeded()
            textView.layoutSubviews()
        }
        
        return true
    }
    
    func textViewDidEndEditing(_ textView: UITextView) {
        buttonsStackView.isHidden = false
        delegate?.textValueDidReturn?(self)
    }
    
    func textViewDidBeginEditing(_ textView: UITextView) {
        delegate?.textValueDidBegin?(self)
        showTokenButton.isHidden = true
        buttonsStackView.isHidden = true
    }
    
    func textViewDidChange(_ textView: UITextView) {
        showTokenButton.isHidden = true
        delegate?.textValueDidChange?(self, textView.text ?? String.empty(), true)
    }
    
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        if text == Localizable.shared.strings.new_line {
            textView.resignFirstResponder()
            return false
        }
        else if text == UIPasteboard.general.string {
            delegate?.textValueDidChange?(self, text, false)
            _ = textField.resignFirstResponder()
            checkAttributes(string: text)
            return false
        }
        else if validateAddress {
          let alphaNumericSet = CharacterSet(charactersIn: "abcdefABCDEF0123456789")
            if text.rangeOfCharacter(from: alphaNumericSet.inverted) != nil {
                return false
            }
        }
        
        error = nil
        
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
        
//        for button in rightButtons {
//            buttonsStackView.removeArrangedSubview(button)
//        }
//        rightButtons.removeAll()
//
//
//        if let icons = options.rightIcons {
//            for icon in icons {
//                let button = UIButton(frame: CGRect(x: 0, y: 0, width: 36, height: 36))
//                button.setImage(icon, for: .normal)
//                button.tag = buttonsStackView.arrangedSubviews.count
//                button.addTarget(self, action: #selector(onRightButton(sender:)), for: .touchUpInside)
//                button.heightAnchor.constraint(equalToConstant: 36).isActive = true
//                button.widthAnchor.constraint(equalToConstant: 36).isActive = true
//                buttonsStackView.insertArrangedSubview(button, at: 1)
//                rightButtons.append(button)
//            }
//        }
     //   buttonsStackView.setNeedsLayout()
        checkAttributes(string: options.value)
    }
}
