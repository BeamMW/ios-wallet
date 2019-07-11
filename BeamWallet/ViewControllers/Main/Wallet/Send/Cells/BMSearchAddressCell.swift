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
    
    @IBOutlet weak private var textField: BMTextView!
    @IBOutlet weak private var nameLabel: UILabel!
    @IBOutlet weak private var errorLabel: UILabel!
    @IBOutlet weak private var rightButton: UIButton!

    @IBOutlet weak private var contactView: UIView!
    @IBOutlet weak private var contactName: UILabel!
    @IBOutlet weak private var contactCategory: UILabel!


    public var copyText: String?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        selectionStyle = .none
        
        nameLabel.isUserInteractionEnabled = true
        nameLabel.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(onTap(_:))))
        
        textField.placholderFont = ItalicFont(size: 16)
        textField.placholderColor = UIColor.white.withAlphaComponent(0.2)
        textField.allowsEditingTextAttributes = true
        textField.defaultOffset = 4
        textField.lineColor = Settings.sharedManager().target == Testnet ? UIColor.main.marineThree : UIColor.main.darkSlateBlue
        
        contentView.backgroundColor = UIColor.main.marineThree
    }
    
    @objc private func onTap(_ sender: UITapGestureRecognizer) {
        textField.becomeFirstResponder()
    }
    
    public func beginEditing(text:String?){
        copyText = text
        textField.becomeFirstResponder()
    }
    
    public var contact:BMContact? {
        didSet {
            if contact == nil {
                contactView.isHidden = true
            }
            else {
                contactView.isHidden = false
                contactName.text = contact?.address.label
                
                if contactName.text?.isEmpty ?? true {
                    contactName.text = Localizable.shared.strings.no_name
                }
                
                if contact?.address.categories.count ?? 0 > 0 {
                    contactCategory.attributedText = contact?.address.categoriesName()
                }
                else{
                    contactCategory.text = nil
                }
            }
        }
    }
    
    public var error:String?
    {
        didSet {
            if error != nil {
                textField.lineColor = UIColor.main.red
                textField.textColor = UIColor.main.red
                errorLabel.textColor = UIColor.main.red
                errorLabel.text = error
                errorLabel.isHidden = false
            }
            else{
                textField.lineColor = Settings.sharedManager().target == Testnet ? UIColor.main.marineThree : UIColor.main.darkSlateBlue
                textField.textColor = UIColor.white
                errorLabel.text = nil
                errorLabel.textColor = UIColor.main.red
                errorLabel.isHidden = true
            }
        }
    }
    
    private func checkAttributes(string:String?) {
        if let text = string {
            if AppModel.sharedManager().isValidAddress(text)
            {
                let length = text.lengthOfBytes(using: .utf8)
                if (length > 12)
                {
                    let att = NSMutableAttributedString(string: text, attributes: [NSAttributedString.Key.font : RegularFont(size: 16), NSAttributedString.Key.foregroundColor : UIColor.white])
                    att.addAttribute(NSAttributedString.Key.foregroundColor, value: UIColor.main.heliotrope, range: NSRange(location: 0, length: 6))
                    att.addAttribute(NSAttributedString.Key.foregroundColor, value: UIColor.main.heliotrope, range: NSRange(location: length-6, length: 6))

                    self.textField.attributedText = att
                }
                else{
                    self.textField.text = string
                }
            }
            else{
                self.textField.text = string
            }
        }
        else{
            self.textField.text = string
        }
    }
    
    @IBAction func onRightButton(sender :UIButton) {
        delegate?.onRightButton?(self)
    }
}

extension BMSearchAddressCell : UITextViewDelegate {
    
    func textViewShouldBeginEditing(_ textView: UITextView) -> Bool {
        textView.inputAccessoryView = nil
        
        if let copy = copyText {
            let inputBar = BMInputCopyBar(frame: CGRect(x: 0, y: 0, width: UIScreen.main.bounds.size.width, height: 44), copy:copy)
            
            inputBar.completion = {
                (obj : String?) -> Void in
                if let text = obj {
                    self.delegate?.textValueDidChange?(self, text, false)
                    self.textField.resignFirstResponder()
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
        self.delegate?.textValueDidReturn?(self)
        
        if nameLabel.text == Localizable.shared.strings.send_to {
            textField.placeholder = String.empty()
        }
    }
    
    func textViewDidBeginEditing(_ textView: UITextView) {
        self.delegate?.textValueDidBegin?(self)
        
        if nameLabel.text == Localizable.shared.strings.send_to {
            textField.placeholder = Localizable.shared.strings.address_search
        }
    }
    
    func textViewDidChange(_ textView: UITextView) {
        self.delegate?.textValueDidChange?(self, textView.text ?? String.empty(), true)
    }
    
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        
        if text == Localizable.shared.strings.new_line {
            textView.resignFirstResponder()
            return false
        }
        else if text == UIPasteboard.general.string {
            self.delegate?.textValueDidChange?(self, text, false)
            self.textField.resignFirstResponder()
            self.checkAttributes(string: text)
            return false
        }
        
        error = nil
        
        return true
    }
}

extension BMSearchAddressCell: Configurable {
    
    func configure(with options: (name: String, value:String, rightIcon:UIImage? )) {
        nameLabel.text = options.name
        nameLabel.letterSpacing = 2
        
        if let icon = options.rightIcon {
            rightButton.setImage(icon, for: .normal)
        }
        
        checkAttributes(string: options.value)
    }
}
