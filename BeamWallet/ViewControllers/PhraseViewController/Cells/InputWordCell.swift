//
//  InputWordCell.swift
//  BeamWallet
//
//  Created by Denis on 3/1/19.
//  Copyright © 2019 Denis. All rights reserved.
//

import UIKit

protocol InputWordCellCellDelegate: AnyObject {
    func textValueCellDidEndEditing(_ sender: InputWordCell, _ text:String)
}

class InputWordCell: UICollectionViewCell, Delegating {

    static let reuseIdentifier = "WordCell"
    
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
            numberLabel.layer.borderColor = UIColor.main.darkSlateBlue.cgColor
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
        textField.resignFirstResponder()
        return true
    }
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        
        let textFieldText: NSString = (textField.text ?? "") as NSString

        let txtAfterUpdate = textFieldText.replacingCharacters(in: range, with: string)

        if(txtAfterUpdate.isEmpty)
        {
            wordField.fState = BMWordField.FieldState.empty
        }
        
        return true
    }
}
