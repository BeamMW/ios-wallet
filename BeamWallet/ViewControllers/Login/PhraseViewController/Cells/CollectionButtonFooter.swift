//
//  CollectionButtonFooter.swift
//  BeamWallet
//
//  Created by Denis on 10/18/19.
//  Copyright © 2019 Denis. All rights reserved.
//

import Foundation

class CollectionButtonFooter: UICollectionReusableView {
    static let reuseIdentifier = "CollectionButtonFooter"
    static let nib = "CollectionButtonFooter"

    @IBOutlet var btn1: BMButton!
    @IBOutlet var btn2: BMButton!


    public func setData(event: SeedPhraseViewController.EventType) {
        switch event {
        case .confirm:
            btn1.setTitle(Localizable.shared.strings.next.lowercased(), for: .normal)
            btn1.setImage(IconNextBlue(), for: .normal)
            btn2.isHidden = true
        case .restore:
            btn1.setTitle(Localizable.shared.strings.next.lowercased(), for: .normal)
            btn1.setImage(IconNextBlue(), for: .normal)
            if Settings.sharedManager().target != Mainnet {
                btn2.setTitle(Localizable.shared.strings.paste.lowercased(), for: .normal)
                btn2.setImage(IconCopyWhite(), for: .normal)
            }
            else {
                btn2.isHidden = true
            }
        case .intro:
            btn1.setTitle(Localizable.shared.strings.understand, for: .normal)
            btn1.setImage(IconDoneBlue(), for: .normal)
            btn2.isHidden = true
        case .display, .onlyDisplay:
            btn2.setTitle(Localizable.shared.strings.i_will_later, for: .normal)
            break
        }
        
        if Settings.sharedManager().isDarkMode {
            btn2.setBackgroundColor(color: UIColor.main.marineThree, forState: .normal)
            btn2.setTitleColor(UIColor.white, for: .normal)
        }
    }

    @IBAction private func onButton(sender: UIButton) {}
}
