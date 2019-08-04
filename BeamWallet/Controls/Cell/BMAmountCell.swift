//
// BMAmountCell.swift
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

class BMAmountCell: BaseCell {
    
    weak var delegate: BMCellProtocol?

    @IBOutlet weak private var textField: BMField!
    @IBOutlet weak private var nameLabel: UILabel!
    @IBOutlet weak private var currencyLabel: UILabel!
    @IBOutlet weak private var erorLabel: UILabel!

    public var fee:Double = 0
    
    public var info:String?
    
    public var normalTextColor = UIColor.main.heliotrope
    public var normalLineColor = UIColor.main.heliotrope

    public var error:String?
    {
        didSet{
            if error == nil {
                erorLabel.text = nil
                erorLabel.isHidden = true
                textField.textColor = normalTextColor
                textField.lineColor = Settings.sharedManager().target == Testnet ? UIColor.main.marineThree : UIColor.main.darkSlateBlue
            }
            else{
                erorLabel.text = error
                erorLabel.isHidden = false
                textField.textColor = UIColor.main.red
                textField.lineColor = UIColor.main.red
            }
        }
    }
    
    public var currency:String?
    {
        didSet{
            if currency != nil {
                
                currencyLabel.isUserInteractionEnabled = true
                
                let text = currency!
                
                let imageAttachment = NSTextAttachment()
                imageAttachment.image = IconNextArrow()
               
                let imageString = NSAttributedString(attachment: imageAttachment)
                
                let attributedString = NSMutableAttributedString(string:text)                
                attributedString.append(NSAttributedString(string: "  "))
                attributedString.append(imageString)
                
                currencyLabel.attributedText = attributedString
                
                textField.placeholder = Localizable.shared.strings.enter_amount_in_currency + " " + currency!
                textField.placeHolderColor = UIColor.main.blueyGrey.withAlphaComponent(0.7)
            }
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        selectionStyle = .none
        
        erorLabel.textColor = UIColor.main.red
        erorLabel.isHidden = true
        erorLabel.text = nil
        
        textField.statusDelegate = self
        
        currencyLabel.isUserInteractionEnabled = false
        currencyLabel.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(onCurrency(_:))))
        
        nameLabel.isUserInteractionEnabled = true
        nameLabel.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(onTap(_:))))
        
        textField.placeHolderColor = UIColor.white.withAlphaComponent(0.2)
    }
    
    @objc private func onTap(_ sender: UITapGestureRecognizer) {
        _ = textField.becomeFirstResponder()
    }
    
    @objc private func onCurrency(_ sender: UITapGestureRecognizer) {
        self.delegate?.onRightButton?(self)
    }
    
    public func beginEditing(){
        _ = textField.becomeFirstResponder()
    }
}

extension BMAmountCell: Configurable {
    
    func configure(with options: (name: String, value:String?)) {
        if options.name == Localizable.shared.strings.amount.uppercased() || options.name == Localizable.shared.strings.you_send.uppercased() {
            textField.textColor = UIColor.main.heliotrope
            textField.setNormalColor(color: UIColor.main.heliotrope)
        }
        
        nameLabel.text = options.name
        nameLabel.letterSpacing = 2
        
        normalLineColor = textField.lineColor ?? UIColor.main.marine
        normalTextColor = textField.textColor ?? UIColor.main.heliotrope

        textField.text = options.value
    }
}

extension BMAmountCell : UITextFieldDelegate {
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        if textField.placeholder == nil || textField.placeholder == Localizable.shared.strings.zero {
            textField.placeholder = String.empty()
            textField.placeHolderColor = UIColor.white.withAlphaComponent(0.2)
        }

        self.delegate?.textValueDidReturn?(self)
    }
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        if textField.placeholder == nil || textField.placeholder == String.empty() {
            textField.placeholder = Localizable.shared.strings.zero
            textField.placeHolderColor = UIColor.white.withAlphaComponent(0.2)
        }
        self.delegate?.textValueDidBegin?(self)
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        
        return true
    }
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        
        let textFieldText: NSString = (textField.text ?? String.empty()) as NSString
        
        let txtAfterUpdate = textFieldText.replacingCharacters(in: range, with: string).replacingOccurrences(of: String.coma(), with: String.dot())
        
        if !txtAfterUpdate.isCorrectAmount(fee: fee) {
            return false
        }
        
        if string == String.coma() {
            textField.text = txtAfterUpdate
            return false
        }
        
        self.error = nil
        
        self.delegate?.textValueDidChange?(self, txtAfterUpdate, true)

        return true
    }
}

extension BMAmountCell : BMFieldStatusProtocol {
    func didChangeStatus() {
      //  self.delegate?.textDidChangeStatus?(self)
    }
}

