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
    @IBOutlet weak private var secondCurrencyLabel: UILabel!
    @IBOutlet weak private var maxAmountErrorLabel: UILabel!

    @IBOutlet var topNameOffset: NSLayoutConstraint!
    @IBOutlet var topStackOffset: NSLayoutConstraint!
    @IBOutlet var botStackOffset: NSLayoutConstraint!

    @IBOutlet weak private var currencyLabel: UILabel!
    @IBOutlet weak private var currencyArrow: UIImageView!
    @IBOutlet weak private var currencyIcon: AssetIconView!
    @IBOutlet weak var currencyView: UIView!

    public var fee:Double = 0
    public var info:String?
    
    private var type: BMTransactionType = BMTransactionType(BMTransactionTypeSimple)

    public var titleColor: UIColor? {
        didSet {
            if let color = titleColor {
                nameLabel.textColor = color
            }
        }
    }
    
    public var hideNameLabel:Bool? = nil
    {
        didSet {
            if let hide = hideNameLabel {
                nameLabel.isHidden = hide
                nameLabel.text = nil
                topNameOffset.constant = 0
                topStackOffset.constant = 0
                botStackOffset.constant = 20
            }
        }
    }
    
    
    public var error:String?
    {
        didSet{
            if error == nil {
                textField.status = .normal
                textField.error = nil
            }
            else{
                textField.status = .error
                textField.error = error
            }
        }
    }

    public var selectedAssetId:Int?
    {
        didSet{
            
            if selectedAssetId != nil {
                let asset = AssetsManager.shared().getAsset(Int32(selectedAssetId ?? 0))

                currencyLabel.letterSpacing = 2
                
                let id = "(\(selectedAssetId ?? 0))"
                let text = asset?.unitName ?? ""
                let fullString = text + " " + id
                
                let attributedString = NSMutableAttributedString(string: fullString)
                let range = (fullString as NSString).range(of: id)
                attributedString.addAttribute(.foregroundColor, value: UIColor.white.withAlphaComponent(0.5), range: range)
                
                currencyLabel.attributedText = attributedString
                
                if let asset = asset {
                    currencyIcon.setAsset(asset)
                }
                
                if AssetsManager.shared().getAssetsWithBalance().count >= 1 {
                    currencyView.isUserInteractionEnabled = true
                    currencyArrow.isHidden = false
                }
                else {
                    currencyView.isUserInteractionEnabled = false
                    currencyArrow.isHidden = true
                }
            }
            else {
                currencyView.isUserInteractionEnabled = false
                currencyArrow.isHidden = true
                currencyLabel.letterSpacing = 2
                
                if let asset = AssetsManager.shared().assets.firstObject as? BMAsset {
                    currencyIcon.setAsset(asset)
                }
            }
        }
    }
    public var maxAmountError:String?
    {
        didSet{
            self.maxAmountErrorLabel.text = maxAmountError
            if maxAmountError != nil  {
                self.maxAmountErrorLabel.isHidden = false
            }
            else {
                self.maxAmountErrorLabel.isHidden = true
            }
        }
    }
    
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        textField.additionalRightOffset = 100
        
        allowHighlighted = false
        selectionStyle = .none
        
        secondCurrencyLabel.textColor = UIColor.main.blueyGrey
        secondCurrencyLabel.font = RegularFont(size: 14)
        
        maxAmountErrorLabel.textColor = UIColor.main.blueyGrey
        maxAmountErrorLabel.font = RegularFont(size: 14)
        
//        erorLabel.textColor = UIColor.main.red
//        erorLabel.isHidden = true
//        erorLabel.text = nil
        
        textField.statusDelegate = self
        textField.ignoreTextChanges = true
        
        currencyView.isUserInteractionEnabled = false
        currencyView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(onCurrency(_:))))
        
        nameLabel.isUserInteractionEnabled = true
        nameLabel.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(onTap(_:))))
                
        if Settings.sharedManager().isDarkMode {
            secondCurrencyLabel.textColor = UIColor.main.steel
            nameLabel.textColor = UIColor.main.steel;
            maxAmountErrorLabel.textColor = UIColor.main.steel;
        }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        textField.placeholder = Localizable.shared.strings.zero
        textField.placeHolderColor = UIColor.white.withAlphaComponent(0.2)
        textField.placeHolderFont = RegularFont(size: 30)
        textField.additionalRightOffset = currencyView.width
    }
    
    func disable() {
        currencyLabel.alpha = 0.5
        currencyArrow.alpha = 0.5
        currencyIcon.alpha = 0.5
        textField.alpha = 0.5
    }
    
    func enable() {
        currencyLabel.alpha = 1.0
        currencyArrow.alpha = 1.0
        currencyIcon.alpha = 1.0
        textField.alpha = 1
    }
    
    @objc private func onTap(_ sender: UITapGestureRecognizer) {
        _ = textField.becomeFirstResponder()
    }
    
    @objc private func onCurrency(_ sender: UITapGestureRecognizer) {
        self.currencyArrow.image = IconDownArrow()
        self.delegate?.onRightButton?(self)
    }
    
    public func beginEditing(){
        _ = textField.becomeFirstResponder()
    }
}

extension BMAmountCell: Configurable {
    
    func setType(type: BMTransactionType) {
        self.type = type
        
        switch type {
        case 1:
            textField.textColor = UIColor.main.brightTeal
            textField.setNormalColor(color: UIColor.main.brightTeal)
            break
        default:
            return
        }
    }
    
    func configure(with options: (name: String, value:String?)) {
        if (options.name == Localizable.shared.strings.amount.uppercased() || options.name == Localizable.shared.strings.you_send.uppercased()) && self.type != BMTransactionTypeUnlink {
            textField.textColor = UIColor.main.heliotrope
            textField.setNormalColor(color: UIColor.main.heliotrope)
        }
        else if self.type == BMTransactionTypeUnlink {
            textField.textColor = UIColor.main.brightTeal
            textField.setNormalColor(color: UIColor.main.brightTeal)
        }
        
        nameLabel.text = options.name
        nameLabel.letterSpacing = 2
        
        textField.text = options.value
        
        currencyArrow.image = IconNextArrow()
    }
    
    func setSecondAmount(amount:String) {
        if amount.isEmpty {
            secondCurrencyLabel.isHidden = true
        }
        else {
            secondCurrencyLabel.text = amount
            secondCurrencyLabel.isHidden = false
        }
    }
}

extension BMAmountCell : UITextFieldDelegate {
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        self.delegate?.textValueDidReturn?(self)
    }
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        self.delegate?.textValueDidBegin?(self)
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        
        return true
    }
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        
        let textFieldText: NSString = (textField.text ?? String.empty()) as NSString
        
        var txtAfterUpdate = textFieldText.replacingCharacters(in: range, with: string).replacingOccurrences(of: String.coma(), with: String.dot())
        
        if textField.text == String.empty() && txtAfterUpdate == String.dot() {
            txtAfterUpdate = "0."
            textField.text = txtAfterUpdate
            return false
        }
        
        if !txtAfterUpdate.isCorrectAmount(fee: fee) {
            return false
        }
        
        if string == String.coma() {
            textField.text = txtAfterUpdate
            return false
        }
        
//        self.error = nil
        
        self.delegate?.textValueDidChange?(self, txtAfterUpdate, true)


        return true
    }
}

extension BMAmountCell : BMFieldStatusProtocol {
    func didChangeStatus() {
      //  self.delegate?.textDidChangeStatus?(self)
    }
}

