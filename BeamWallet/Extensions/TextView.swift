//
// TextView.swift
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

import Foundation

class UITextViewPlacholder : UITextView
{
    
    public var placholderFont:UIFont?
    public var placholderColor:UIColor?
    public var clearButton = UIButton()
    public var isInput = false
    public var alwaysVisibleClearButton = false
    public var isClearPressed = false

    
    override open var attributedText: NSAttributedString! {
        didSet {
            attibutedTextChanged()
        }
    }
    
    override open var text: String! {
        didSet {
            textChanged()
        }
    }
    
    /// Resize the placeholder when the UITextView bounds change
    override open var bounds: CGRect {
        didSet {
            self.resizePlaceholder()
        }
    }
    
    
    /// The UITextView placeholder text
    public var placeholder: String? {
        get {
            var placeholderText: String?
            
            if let placeholderLabel = self.viewWithTag(100) as? UILabel {
                placeholderText = placeholderLabel.text
            }
            
            return placeholderText
        }
        set {
            if let placeholderLabel = self.viewWithTag(100) as! UILabel? {
                placeholderLabel.text = newValue
                placeholderLabel.sizeToFit()
            } else {
                self.addPlaceholder(newValue!)
            }
        }
    }
    
    /// When the UITextView did change, show or hide the label based on if the UITextView is empty or not
    ///
    /// - Parameter textView: The UITextView that got updated
    @objc private func textChanged() {
        if let placeholderLabel = self.viewWithTag(100) as? UILabel {
            placeholderLabel.isHidden = self.text.lengthOfBytes(using: .utf8) > 0
        }
        
        if let text = self.text, text.isEmpty == false, self.isInput {
            clearButton.isHidden = false
            textContainerInset = UIEdgeInsets(top: textContainerInset.top, left: textContainerInset.left, bottom: textContainerInset.bottom, right: 30)
        }
        else if alwaysVisibleClearButton && isClearPressed && (self.attributedText == nil  || self.attributedText.string.isEmpty){
            self.endEditing(true)
        }
        else if alwaysVisibleClearButton  {
            
        }
        else{
            clearButton.isHidden = true
            textContainerInset = UIEdgeInsets(top: textContainerInset.top, left: textContainerInset.left, bottom: textContainerInset.bottom, right: 0)
        }
    }
    
    @objc private func attibutedTextChanged() {
        if let placeholderLabel = self.viewWithTag(100) as? UILabel {
            placeholderLabel.isHidden = self.attributedText.string.lengthOfBytes(using: .utf8) > 0
        }
        
        if let text = self.attributedText, text.string.isEmpty == false, self.isInput {
            clearButton.isHidden = false
            textContainerInset = UIEdgeInsets(top: textContainerInset.top, left: textContainerInset.left, bottom: textContainerInset.bottom, right: 30)
        }
        else if alwaysVisibleClearButton && isClearPressed && (self.attributedText == nil  || self.attributedText.string.isEmpty){
            self.endEditing(true)
        }
        else if alwaysVisibleClearButton  {
            
        }
        else{
            clearButton.isHidden = true
            textContainerInset = UIEdgeInsets(top: textContainerInset.top, left: textContainerInset.left, bottom: textContainerInset.bottom, right: 0)
        }
    }
    
    /// Resize the placeholder UILabel to make sure it's in the same position as the UITextView text
    private func resizePlaceholder() {
        if let placeholderLabel = self.viewWithTag(100) as! UILabel? {
            let labelX = self.textContainer.lineFragmentPadding
            let labelY = self.textContainerInset.top - 2
            let labelWidth = self.frame.width - (labelX * 2)
            let labelHeight = placeholderLabel.frame.height
            
            placeholderLabel.frame = CGRect(x: 16, y: labelY, width: labelWidth, height: labelHeight)
        }
    }
    
    /// Adds a placeholder UILabel to this UITextView
    private func addPlaceholder(_ placeholderText: String, _ font:UIFont? = nil) {
        NotificationCenter.default.addObserver(self, selector: #selector(textChanged), name: UITextView.textDidChangeNotification, object: nil)

        let placeholderLabel = UILabel()
        
        placeholderLabel.text = placeholderText
        placeholderLabel.sizeToFit()
        
        if let f = self.placholderFont {
            placeholderLabel.font = f
        }
        else{
            placeholderLabel.font = self.font
        }
        
        if let c = self.placholderColor {
            placeholderLabel.textColor = c
        }
        else{
            placeholderLabel.textColor = UIColor.init(red: 112/255, green: 128/255, blue: 138/255, alpha: 1)
        }
     
        placeholderLabel.tag = 100
        
        placeholderLabel.isHidden = self.text.lengthOfBytes(using: .utf8) > 0

        self.addSubview(placeholderLabel)
        self.resizePlaceholder()
    }    
}
