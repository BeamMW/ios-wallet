//
// BMEmptyCell.swift
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

class BMEmptyCell: BaseCell {

    @IBOutlet weak private var titleLabel: UILabel!
    @IBOutlet weak private var mainView: UIView!
    @IBOutlet weak private var iconView: UIImageView!


    override func awakeFromNib() {
        super.awakeFromNib()
        
        contentView.backgroundColor = UIColor.clear
        backgroundColor = UIColor.clear

        selectionStyle = .none
        
        isUserInteractionEnabled = false
    }
}

extension BMEmptyCell: Configurable {
    
    func configure(with options: (text:String, image:UIImage?)) {
        titleLabel.text = options.text
        iconView.isHidden = (options.image == nil)
        iconView.image = options.image
    }
}
