//
//  BMWordField.swift
//  BeamWallet
//
// 3/1/19.
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

class BMWordField: BMField {
    
    enum FieldState {
        case correct
        case error
        case empty
    }
    
    private var maxWords = 3
    
    private var accessoryView = UIView()
    private var accessoryOptions = [UIButton]()
    
    private let errorColor = UIColor.main.red
    private let normalColor = Settings.sharedManager().target == Testnet ? UIColor.main.marineTwo : UIColor.main.darkSlateBlue
    
    var suggestions: [String]?
    
    var fState: FieldState! = .none {
        didSet {
            switch fState {
            case .empty?:
                self.textColor = UIColor.white
                self.line.backgroundColor = normalColor
                break
            case .error?:
                self.textColor = errorColor
                self.line.backgroundColor = errorColor
                break
            case .correct?:
                self.textColor = UIColor.white
                self.line.backgroundColor = normalColor
                break
            case .none:
                break
            }
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupSuggestionsView()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setupSuggestionsView()
    }
    
    
    private func setupSuggestionsView() {
        accessoryView = UIView(frame: CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: 44))

        let toolbar = UIToolbar(frame: accessoryView.bounds)
        toolbar.autoresizingMask = .flexibleWidth;
        toolbar.isUserInteractionEnabled = false;
        accessoryView.addSubview(toolbar)

        let width_3 = toolbar.frame.size.width / CGFloat(maxWords)

        for i in 0...maxWords-1 {
            let button = UIButton(type: .custom)
            button.frame = CGRect(x: CGFloat(i) * width_3, y: 0, width: width_3, height: 44)
            button.setTitleColor(UIColor.init(white: 0.3, alpha: 1), for: .normal)
            button.setTitleColor(UIColor.init(white: 0.3, alpha: 0.3), for: .highlighted)
            button.addTarget(self, action: #selector(onSuggestion), for: .touchUpInside)
            accessoryView.addSubview(button)
            accessoryOptions.append(button)
        }

        let separator = UIView(frame: CGRect(x:0, y:43.5, width:accessoryView.frame.size.width, height:0.5))
        separator.autoresizingMask = .flexibleWidth;
        separator.backgroundColor = UIColor.init(white: 0, alpha: 0.2)
        accessoryView.addSubview(separator)
        
        self.addTarget(self, action: #selector(didBeginEditing), for: UIControl.Event.editingDidBegin)
        self.addTarget(self, action: #selector(editingChanged), for: UIControl.Event.editingChanged)
    }
    
    @objc private func onSuggestion(sender:UIButton) {
        if sender.currentAttributedTitle?.string.lengthOfBytes(using: .utf8) == 0 {
            return
        }
        
        self.text = sender.currentAttributedTitle?.string
        
        _ = self.delegate?.textFieldShouldReturn!(self)
    }
    
    @objc private func didBeginEditing() {
        if let txt = text {
            updateAccessoryViewPrefix(prefix: txt)
        }
    }
    
    @objc private func editingChanged() {
        if let txt = text {
            updateAccessoryViewPrefix(prefix: txt)
        }
    }
    
    public func tryAutoInsertWord() {
        if self.inputAccessoryView != nil, let text = self.text {
            var words = MnemonicModel.mnemonicWords(forPrefix: text, suggestions: suggestions) as [String]
            if words.count == 1 {
                if words[0] != text {
                    self.text = words[0]
                }
            }
        }
    }
    
    private func updateAccessoryViewPrefix(prefix:String) {
        var words = MnemonicModel.mnemonicWords(forPrefix: prefix, suggestions: suggestions) as [String]
        
        
        for btn in accessoryOptions {
            btn.setAttributedTitle(nil, for: .normal)
        }

        if words.count == 1 {
            var recommendFirstWord = (words.count == 1)

            if !recommendFirstWord && words.count != 0 && words[0].hasPrefix(prefix) {

                var hasPrefix = false;

                for i in 1...words.count-1 {
                    if words[i].hasPrefix(prefix) {
                        hasPrefix = true;
                        break
                    }
                }

                if !hasPrefix {
                    recommendFirstWord = true;
                }
            }


            for i in 0...words.count-1 {
                if i >= maxWords {
                    break
                }

                let button = accessoryOptions [i]

                let word = words[i]

                if word == prefix {
                    recommendFirstWord = true
                }

                let attributedTitle = NSMutableAttributedString(string: word)
                let range = (word as NSString).range(of: String(prefix))

                if range.location == 0 && range.length > 0 {
                    attributedTitle.addAttribute(NSAttributedString.Key.font, value: BoldFont(size: 15) , range: range)
                }

                if range.length < word.lengthOfBytes(using: .utf8) {
                    attributedTitle.addAttribute(NSAttributedString.Key.font, value: RegularFont(size: 15) , range: NSRange(location: range.length, length: word.lengthOfBytes(using: .utf8) - range.length))
                }
                else{
                    attributedTitle.addAttribute(NSAttributedString.Key.font, value:RegularFont(size: 15) , range: NSRange(location: 0, length: word.lengthOfBytes(using: .utf8)))
                }

                button.setAttributedTitle(attributedTitle, for: .normal)
            }

            if recommendFirstWord {
                let button = accessoryOptions[0];
                button.layer.removeAllAnimations()

                let animate = CABasicAnimation(keyPath: "backgroundColor")
                animate.fromValue = UIColor.black.cgColor
                animate.toValue = UIColor.clear.cgColor
                animate.duration = 1.0;

                button.layer.add(animate, forKey: "recommend")
            }

            self.inputAccessoryView = accessoryView
            self.reloadInputViews()
        }
        else{
            self.inputAccessoryView = nil
        }
    }
}
