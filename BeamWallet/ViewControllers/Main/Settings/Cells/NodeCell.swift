//
// NodeCell.swift
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

class NodeCell: UITableViewCell {

    @IBOutlet weak private var checkButton: UIButton!
    @IBOutlet weak private var nameLabel: UILabel!
    @IBOutlet weak private var infoLabel: UILabel!
    @IBOutlet weak private var iconView: UIImageView!

    override func awakeFromNib() {
        super.awakeFromNib()
       
        if Settings.sharedManager().isDarkMode {
            nameLabel.textColor = UIColor.main.steel;
        }
        
        selectionStyle = .none
    }
    
    func configure(_ item: SelectNode) {
        let value = "\(item.title.uppercased()) (\(item.subTitle.lowercased()))"
        nameLabel.setLetterSpacingOnly(value: 2.0, title: value, letter: item.title.uppercased())
        infoLabel.text = item.detail
        iconView.image = UIImage(named: item.icon)
        checkButton.isSelected = item.selected
        checkButton.isUserInteractionEnabled = false
    }
}
