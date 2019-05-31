//
// ReceiveFieldCell.swift
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

class ReceiveFieldCell: BaseCell {

    weak var delegate: ReceiveCellProtocol?

    @IBOutlet weak private var textField: BMField!
    @IBOutlet weak private var nameLabel: UILabel!

    override func awakeFromNib() {
        super.awakeFromNib()
        
        selectionStyle = .none
       // contentView.backgroundColor = UIColor.main.marineTwo.withAlphaComponent(0.2)
    }
}

extension ReceiveFieldCell : UITextFieldDelegate {

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        
        return true
    }
    
    func textFieldShouldEndEditing(_ textField: UITextField) -> Bool {
        self.delegate?.textValueDidReturn?(self)
        
        return true
    }
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        self.delegate?.textValueDidBegin?(self)
    }
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        
        let textFieldText: NSString = (textField.text ?? String.empty()) as NSString
        let txtAfterUpdate = textFieldText.replacingCharacters(in: range, with: string)
        
        self.delegate?.textValueDidChange?(self, txtAfterUpdate)
        
        return true
    }
}

extension ReceiveFieldCell: Configurable {
    
    func configure(with options: (name: String, value:String)) {
        textField.text = options.value
        nameLabel.text = options.name
        nameLabel.letterSpacing = 2
    }
}
