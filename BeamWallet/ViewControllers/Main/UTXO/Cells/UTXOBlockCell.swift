//
// UTXOBlockCell.swift
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

class UTXOBlockCell: UITableViewCell {

    @IBOutlet weak private var heightLabel: UILabel!
    @IBOutlet weak private var hashLabel: UILabel!
    @IBOutlet weak private var hashTitleLabel: UILabel!
    @IBOutlet weak private var heightTitleLabel: UILabel!
    @IBOutlet weak private var mainView: UIView!

    override func awakeFromNib() {
        super.awakeFromNib()
        
        mainView.backgroundColor = UIColor.white.withAlphaComponent(0.05)

        hashTitleLabel.text = Localizable.shared.strings.addDots(value: Localizable.shared.strings.block_hash).uppercased()
        heightTitleLabel.text = Localizable.shared.strings.addDots(value: Localizable.shared.strings.blockchain_height).uppercased()
        hashTitleLabel.letterSpacing = 1.5
        heightTitleLabel.letterSpacing = 1.5
        
        selectionStyle = .none
    }
}

extension UTXOBlockCell: Configurable {
    
    func configure(with status:BMWalletStatus?) {
        
        if let walletStatus = status {
            heightLabel.text = walletStatus.currentHeight
            hashLabel.text = walletStatus.currentStateHash
        }
        else{
            heightLabel.text = String.empty()
            hashLabel.text = String.empty()
        }
    }
}

