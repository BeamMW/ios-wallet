//
// SendAllCell.swift
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

class SendAllCell: BaseCell {

    @IBOutlet weak private var amountLabel: UILabel!
    @IBOutlet weak private var allButton: BMButton!

    weak var delegate: BMCellProtocol?

    override func awakeFromNib() {
        super.awakeFromNib()
        
        selectionStyle = .none
    }
    
    @IBAction func onSendAll(sender :UIButton) {
        delegate?.onRightButton?(self)
    }
}

extension SendAllCell: Configurable {
    
    func configure(with amount:String) {
        amountLabel.text = amount + LocalizableStrings.beam
        allButton.setBackgroundColor(color: UIColor.main.heliotrope.withAlphaComponent(0.3), forState: .highlighted)
    }
}
