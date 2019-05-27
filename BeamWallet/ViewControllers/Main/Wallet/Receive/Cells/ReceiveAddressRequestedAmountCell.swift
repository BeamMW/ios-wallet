//
// ReceiveAddressRequestedAmountCell.swift
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

class ReceiveAddressRequestedAmountCell: BaseCell {

    weak var delegate: ReceiveCellProtocol?

    @IBOutlet weak private var amountLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        selectionStyle = .none
    }
    
    @IBAction func onRemove(sender :UIButton) {
        delegate?.onClickRemoveRequest?()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
    }
}

extension ReceiveAddressRequestedAmountCell: Configurable {
    
    func configure(with amount: String?) {
        if let a = amount {
            amountLabel.text = LocalizableStrings.beam_amount(a)
        }
        else{
            amountLabel.text = String.empty()
        }
    }
}

