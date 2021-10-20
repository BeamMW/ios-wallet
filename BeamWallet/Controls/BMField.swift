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

@objc protocol BMFieldStatusProtocol: AnyObject {
    @objc func didChangeStatus()
}


class BMClearField: UITextField {
    
    private var clearButton: UIButton? {
        return value(forKey: "clearButton") as? UIButton
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        if !isSecureTextEntry && (keyboardType != .decimalPad && keyboardType != .numberPad) {
            clearButtonMode = .whileEditing
        }
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        if !isSecureTextEntry && (keyboardType != .decimalPad && keyboardType != .numberPad) {
            clearButtonMode = .whileEditing
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        if !isSecureTextEntry && (keyboardType != .decimalPad && keyboardType != .numberPad) {
            clearButtonMode = .whileEditing
        }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        if let button = clearButton {
            button.backgroundColor = UIColor.clear
            button.setImage(ClearIcon(), for: .normal)
            button.tintColor = UIColor.main.steel
            button.frame = CGRect(x: self.bounds.width - 24, y: (45 - 14)/2, width: 14, height: 14)
        }
    }
}


class BMField: BMClearField {

    public weak var statusDelegate: BMFieldStatusProtocol?

    enum Status {
        case normal
        case error
    }
        
    private var _defaultHeight:CGFloat = 45
    private var _errorHeight:CGFloat = 45

    var additionalRightOffset:CGFloat = 0
    
    var showEye = false {
        didSet {
            self.rightViewMode = (self.text ?? "").isEmpty ? .never : .whileEditing

            let eyeButton = UIButton(frame: CGRect(x: 0, y: 0, width: 70, height: 45))
            eyeButton.setImage(UIImage(named: "iconEyePass2"), for: .normal)
            eyeButton.setImage(UIImage(named: "iconEyePass1"), for: .selected)
            eyeButton.addTarget(self, action: #selector(onEye), for: .touchUpInside)
            eyeButton.backgroundColor = .clear
            eyeButton.imageEdgeInsets = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 30)
            self.rightView = eyeButton

        }
    }
    
    
    @IBInspectable
    var defaultHeight: CGFloat {
        get {
            return _defaultHeight
        }
        set{
            _defaultHeight = newValue
        }
    }
    
    private var isInFocus = false {
        didSet {
            if self.status != .error {
                if self.isInFocus {
                    self.bgView.backgroundColor = UIColor.white.withAlphaComponent(0.1)
                }
                else {
                    self.bgView.backgroundColor = UIColor.white.withAlphaComponent(0.05)
                }
            }
        }
    }
    
