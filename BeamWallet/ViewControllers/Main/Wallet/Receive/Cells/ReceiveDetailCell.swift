//
// ReceiveDetailCell.swift
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

class ReceiveDetailCell: BaseCell {
    
    @IBOutlet weak private var arrowIcon: UIImageView!
    @IBOutlet weak private var nameLabel: UILabel!
    @IBOutlet weak private var valueLabel: UILabel!

    override func awakeFromNib() {
        super.awakeFromNib()
       
        selectionStyle = .default
        
        let selectedView = UIView()
        selectedView.backgroundColor = contentView.backgroundColor
        selectedBackgroundView = selectedView
        
        arrowIcon.highlightedImage = IconNextArrow()?.maskWithColor(color: UIColor.main.steelGrey)
    }
}

extension ReceiveDetailCell: Configurable {
    
    func configure(with options: (title:String, value:String, valueColor: UIColor)) {
        valueLabel.text = options.value
        valueLabel.textColor = options.valueColor
        
        nameLabel.text = options.title
        nameLabel.letterSpacing = 2
    }
}

