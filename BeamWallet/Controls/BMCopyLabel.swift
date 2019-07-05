//
//  BMCopyLabel.swift
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

protocol BMCopyLabelDelegate: AnyObject {
    func onCopied()
}

class BMCopyLabel: UILabel {

    weak var delegate: BMCopyLabelDelegate?

    public var copyText:String?
    public var displayCopyAlert = true

    override public var canBecomeFirstResponder: Bool {
        get {
            return true
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setup()
    }
    
    private func setup() {
        isUserInteractionEnabled = true
        addGestureRecognizer(UILongPressGestureRecognizer(
            target: self,
            action: #selector(showCopyMenu(sender:))
        ))
    }
    
    @objc private func customCopy(_ sender: Any?) {
        UIPasteboard.general.string = (copyText != nil ) ? copyText : text

        UIMenuController.shared.setMenuVisible(false, animated: true)
        
        if displayCopyAlert {
            ShowCopied()
        }
        
        self.delegate?.onCopied()
    }
    
    @objc private func showCopyMenu(sender: Any?) {
        becomeFirstResponder()
        let menu = UIMenuController.shared
        if !menu.isMenuVisible {
            menu.setTargetRect(bounds, in: self)
            menu.menuItems = [
                UIMenuItem(
                    title: Localizable.shared.strings.copy,
                    action: #selector(customCopy(_:))
                )
            ]
            menu.setMenuVisible(true, animated: true)
            
            let generator = UIImpactFeedbackGenerator(style: .medium)
            generator.impactOccurred()
        }
    }
    
    override func canPerformAction(_ action: Selector, withSender sender: Any?) -> Bool {
        return (action == #selector(customCopy(_:)))
    }

}
