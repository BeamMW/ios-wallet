//
// BMPickedAddressCell.swift
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

class BMPickedAddressCell: BaseCell {
    
    @IBOutlet weak private var addressLabel: UILabel!
    @IBOutlet weak private var nameLabel: UILabel!
    @IBOutlet weak private var button: BMButton!

    weak var delegate: BMCellProtocol?

    override func awakeFromNib() {
        super.awakeFromNib()
        
        selectionStyle = .none
        
       // contentView.backgroundColor = UIColor.main.marineTwo.withAlphaComponent(0.2)
    }
    
    @IBAction func onChange(sender :UIButton) {
        delegate?.onRightButton?(self)
    }
}

extension BMPickedAddressCell: Configurable {
    
    func configure(with options: (hideLine: Bool, address:BMAddress?, title:String?)) {
        addressLabel.text = options.address?.walletId
        
        if options.title != nil {
            nameLabel.text = options.title
        }
        
        if options.title == LocalizableStrings.outgoing || options.title == LocalizableStrings.outgoing_address {
            button.setTitleColor(UIColor.main.heliotrope, for: .normal)
            button.setTitleColor(UIColor.main.heliotrope.withAlphaComponent(0.3), for: .highlighted)
            button.layer.borderColor = UIColor.main.heliotrope.cgColor
            button.setImage(IconShufflePink(), for: .normal)
            button.setBackgroundColor(color: UIColor.main.heliotrope.withAlphaComponent(0.3), forState: .highlighted)
        }
    }
}
