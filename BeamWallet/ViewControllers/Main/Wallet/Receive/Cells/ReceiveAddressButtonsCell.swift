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
        
        selectionStyle = .none
    }


    public func setMaxPrivacy(_ value:Bool) {
        if value {
            infoLabel.text = Localizable.shared.strings.receive_notice_max_privacy
        }
        else {
            infoLabel.text = Localizable.shared.strings.receive_notice
        }
    }

    @IBAction func onShare(sender: UIButton) {
        delegate?.onClickShare?()
    }
}


