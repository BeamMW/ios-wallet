//
//  AddressCommentCell.swift
//  BeamWallet
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


protocol AddressCommentCellDelegate: AnyObject {
    func onChangeComment(value:String)
}

class AddressCommentCell: UITableViewCell {

    weak var delegate: AddressCommentCellDelegate?

    @IBOutlet weak private var commentField: UITextViewPlacholder!

    override func awakeFromNib() {
        super.awakeFromNib()
        
        selectionStyle = .none
        
        self.backgroundColor = UIColor.main.marineThree
        
        commentField.placeholder = Localizable.shared.strings.no_name
        commentField.delegate = self
    }
}

extension AddressCommentCell: UITextViewDelegate {
    
    func textViewDidBeginEditing(_ textView: UITextView) {
        
    }
    
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        
        if text == "\n" {
            textView.resignFirstResponder()
            return false
        }
        
        let textFieldText: NSString = (textView.text ?? "") as NSString
        
        let txtAfterUpdate = textFieldText.replacingCharacters(in: range, with: text)
        
        self.delegate?.onChangeComment(value: txtAfterUpdate)
        
        return true
    }
}

extension AddressCommentCell: Configurable {
    
    func configure(with text: String) {
        commentField.text = text
    }
}

extension AddressCommentCell: DynamicContentHeight {
    
    static func height() -> CGFloat {
        return 120
    }
}