    private var bgView = UIView()
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
                    errorLabel.frame = CGRect(x: 10, y: _defaultHeight + 5, width: self.frame.size.width-20, height: 0)
                    errorLabel.sizeToFit()
                    if status == .error {
                        _errorHeight = defaultHeight + errorLabel.frame.size.height + 5
                    }
                    self.heightConstraint.constant = _errorHeight
                }
                self.textColor = UIColor.main.red
                self.bgView.backgroundColor = UIColor.main.red.withAlphaComponent(0.15)
                self.errorLabel.isHidden = false
                self.layoutSubviews()
                self.statusDelegate?.didChangeStatus()
            case .normal?:
                if self.isInFocus {
                    self.bgView.backgroundColor = UIColor.white.withAlphaComponent(0.1)
                }
                else {
                    self.bgView.backgroundColor = UIColor.white.withAlphaComponent(0.05)
                }
                self.heightConstraint.constant = defaultHeight
                self.textColor = _oldColor
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
    var error: String? {
        get {
            return _error
        }
        set{
            _error = newValue
            errorLabel.text = newValue
            errorLabel.frame = CGRect(x: 10, y: _defaultHeight + 5, width: self.frame.size.width-20, height: 0)
            errorLabel.sizeToFit()
            if status == .error {
                _errorHeight = defaultHeight + errorLabel.frame.size.height + 5
                self.heightConstraint.constant = _errorHeight
            }
            layoutSubviews()
            
            if status == .error {
                self.statusDelegate?.didChangeStatus()
            }
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        _oldColor = self.textColor
        
        NotificationCenter.default.addObserver(forName: UITextField.textDidChangeNotification, object: self, queue: nil) { [weak self] notification in
            guard let strongSelf = self else { return }
            guard let object = notification.object as? BMField, object == strongSelf else { return }
            
            if strongSelf.status != .normal {
                strongSelf.status = .normal
                strongSelf.layoutSubviews()
                strongSelf.statusDelegate?.didChangeStatus()
            }
            
            if strongSelf.showEye {
                strongSelf.rightViewMode = (strongSelf.text ?? "").isEmpty ? .never : .whileEditing
            }
        }
        
        NotificationCenter.default.addObserver(forName: UITextField.textDidBeginEditingNotification, object: self, queue: nil) { [weak self] notification in
            guard let strongSelf = self else { return }
            guard let object = notification.object as? BMField, object == strongSelf else { return }
            
            strongSelf.isInFocus = true
        }
        
        NotificationCenter.default.addObserver(forName: UITextField.textDidEndEditingNotification, object: self, queue: nil) { [weak self] notification in
            guard let strongSelf = self else { return }
            guard let object = notification.object as? BMField, object == strongSelf else { return }
            
            strongSelf.isInFocus = false
        }
        
        if isSecureTextEntry {
            disablePasswordAutoFill()
        }
        
        heightConstraint.constant = defaultHeight

        neededConstraint.append(heightConstraint)
        
        NSLayoutConstraint.activate(neededConstraint)
        
        bgView = UIView(frame: CGRect(x: 0, y: 0, width: self.bounds.width, height: _defaultHeight))
        bgView.backgroundColor = UIColor.white.withAlphaComponent(0.05)
        bgView.cornerRadius = 10
        bgView.isUserInteractionEnabled = false
        self.insertSubview(bgView, at: 0)
        
        self.placeHolderColor = UIColor.white.withAlphaComponent(0.20)
        self.placeHolderFont = ItalicFont(size: 16)
        
        self.errorLabel.font = ItalicFont(size: 14)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        if let view = self.rightView, !self.showEye {
            view.y = 0
        }
        else if let view = self.rightView, self.showEye {
            view.x = self.bounds.width - 40
        }
                
        bgView.frame = CGRect(x: 0, y: 0, width: self.bounds.width, height: _defaultHeight)
        errorLabel.frame = CGRect(x: 10, y: _defaultHeight + 5, width: self.frame.size.width-20, height: errorLabel.frame.size.height)
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
        
        var right:CGFloat = 15
        
        if let view = self.rightView {
            right = view.frame.size.width + 10
            if self.showEye {
                right = right + 10
            }
        }
        
        let padding = UIEdgeInsets(top: (isNormal ? 0 : (errorLabel.frame.size.height + 5) * (-1)), left: 15, bottom: 0, right: right + additionalRightOffset)
        return bounds.inset(by: padding)
    }
    
    open override func placeholderRect(forBounds bounds: CGRect) -> CGRect {
        var isNormal = self.status == .normal || self.status == nil
        if !isNormal && error == nil {
            isNormal = true
        }
        var right:CGFloat = 15
        
        if let view = self.rightView {
            right = view.frame.size.width + 10
            if self.showEye {
                right = right + 10
            }
        }
        let padding = UIEdgeInsets(top: (isNormal ? 0 : (errorLabel.frame.size.height + 5) * (-1)), left: 15, bottom: 0, right: right + additionalRightOffset)
        
        return bounds.inset(by: padding)
    }
    
    open override func rightViewRect(forBounds bounds: CGRect) -> CGRect {
        if self.rightView != nil && self.showEye {
            return CGRect(x: self.width-85, y: 0, width: 70, height: 45)
        }
        
        return super.rightViewRect(forBounds: bounds)
    }
    
    open override func editingRect(forBounds bounds: CGRect) -> CGRect {
        var isNormal = self.status == .normal || self.status == nil
        if !isNormal && error == nil {
            isNormal = true
        }
        var right:CGFloat = 15
        
        if let view = self.rightView {
            right = view.frame.size.width + 10
            if self.showEye {
                right = right + 10
            }
        }
        else if clearButtonMode == .whileEditing {
            if (self.text ?? String.empty()).isEmpty == false {
                right = 30
            }
        }
        
        
        let padding = UIEdgeInsets(top: (isNormal ? 0 : (errorLabel.frame.size.height + 5) * (-1)), left: 15, bottom: 0, right: right + additionalRightOffset)
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
    
    
    @objc private func onHide() {
        _ = self.resignFirstResponder()
    }
    
    @objc private func onEye(sender:UIButton) {
        sender.isSelected = !sender.isSelected
        self.isSecureTextEntry = !self.isSecureTextEntry
    }
}
