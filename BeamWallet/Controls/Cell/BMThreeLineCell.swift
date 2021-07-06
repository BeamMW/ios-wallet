//
// BMThreeLineCell.swift
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

class BMThreeLineCell: BaseCell {

    @IBOutlet weak private var nameLabel: UILabel!
    @IBOutlet weak private var detailLabel: UILabel!
    @IBOutlet weak private var subDetailLabel: UILabel!
    @IBOutlet weak private var arrow: UIImageView!
    @IBOutlet weak private var mainView: UIView!
    @IBOutlet weak var accessoryButton: UIButton!

    override func awakeFromNib() {
        super.awakeFromNib()

        allowHighlighted = false

        mainView.backgroundColor = UIColor.main.cellBackgroundColor
        
        selectionStyle = .none
    }
    
    func setExpand(value:Bool) {
        let angle:Double = value ? 0 : -180
        arrow.transform = CGAffineTransform(rotationAngle: CGFloat(angle * Double.pi/180))
    }
    
    @IBAction private func onAccessory() {
        
    }
}

extension BMThreeLineCell: Configurable {

    func configure(with item:BMThreeLineItem) {
        nameLabel.text = item.title
        detailLabel.text = item.detail
        subDetailLabel.text = item.subDetail
        
        nameLabel.textColor = item.titleColor
        detailLabel.textColor = item.detailColor
        subDetailLabel.textColor = item.subDetailColor
        
        nameLabel.font = item.titleFont
        detailLabel.font = item.detailFont
        subDetailLabel.font = item.subDetailFont
        
        arrow.isHidden = !item.hasArrow
        subDetailLabel.isHidden = item.subDetail.isEmpty
        
        if let accessory = item.accessoryName, !accessory.isEmpty {
            accessoryButton.isHidden = false
            accessoryButton.setTitle(accessory, for: .normal)
        }
        else {
            accessoryButton.isHidden = true
        }
    }
}
