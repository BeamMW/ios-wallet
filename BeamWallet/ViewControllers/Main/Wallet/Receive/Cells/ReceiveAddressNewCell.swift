//
// ReceiveAddressNewCell.swift
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

class ReceiveAddressNewCell: BaseCell {
    
    @IBOutlet weak private var addressLabel: UILabel!
    @IBOutlet weak private var line: UIView!
    
    @IBOutlet weak private var nameLabel: UILabel!
    @IBOutlet weak private var categoryLabel: UILabel!

    override func awakeFromNib() {
        super.awakeFromNib()
        
        selectionStyle = .none
        
        line.backgroundColor = Settings.sharedManager().target == Testnet ? UIColor.main.marineTwo : UIColor.main.darkSlateBlue
    }
}

extension ReceiveAddressNewCell: Configurable {
    
    func configure(with options: (hideLine: Bool, address:BMAddress?)) {
        addressLabel.text = options.address?.walletId
        line.isHidden = options.hideLine
        
        if let address = options.address {
            categoryLabel.isHidden = false
            nameLabel.isHidden = false
            
            if let category = AppModel.sharedManager().findCategory(byId: address.category) {
                categoryLabel.textColor = UIColor.init(hexString: category.color)
                categoryLabel.text = category.name
            }
            else{
                categoryLabel.isHidden = true
                nameLabel.isHidden = true
            }
            
            nameLabel.text = address.label
        }
        else{
            categoryLabel.isHidden = true
            nameLabel.isHidden = true
        }
    }
}
