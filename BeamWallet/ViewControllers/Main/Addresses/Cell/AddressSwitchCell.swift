//
//  AddressSwitchCell.swift
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

protocol AddressSwitchCellDelegate: AnyObject {
    func onSwitch(value:Bool)
}


class AddressSwitchCell: BaseCell {

    weak var delegate: AddressSwitchCellDelegate?

    @IBOutlet weak private var nameLabel: UILabel!
    @IBOutlet weak private var switchView: UISwitch!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        selectionStyle = .none
    }
    
    
    @IBAction func onSend(sender : UISwitch) {
        self.delegate?.onSwitch(value: sender.isSelected)
    }
}

extension AddressSwitchCell: Configurable {
    
    func configure(with options: (text: String, selected:Bool)) {
        switchView.isSelected = options.selected
        nameLabel.text = options.text
    }
}
