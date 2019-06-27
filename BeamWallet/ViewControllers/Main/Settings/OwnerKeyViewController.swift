//
// OwnerKeyViewController.swift
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

class OwnerKeyViewController: BaseViewController {

    public var ownerKey:String!
    
    @IBOutlet private weak var ownerKeyLabel: UILabel!
    @IBOutlet private weak var ownerKeyTitleLabel: UILabel!
    @IBOutlet private weak var detailLabelRight: NSLayoutConstraint!
    @IBOutlet private weak var detailLabelLeft: NSLayoutConstraint!

    override func viewDidLoad() {
        super.viewDidLoad()

        topOffset?.constant = topOffset?.constant ?? 0 + 30

        if Device.screenType == .iPhones_5 {
            detailLabelRight.constant = 0
            detailLabelLeft.constant = 0
        }
        
        title = Localizable.shared.strings.show_owner_key
        
        ownerKeyLabel.text = ownerKey
        ownerKeyTitleLabel.text = Localizable.shared.strings.addDots(value: Localizable.shared.strings.key_code.uppercased())
        ownerKeyTitleLabel.letterSpacing = 1.5
    }
    
    @IBAction func onCopy(sender :UIButton) {
        UIPasteboard.general.string = ownerKey
        
        ShowCopied(text: Localizable.shared.strings.ownerkey_copied)
        
        back()
    }
}
