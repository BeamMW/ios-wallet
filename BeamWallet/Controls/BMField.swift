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

    private var errorLabel:UILabel?

    private var _lineColor:UIColor?
    private var _lineHeight:CGFloat = 2
    private var _error:String?
    private var _oldColor:UIColor?
        
    var status: Status?  {
        didSet {
            switch status {
            case .error?:
                self.textColor = UIColor.main.red
                self.line.backgroundColor = UIColor.main.red
                self.errorLabel?.isHidden = false
            case .normal?:
                self.textColor = _oldColor
                self.line.backgroundColor = lineColor
                self.errorLabel?.isHidden = true
            case .none:
                break
            }
        }
    }
    
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
            errorLabel?.text = newValue
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
            
            strongSelf.status = .normal
        }
        
        if isSecureTextEntry {
            disablePasswordAutoFill()
        }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        line.frame = CGRect(x: 0, y: self.frame.size.height-lineHeight, width: self.frame.size.width, height: lineHeight)
    }

    override var text: String? {
        didSet {
           status = .normal
        }
    }
}
