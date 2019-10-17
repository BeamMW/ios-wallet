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
    @IBOutlet private weak var noticeLabel: UILabel!

    @IBOutlet private weak var copyView: UIView!
    @IBOutlet private weak var copyNextView: UIView!
    @IBOutlet private weak var copyRestoreButton: UIButton!

    override var isUppercasedTitle: Bool {
        get {
            return true
        }
        set {
            super.isUppercasedTitle = true
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        setGradientTopBar(mainColor: UIColor.main.peacockBlue, addedStatusView: AppModel.sharedManager().isLoggedin)


        ownerKeyLabel.text = ownerKey
        ownerKeyTitleLabel.text = Localizable.shared.strings.addDots(value: Localizable.shared.strings.key_code.uppercased())
        ownerKeyTitleLabel.letterSpacing = 1.5
        
        if AppModel.sharedManager().isRestoreFlow {            
            title = Localizable.shared.strings.owner_key

            copyView.isHidden = true
            copyNextView.isHidden = false
            
            noticeLabel.text = Localizable.shared.strings.paste_owner_key + "\n\n" + Localizable.shared.strings.after_paste_owner_key
        }
        else{
            title = Localizable.shared.strings.show_owner_key
        }
    }
    
    @IBAction func onCopy(sender :UIButton) {
        UIPasteboard.general.string = ownerKey
        
        ShowCopied(text: Localizable.shared.strings.ownerkey_copied)
        
        if !AppModel.sharedManager().isRestoreFlow {
            back()
        }
    }
    
    @IBAction func onNext(sender :UIButton) {
        let vc = RestoreNodeViewController()
        pushViewController(vc: vc);
    }
}
