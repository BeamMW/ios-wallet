//
// InputWordCell.swift
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

protocol InputWordCellCellDelegate: AnyObject {
    func textValueCellDidEndEditing(_ sender: InputWordCell, _ text:String)
    func textValueCellReturn(_ sender: InputWordCell, _ text:String)
}

class InputWordCell: UICollectionViewCell, Delegating {

    static let reuseIdentifier = "WordCell"
    static let nib = "InputWordCell"

    @IBOutlet weak var wordField: BMWordField!
    @IBOutlet weak var numberLabel: UILabel!
    
    weak var delegate: InputWordCellCellDelegate?

    override func awakeFromNib() {
        super.awakeFromNib()
    }
    
    func startEditing() {
        wordField.becomeFirstResponder()
    }
}

extension InputWordCell: Configurable {
    
    func configure(with word:BMWord) {
        numberLabel.text = String(word.index+1)
        wordField.text = String(word.value)
        
        if(word.value.isEmpty){
            numberLabel.backgroundColor = UIColor.clear
            numberLabel.layer.borderColor = Settings.sharedManager().target == Testnet ? UIColor.main.marineTwo.cgColor : UIColor.main.darkSlateBlue.cgColor
            numberLabel.textColor =  UIColor.main.veryLightPink50
            wordField.fState = BMWordField.FieldState.empty
        }
        else if(word.correct){
            numberLabel.backgroundColor = UIColor.main.green
            numberLabel.layer.borderColor = UIColor.clear.cgColor
            numberLabel.textColor =  UIColor.main.marine
            wordField.fState = BMWordField.FieldState.correct
        }
        else{
            numberLabel.backgroundColor = UIColor.main.red
            numberLabel.layer.borderColor = UIColor.clear.cgColor
            numberLabel.textColor =  UIColor.main.marine
            wordField.fState = BMWordField.FieldState.error
        }
    }
}

extension InputWordCell: UITextFieldDelegate {
    func textFieldDidEndEditing(_ textField: UITextField) {
        self.delegate?.textValueCellDidEndEditing(self,textField.text ?? "")
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        wordField.tryAutoInsertWord()
        
        self.delegate?.textValueCellReturn(self,textField.text ?? "")

        textField.resignFirstResponder()

        return true
    }
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        
        if string == " " {
            return false
        }
        
        let textFieldText: NSString = (textField.text ?? "") as NSString

        let txtAfterUpdate = textFieldText.replacingCharacters(in: range, with: string)

        if(txtAfterUpdate.isEmpty)
        {
            wordField.fState = BMWordField.FieldState.empty
        }
        
        return true
    }
}
