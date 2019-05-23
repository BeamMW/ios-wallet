//
// ReceiveAddressRequestedAmountCell.swift
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

class ReceiveAddressRequestedAmountCell: BaseCell {

    weak var delegate: ReceiveCellProtocol?

    @IBOutlet weak private var textField: BMField!
    
    private var prefixLabel:UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        selectionStyle = .none

        prefixLabel = UILabel()
        prefixLabel.text = "BEAM"
        prefixLabel.font = textField.font
        prefixLabel.textColor = textField.textColor
        prefixLabel.sizeToFit()
        
        textField.rightView = prefixLabel
        textField.rightViewMode = .always
    }
    
    @IBAction func onRemove(sender :UIButton) {
        delegate?.onClickRemoveRequest()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
//        let size: CGSize = textField.text?.size(withAttributes: [NSAttributedString.Key.font: textField.font ?? UIFont.systemFont(ofSize: 16)]) ?? CGSize.zero
//
//        prefixLabel.frame = CGRect(x: 0, y: 0, width: textField.frame.size.width - size.width - prefixLabel.frame.size.width, height: prefixLabel.frame.size.height)
//        textField.rightView = prefixLabel
    }
}

extension ReceiveAddressRequestedAmountCell : UITextFieldDelegate {
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        
        return true
    }
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        self.delegate?.textValueDidBegin(self)
    }
    
    func textFieldShouldEndEditing(_ textField: UITextField) -> Bool {
        self.delegate?.textValueDidReturn(self)
        
        return true
    }
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        
        let mainCount = 9
        let comaCount = 8
        
        let textFieldText: NSString = (textField.text ?? String.empty()) as NSString
        
        let txtAfterUpdate = textFieldText.replacingCharacters(in: range, with: string).replacingOccurrences(of: ",", with: ".")
        
        if Double(txtAfterUpdate) == nil && !txtAfterUpdate.isEmpty {
            return false
        }
        
        if (!txtAfterUpdate.isDecimial()) {
            return false
        }
        
        if !txtAfterUpdate.isEmpty {
            let split = txtAfterUpdate.split(separator: ".")
            if split[0].lengthOfBytes(using: .utf8) > mainCount {
                return false
            }
            else if split.count > 1 {
                if split[1].lengthOfBytes(using: .utf8) > comaCount {
                    return false
                }
                else if split[1].lengthOfBytes(using: .utf8) == comaCount && Double(txtAfterUpdate) == 0 {
                    return false
                }
            }
        }
        
        if let amount = Double(txtAfterUpdate) {
            if AppModel.sharedManager().canReceive(amount, fee: 0) != nil {
                return false
            }
        }
        
        textField.text = txtAfterUpdate
        
        self.delegate?.textValueDidChange(self, txtAfterUpdate)
        
        return false
    }
}
