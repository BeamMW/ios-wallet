//
// BMSearchView.swift
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

import Foundation


class BMSearchView: UIView {
    
    private let searchField = UITextField()
    
    public var onSearchTextChanged : ((String) -> Void)?
    public var onCancelSearch : (() -> Void)?

    init() {
        super.init(frame: CGRect(x: 0, y: 0, width: UIScreen.main.bounds.size.width, height: 46))
        
        backgroundColor = UIColor.clear
                
        let iconView = UIImageView(frame: CGRect(x: 10, y: 11, width: 14, height: 14))
        iconView.contentMode = .scaleAspectFit
        iconView.image = IconSearchSmall()?.withRenderingMode(.alwaysTemplate)
        iconView.tintColor = UIColor.main.steel
        
        let leftView = UIView(frame: CGRect(x: 0, y: 0, width: 30, height: 36))
        leftView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(onFocus(_:))))
        leftView.addSubview(iconView)
        
        let clearButton = UIImageView(frame: CGRect(x: 10, y: 11, width: 14, height: 14))
        clearButton.contentMode = .scaleAspectFit
        clearButton.image = ClearIcon()?.withRenderingMode(.alwaysTemplate)
        clearButton.tintColor = UIColor.main.steel
        
        let clearButtonView = UIView(frame: CGRect(x: 0, y: 0, width: 30, height: 36))
        clearButtonView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(onClear(_:))))
        clearButtonView.addSubview(clearButton)

        searchField.frame = CGRect(x: defaultX, y: 5, width:  (defaultWidth), height: 36)
        searchField.leftView = leftView
        searchField.leftViewMode = .always
        searchField.rightView = clearButtonView
        searchField.rightViewMode = .never
        searchField.layer.cornerRadius = 10
        searchField.font = RegularFont(size: 16)
        searchField.backgroundColor = UIColor.main.marineThree
        searchField.placeholder = Localizable.shared.strings.search_transactions
        searchField.placeHolderColor = UIColor.white.withAlphaComponent(0.2)
        searchField.tintColor = UIColor.white
        searchField.textColor = UIColor.white
        searchField.autocorrectionType = .no
        searchField.spellCheckingType = .no
        searchField.delegate = self
        searchField.addTarget(self, action: #selector(textFieldDidChange(_:)), for: .editingChanged)
        
        addSubview(searchField)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError(Localizable.shared.strings.fatalInitCoderError)
    }
    
    @objc private func onClear(_ sender: UITapGestureRecognizer) {
        searchField.text = String.empty()
        searchField.rightViewMode = .never
        onSearchTextChanged?(String.empty())
    }
    
    @objc private func onFocus(_ sender: UITapGestureRecognizer) {
        searchField.becomeFirstResponder()
    }
    
    public func show() {
        alpha = 1
    }
    
    public func hide(){
        searchField.resignFirstResponder()
        alpha = 0
    }
    
    @objc private func textFieldDidChange(_ textField: BMField) {
        let text = textField.text ?? String.empty()
        searchField.rightViewMode = (text.isEmpty) ? .never : .whileEditing
        onSearchTextChanged?(text)
    }
}

extension BMSearchView : UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
}
