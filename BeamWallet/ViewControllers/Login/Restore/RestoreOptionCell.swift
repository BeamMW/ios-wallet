//
// RestoreOptionCell.swift
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

class RestoreOptionCell: UITableViewCell {

    weak var delegate: BMCellProtocol?

    @IBOutlet private weak var iconView: UIImageView!
    @IBOutlet private weak var titleLabel: UILabel!
    @IBOutlet private weak var detailLabel: UILabel!
    @IBOutlet private weak var checkButton: UIButton!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        selectionStyle = .none
    }
    
    @IBAction func onCheck(sender :UIButton) {
        self.delegate?.onRightButton?(self)
    }
}

extension RestoreOptionCell: Configurable {
    
    func configure(with options: (icon: UIImage?, title:String, detail:String, selected:Bool)) {
        iconView.image = options.icon
        titleLabel.text = options.title.uppercased()
        detailLabel.text = options.detail
        checkButton.isSelected = options.selected
        titleLabel.letterSpacing = 1.5
    }
}
