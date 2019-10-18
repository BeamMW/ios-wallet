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
    
    @IBOutlet weak var btn1: BMButton!
    @IBOutlet weak var btn2: BMButton!

    public func setData(event:SeedPhraseViewController.EventType) {
        switch event {
        case .confirm:
            btn1.setTitle(Localizable.shared.strings.next.lowercased(), for: .normal)
            btn1.setImage(IconNextBlue(), for: .normal)
            btn2.isHidden = true
        case .restore:
            btn1.setTitle(Localizable.shared.strings.next.lowercased(), for: .normal)
            btn1.setImage(IconNextBlue(), for: .normal)
            btn2.isHidden = true
        case .display:
            break
        }
    }
    
    @IBAction private func onButton(sender: UIButton) {

    }
}
