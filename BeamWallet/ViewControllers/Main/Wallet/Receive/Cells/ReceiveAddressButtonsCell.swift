//
// ReceiveAddressButtonsCell.swift
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

class ReceiveAddressButtonsCell: BaseCell {
    @IBOutlet private var infoLabel: UILabel!

    weak var delegate: BMCellProtocol?

    override func awakeFromNib() {
        super.awakeFromNib()
        
        allowHighlighted = false

        selectionStyle = .none
        
        if Settings.sharedManager().isDarkMode {
            infoLabel.textColor = UIColor.main.steel;
        }
        else {
            infoLabel.textColor = UIColor.main.blueyGrey
        }
    }


    public func setText(text:String) {
        infoLabel.text = text
    }

    @IBAction func onShare(sender: UIButton) {
        delegate?.onClickShare?()
    }
}


