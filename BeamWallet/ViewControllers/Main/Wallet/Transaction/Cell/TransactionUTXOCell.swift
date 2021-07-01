//
// TransactionUTXOCell.swift
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

class TransactionUTXOCell: BaseCell {

    @IBOutlet weak private var amountLabel: UILabel!
    @IBOutlet weak private var statusIcon: UIImageView!
    @IBOutlet weak private var mainView: UIView!

    override func awakeFromNib() {
        super.awakeFromNib()
        
        selectionStyle = .none
        
        mainView.backgroundColor = UIColor.white.withAlphaComponent(0.05)
    }    
}

extension TransactionUTXOCell: Configurable {
    
    func configure(with utxo: BMUTXO) {        
        amountLabel.text = utxo.amountString
        
        switch utxo.statusString {
        case Localizable.shared.strings.spent:
            statusIcon.image = IconSendPink()
        case Localizable.shared.strings.total:
            statusIcon.image = IconUtxo()
        default:
            statusIcon.image = IconReceiveLightBlue()
        }
    }
}
