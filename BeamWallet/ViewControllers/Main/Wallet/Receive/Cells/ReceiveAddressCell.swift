//
// ReceiveAddressCell.swift
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

class ReceiveAddressCell: BaseCell {

    @IBOutlet weak private var addressLabel: UILabel!
    @IBOutlet weak private var line: UIView!
    @IBOutlet weak private var titleLabel: UILabel!

    override func awakeFromNib() {
        super.awakeFromNib()
        
        selectionStyle = .none
        
        line.backgroundColor = Settings.sharedManager().target == Testnet ? UIColor.main.marineTwo : UIColor.main.darkSlateBlue
    }
}

extension ReceiveAddressCell: Configurable {
    
    func configure(with options: (hideLine: Bool, address:BMAddress?, title:String?)) {
        addressLabel.text = options.address?.walletId
        line.isHidden = options.hideLine
        
        if let title = options.title {
            titleLabel.text = title
            titleLabel.letterSpacing = 1.5
        }
    }
}
