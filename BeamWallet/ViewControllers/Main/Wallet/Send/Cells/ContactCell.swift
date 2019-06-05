//
// ContactCell.swift
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

class ContactCell: UITableViewCell {
    
    @IBOutlet weak private var mainView: UIView!
    @IBOutlet weak private var nameLabel: UILabel!
    @IBOutlet weak private var idLabel: UILabel!
    @IBOutlet weak private var categoryLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        let selectedView = UIView()
        selectedView.backgroundColor = UIColor.black.withAlphaComponent(0.2)
        self.selectedBackgroundView = selectedView
    }
}

extension ContactCell: Configurable {
    
    func configure(with options: (row: Int, contact:BMContact)) {
        let address = options.contact.address
        
        mainView.backgroundColor = (options.row % 2 == 0) ? UIColor.main.marineTwo.withAlphaComponent(0.35) : UIColor.main.marine
        
        backgroundColor = mainView.backgroundColor
        
        
        idLabel.text = address.walletId
        
        
        if address.label.isEmpty {
            nameLabel.text = " "
        }
        else{
            nameLabel.text = address.label
        }
        
        if let category = AppModel.sharedManager().findCategory(byId: address.category) {
            categoryLabel.textColor = UIColor.init(hexString: category.color)
            categoryLabel.text = category.name
        }
        else{
            categoryLabel.text = nil
        }
        
    }
}

extension ContactCell: DynamicContentHeight {
    
    static func height() -> CGFloat {
        return 70
    }
}
