//
// CategoryPickerCell.swift
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


class CategoryPickerCell: BaseCell {
    
    @IBOutlet weak private var nameLabel: UILabel!
    @IBOutlet private weak var mainView: UIView!
    @IBOutlet private weak var arrowView: UIImageView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        backgroundColor = UIColor.main.marineTwo
        mainView.backgroundColor = UIColor.main.marineTwo
        
        let selectedView = UIView()
        selectedView.backgroundColor = UIColor.black.withAlphaComponent(0.2)
        self.selectedBackgroundView = selectedView
        
        arrowView.image = UIImage.init(named: "tick")?.withRenderingMode(.alwaysTemplate)
        arrowView.tintColor = UIColor.main.brightTeal
    }
}

extension CategoryPickerCell: Configurable {
    
    func configure(with options: (category: BMCategory, selected:Bool)) {
        arrowView.isHidden = !options.selected
        nameLabel.text = options.category.name
        nameLabel.textColor = UIColor.init(hexString: options.category.color)
    }
}
