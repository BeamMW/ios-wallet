//
//  BMField.swift
//  BeamWallet
//
// 3/1/19.
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

class BMTextView: UITextViewPlacholder {
    
    var line = UIView()
    
    public var defaultOffset:CGFloat = 12
    
    private var _lineColor:UIColor?
    private var _lineHeight:CGFloat = 2
    
    @IBInspectable
    var lineColor: UIColor? {
        get {
            return _lineColor
        }
        set{
            _lineColor = newValue
            line.backgroundColor = _lineColor
        }
    }
    
    @IBInspectable
    var lineHeight: CGFloat {
        get {
            return _lineHeight
        }
        set{
            _lineHeight = newValue
            layoutSubviews()
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        if lineColor == nil {
            line.backgroundColor = UIColor.main.marineThree
        }
        
        addSubview(line)
        
        textContainer.lineFragmentPadding = 0
        contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        
        tintColor = UIColor.white
        tintColorDidChange()
        
        clearButton.frame = CGRect(x: 0, y: 0, width: 20, height: 20)
        clearButton.setImage(ClearIcon(), for: .normal)
        clearButton.isHidden = true
        clearButton.addTarget(self, action: #selector(onClear), for: .touchUpInside)
        addSubview(clearButton)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        if self.frame.size.height <= 42 {
            line.frame = CGRect(x: 0, y: self.frame.size.height - lineHeight - defaultOffset + 4, width: self.frame.size.width, height: lineHeight)
        }
        else{
            line.frame = CGRect(x: 0, y: self.frame.size.height - lineHeight - 4, width: self.frame.size.width, height: lineHeight)
        }
        
        clearButton.frame = CGRect(x: self.width - 25, y: 8, width: 20, height: 20)
    }
    
    override func becomeFirstResponder() -> Bool {
        isInput = true

        if let text = self.attributedText, text.string.isEmpty == false {
            clearButton.isHidden = false
            contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 30)
        }
        else if let text = self.text, text.isEmpty == false {
            clearButton.isHidden = false
            contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 30)
        }

        return super.becomeFirstResponder()
    }
    
    override func resignFirstResponder() -> Bool {
        isInput = false
        
        clearButton.isHidden = true
        contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        
        return super.resignFirstResponder()
    }
    
    @objc private func onClear() {
        self.attributedText = nil
        self.text = nil
        _ = self.delegate?.textView?(self, shouldChangeTextIn: NSRange(location: 0, length: 0), replacementText: String.empty())
        self.delegate?.textViewDidChange?(self)
    }
}

