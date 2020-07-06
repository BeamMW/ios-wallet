//
// BMExpandCell.swift
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

class BMExpandCell: BaseCell {

    @IBOutlet weak private var arrowIcon: UIImageView!
    @IBOutlet weak private var nameLabel: UILabel!
    @IBOutlet weak private var mainView: NonDisappearingView!

    private var isExpand = false
    
    weak var delegate: BMCellProtocol?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        mainView.backgroundColor = UIColor.main.marineThree

        nameLabel.highlightedTextColor = UIColor.main.steelGrey
        arrowIcon.highlightedImage = IconDownArrow()?.maskWithColor(color: UIColor.main.steelGrey)

        selectionStyle = .default
        
        let selectedView = UIView()
        selectedView.backgroundColor = UIColor.clear
        selectedBackgroundView = selectedView
        
        if Settings.sharedManager().isDarkMode {
            nameLabel.textColor = UIColor.main.steel;
        }
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        if selected {
            isExpand = !isExpand
            
            let angle:Double = isExpand ? 0 : -180
            arrowIcon.transform = CGAffineTransform(rotationAngle: CGFloat(angle * Double.pi/180))
            
            UIView.animate(withDuration: 0.3) {
                self.arrowIcon.transform = CGAffineTransform(rotationAngle: CGFloat(angle * Double.pi/180))
            }
            
            self.delegate?.onExpandCell?(self)
        }
    }
    
    public func setColor(_ color: UIColor) {
        nameLabel.textColor = color
    }
}

extension BMExpandCell: Configurable {
    
    func configure(with options: (expand: Bool, title:String)) {
        isExpand = options.expand
        nameLabel.text = options.title
        nameLabel.letterSpacing = 2
        
        let angle:Double = isExpand ? 0 : -180
        arrowIcon.transform = CGAffineTransform(rotationAngle: CGFloat(angle * Double.pi/180))
    }
}
