//
// AssetDropDownCell.swift
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

class AssetDropDownCell: BaseCell {
    
    @IBOutlet weak private var nameLabel: UILabel!
    @IBOutlet weak private var iconView: AssetIconView!
    @IBOutlet weak private var arrow: UIImageView!
    @IBOutlet weak private var mainView: UIView!

    override func awakeFromNib() {
        super.awakeFromNib()
        
        mainView.backgroundColor = UIColor.main.cellBackgroundColor

        selectionStyle = .none
    }
    
    public func setAsset(_ asset:BMAsset, expand:Bool) {
        iconView.setAsset(asset)
        
        if !asset.isBeam() {
            nameLabel.text = asset.unitName.uppercased()
        }
        else {
            nameLabel.text = Localizable.shared.strings.beam.uppercased()
        }
        
        let angle:Double = expand ? 0 : -180
        arrow.transform = CGAffineTransform(rotationAngle: CGFloat(angle * Double.pi/180))
    }
    
}
