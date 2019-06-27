//
// BMField.swift
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

class BMField: UITextField {

    enum Status {
        case normal
        case error
    }
    
    var line = UIView()
    
    private var _defaultHeight:CGFloat = 30
    private var _errorHeight:CGFloat = 50

    @IBInspectable
    var defaultHeight: CGFloat {
        get {
            return _defaultHeight
        }
        set{
            _defaultHeight = newValue
        }
    }
    
    private var _lineColor:UIColor?
    private var _lineHeight:CGFloat = 2
    private var _error:String?
    private var _oldColor:UIColor?
    
    public func setNormalColor(color:UIColor) {
        _oldColor = color
    }
    
    var status: Status?  {
        didSet {
            switch status {
            case .error?:
                if error != nil {
                    errorLabel.frame = CGRect(x: 0, y: line.frame.size.height + line.frame.origin.y + 5, width: self.frame.size.width, height: 0)
                    errorLabel.sizeToFit()
                    if status == .error {
                        _errorHeight = defaultHeight + errorLabel.frame.size.height + 5
                    }
                    self.heightConstraint.constant = _errorHeight
                }
                self.textColor = UIColor.main.red
                self.line.backgroundColor = UIColor.main.red
                self.errorLabel.isHidden = false
            case .normal?:
                self.heightConstraint.constant = defaultHeight
                self.textColor = _oldColor
                self.line.backgroundColor = lineColor
                self.errorLabel.isHidden = true
            case .none:
                break
            }
        }
    }
    
    private var neededConstraint = [NSLayoutConstraint]()
    lazy var heightConstraint: NSLayoutConstraint = {
        return NSLayoutConstraint(item: self,
                                  attribute: .height,
                                  relatedBy: .equal,
                                  toItem: nil,
                                  attribute: .notAnAttribute,
                                  multiplier: 1,
                                  constant: 0)
    }()
    
    private lazy var errorLabel: UILabel = {
        let label = UILabel()
        label.textColor = UIColor.main.red
        label.font = RegularFont(size: 16)
        label.isHidden = true
        label.numberOfLines = 0
        addSubview(label)

        return label
    }()
    
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
    
    @IBInspectable
    var error: String? {
        get {
            return _error
        }
        set{
            _error = newValue
            errorLabel.text = newValue
            errorLabel.frame = CGRect(x: 0, y: line.frame.size.height + line.frame.origin.y + 5, width: self.frame.size.width, height: 0)
            errorLabel.sizeToFit()
            if status == .error {
                _errorHeight = defaultHeight + errorLabel.frame.size.height + 5
                self.heightConstraint.constant = _errorHeight
            }
            layoutSubviews()
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        _oldColor = self.textColor

        if lineColor == nil {
            line.backgroundColor = Settings.sharedManager().target == Testnet ? UIColor.main.marineTwo : UIColor.main.darkSlateBlue
            lineColor = Settings.sharedManager().target == Testnet ? UIColor.main.marineTwo : UIColor.main.darkSlateBlue
        }
        
        addSubview(line)
        
        NotificationCenter.default.addObserver(forName: UITextField.textDidChangeNotification, object: self, queue: nil) { [weak self] notification in
            guard let strongSelf = self else { return }
            guard let object = notification.object as? BMField, object == strongSelf else { return }
            
            if strongSelf.status != .normal {
                strongSelf.status = .normal
            }
        }
        
        if isSecureTextEntry {
            disablePasswordAutoFill()
        }
        
        heightConstraint.constant = defaultHeight

        neededConstraint.append(heightConstraint)
        
        NSLayoutConstraint.activate(neededConstraint)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        var w = self.frame.size.width
        
        if let view = self.rightView {
            w = w - view.frame.size.width - 10
            view.y = 0
        }
        
        line.frame = CGRect(x: 0, y: defaultHeight - lineHeight, width: w, height: lineHeight)
        
        errorLabel.frame = CGRect(x: 0, y: line.frame.size.height + line.frame.origin.y + 5, width: self.frame.size.width, height: errorLabel.frame.size.height)
    }

    override var text: String? {
        didSet {
            if status != .normal {
                status = .normal
            }
        }
    }
    
    open override func textRect(forBounds bounds: CGRect) -> CGRect {
        var isNormal = self.status == .normal || self.status == nil
        if !isNormal && error == nil {
            isNormal = true
        }
        
        var right:CGFloat = 0
        
        if let view = self.rightView {
            right = view.frame.size.width + 10
        }
        
        let padding = UIEdgeInsets(top: (isNormal ? 0 : (errorLabel.frame.size.height) * (-1)), left: 0, bottom: 0, right: right)
        return bounds.inset(by: padding)
    }
    
    open override func placeholderRect(forBounds bounds: CGRect) -> CGRect {
        var isNormal = self.status == .normal || self.status == nil
        if !isNormal && error == nil {
            isNormal = true
        }
        var right:CGFloat = 0
        
        if let view = self.rightView {
            right = view.frame.size.width + 10
        }
        let padding = UIEdgeInsets(top: (isNormal ? 0 : (errorLabel.frame.size.height) * (-1)), left: 0, bottom: 0, right: right)
        
        return bounds.inset(by: padding)
    }
    
    open override func editingRect(forBounds bounds: CGRect) -> CGRect {
        var isNormal = self.status == .normal || self.status == nil
        if !isNormal && error == nil {
            isNormal = true
        }
        var right:CGFloat = 0
        
        if let view = self.rightView {
            right = view.frame.size.width + 10
        }
        let padding = UIEdgeInsets(top: (isNormal ? 0 : (errorLabel.frame.size.height) * (-1)), left: 0, bottom: 0, right: right)
        return bounds.inset(by: padding)
    }
    
    override func becomeFirstResponder() -> Bool {
        
        if keyboardType == .numberPad || keyboardType == .decimalPad || returnKeyType == .next {
            let toolbar = UIToolbar(frame: CGRect(x: 0, y: 0, width: UIScreen.main.bounds.size.width, height: 44))
            let item = UIBarButtonItem(title: Localizable.shared.strings.done, style: .plain, target: self, action: #selector(onHide))
            item.setTitleTextAttributes([NSAttributedString.Key.font : BoldFont(size: 17)], for: .normal)
            toolbar.items = [UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil),item]
            self.inputAccessoryView = toolbar
        }
        
        return super.becomeFirstResponder()
    }
    
    @objc private func onHide(){
        self.resignFirstResponder()
    }
}
