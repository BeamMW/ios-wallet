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

    @IBOutlet weak private var textField: BMField!
    @IBOutlet weak private var nameLabel: UILabel!
    @IBOutlet weak private var mainStack: UIStackView!
    
    public var copyText: String?

    override func awakeFromNib() {
        super.awakeFromNib()
        
        selectionStyle = .none
        
       // contentView.backgroundColor = UIColor.main.marineTwo.withAlphaComponent(0.35)
    }
    
    public func beginEditing(text:String?){
        copyText = text
        textField.becomeFirstResponder()
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
    
    @objc private func onRightButton() {
        delegate?.onRightButton?(self)
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
                    self.textField.resignFirstResponder()
                }
            }
            textField.inputAccessoryView = inputBar
        }
        return true
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        self.delegate?.textValueDidReturn?(self)
    }
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        self.delegate?.textValueDidBegin?(self)
    }
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        
        let textFieldText: NSString = (textField.text ?? String.empty()) as NSString
        let txtAfterUpdate = textFieldText.replacingCharacters(in: range, with: string)
        
        self.textField.status = .normal
        self.delegate?.textValueDidChange?(self, txtAfterUpdate, true)
        
        return true
    }
}

extension BMFieldCell: Configurable {
    
    func configure(with options: (name: String, value:String, rightIcon:UIImage? )) {
        textField.text = options.value
        nameLabel.text = options.name
        nameLabel.letterSpacing = 2
        
        if let icon = options.rightIcon {
            mainStack.spacing = 10
            
            let button = UIButton(type: .system)
            button.tintColor = UIColor.white
            button.frame = CGRect(x: 0, y: 0, width: 50, height: 32)
            button.setImage(icon, for: .normal)
            button.contentHorizontalAlignment = .right
            button.addTarget(self, action: #selector(onRightButton), for: .touchUpInside)
            textField.rightView = button
            textField.rightViewMode = .always
        }
    }
}
