//
//  MaxPrivacyDetailHeader.swift
//  BeamWallet
//
//  Created by Denis on 18.12.2020.
//  Copyright © 2020 Denis. All rights reserved.
//

import UIKit

class MaxPrivacyDetailHeader: UIView {
    @IBOutlet weak private var headerLabel1: UILabel!
    @IBOutlet weak private var headerLabel2: UILabel!
    
  
    override func awakeFromNib() {
        super.awakeFromNib()
        
        headerLabel1.textColor = Settings.sharedManager().isDarkMode ? UIColor.main.steel : UIColor.main.blueyGrey
        headerLabel2.textColor = Settings.sharedManager().isDarkMode ? UIColor.main.steel : UIColor.main.blueyGrey
        
        headerLabel1.text = Localizable.shared.strings.amount.uppercased()
        headerLabel2.text = Localizable.shared.strings.last_unlock_time.uppercased()
        
        headerLabel1.letterSpacing = 1.2
        headerLabel2.letterSpacing = 1.2
    }

}
