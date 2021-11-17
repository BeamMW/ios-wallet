//
//  BMField.swift
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

class BMTextView: UITextViewPlacholder {
        
    private var bgView = UIView()

    enum Status {
        case normal
        case error
    }
    
    var status: Status?  {
        didSet {
            switch status {
            case .error?:
                self.textColor = UIColor.main.red
                self.bgView.backgroundColor = UIColor.main.red.withAlphaComponent(0.15)
                self.layoutSubviews()
            case .normal?:
                if self.isInput {
                    self.bgView.backgroundColor = UIColor.white.withAlphaComponent(0.1)
                }
                else {
                    self.bgView.backgroundColor = UIColor.white.withAlphaComponent(0.05)
                }
                self.textColor = UIColor.white
            case .none:
                break
            }
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        
        bgView = UIView(frame: CGRect(x: 0, y: 0, width: self.bounds.width, height: self.frame.size.height))
        bgView.backgroundColor = UIColor.white.withAlphaComponent(0.05)
        bgView.cornerRadius = 10
        bgView.isUserInteractionEnabled = false
        self.insertSubview(bgView, at: 0)
        
        textContainer.lineFragmentPadding = 0
        textContainerInset = UIEdgeInsets(top: 10, left: 15, bottom: 10, right: 15)
        
        tintColor = UIColor.white
        tintColorDidChange()
        
        clearButton.frame = CGRect(x: 0, y: 0, width: 20, height: 20)
        clearButton.setImage(ClearIcon(), for: .normal)
        clearButton.isHidden = true
        clearButton.addTarget(self, action: #selector(onClear), for: .touchUpInside)
        addSubview(clearButton)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        bgView.frame = CGRect(x: 0, y: 0, width: self.bounds.width, height: self.bounds.height)

        clearButton.frame = CGRect(x: self.width - 25, y: 8, width: 20, height: 20)
    }
    
    override func becomeFirstResponder() -> Bool {
        isInput = true
        self.bgView.backgroundColor = UIColor.white.withAlphaComponent(0.1)

        if let text = self.attributedText, text.string.isEmpty == false {
            clearButton.isHidden = false
            textContainerInset = UIEdgeInsets(top: textContainerInset.top, left: textContainerInset.left, bottom: textContainerInset.bottom, right: 30)
        }
        else if let text = self.text, text.isEmpty == false {
            clearButton.isHidden = false
            textContainerInset = UIEdgeInsets(top: textContainerInset.top, left: textContainerInset.left, bottom: textContainerInset.bottom, right: 15)
        }
        else if alwaysVisibleClearButton {
            clearButton.isHidden = false
            textContainerInset = UIEdgeInsets(top: textContainerInset.top, left: textContainerInset.left, bottom: textContainerInset.bottom, right: 15)
        }

        return super.becomeFirstResponder()
    }
    
    override func resignFirstResponder() -> Bool {
        isInput = false
        self.bgView.backgroundColor = UIColor.white.withAlphaComponent(0.05)

        clearButton.isHidden = true
        textContainerInset = UIEdgeInsets(top: textContainerInset.top, left: textContainerInset.left, bottom: textContainerInset.bottom, right: 15)

        return super.resignFirstResponder()
    }
    
    @objc private func onClear() {
        if self.attributedText.string.isEmpty {
            self.isClearPressed = true
        }
        self.attributedText = nil
        self.text = nil
        _ = self.delegate?.textView?(self, shouldChangeTextIn: NSRange(location: 0, length: 0), replacementText: String.empty())
        self.delegate?.textViewDidChange?(self)
        self.isClearPressed = false
    }
}

