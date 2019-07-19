//
// BMFieldCell.swift
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

class BMFieldCell: BaseCell {

    weak var delegate: BMCellProtocol?

    @IBOutlet public var topOffset: NSLayoutConstraint?

    @IBOutlet weak private var textField: BMField!
    @IBOutlet weak private var nameLabel: UILabel!
    @IBOutlet weak private var infoLabel: UILabel!
    @IBOutlet weak private var mainStack: UIStackView!

    public var copyText: String?

    override func awakeFromNib() {
        super.awakeFromNib()
        
        selectionStyle = .none
        
        nameLabel.isUserInteractionEnabled = true
        nameLabel.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(onTap(_:))))
        
        mainStack.isUserInteractionEnabled = true
        mainStack.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(onTap(_:))))
        
    }
    
    @objc private func onTap(_ sender: UITapGestureRecognizer) {
        _ = textField.becomeFirstResponder()
    }
    
    public func beginEditing(text:String?){
        copyText = text
        _ = textField.becomeFirstResponder()
    }
    
    public var error:String?
    {
        didSet{
            if error == nil {
                textField.status = .normal
            }
            else{
                textField.error = error
                textField.status = .error
            }
        }
    }
    
    public var info:String?
    {
        didSet{
            if info == nil {
                infoLabel.isHidden = true
            }
            else{
                infoLabel.isHidden = false
                infoLabel.text = info
            }
        }
    }
    
    @objc private func onRightButton() {
        delegate?.onRightButton?(self)
    }
    
    public var isSecure:Bool? {
        didSet {
            if isSecure != nil {
                textField.isSecureTextEntry = isSecure!
            }
        }
    }
}

extension BMFieldCell : UITextFieldDelegate {

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        
        return true
    }
    
    func textFieldShouldBeginEditing(_ textField: UITextField) -> Bool {
        textField.inputAccessoryView = nil
        
        if let copy = copyText {
            let inputBar = BMInputCopyBar(frame: CGRect(x: 0, y: 0, width: UIScreen.main.bounds.size.width, height: 44), copy:copy)
            
            inputBar.completion = {
                (obj : String?) -> Void in
                if let text = obj {
                    self.textField.text = text
                    self.delegate?.textValueDidChange?(self, text, false)
                    _ = self.textField.resignFirstResponder()
                }
            }
            textField.inputAccessoryView = inputBar
        }
        return true
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        self.delegate?.textValueDidReturn?(self)
        
        if nameLabel.text == Localizable.shared.strings.transaction_comment {
            textField.placeholder = String.empty()
            textField.placeHolderColor = UIColor.white.withAlphaComponent(0.2)
        }
    }
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        self.delegate?.textValueDidBegin?(self)
        
        if nameLabel.text == Localizable.shared.strings.transaction_comment {
            textField.placeholder = Localizable.shared.strings.not_shared.capitalizingFirstLetter()
            textField.placeHolderColor = UIColor.white.withAlphaComponent(0.2)
        }
    }
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        
        let textFieldText: NSString = (textField.text ?? String.empty()) as NSString
        let txtAfterUpdate = textFieldText.replacingCharacters(in: range, with: string)
        
        self.textField.status = .normal
        self.delegate?.textValueDidChange?(self, txtAfterUpdate, true)
        
        return true
    }
    
    func textFieldShouldClear(_ textField: UITextField) -> Bool {
        self.textField.status = .normal
        self.delegate?.textValueDidChange?(self, String.empty(), true)
        
        return true
    }
}

extension BMFieldCell: Configurable {
    
    func configure(with options: (name: String, value:String)) {
        textField.text = options.value
        nameLabel.text = options.name
        nameLabel.letterSpacing = 2
        
        if options.name == Localizable.shared.strings.name.uppercased() {
            textField.placeholder = Localizable.shared.strings.no_name
            textField.placeHolderColor = UIColor.white
        }
        else{
            textField.placeholder = String.empty()
        }
    }
}
