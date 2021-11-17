//
// BMMultiLinesCell.swift
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

class BMDetailAmountCell: BaseCell {

    @IBOutlet weak private var nameLabel: UILabel!
    @IBOutlet weak private var detailLabel: UILabel!
    @IBOutlet weak private var secondDetailLabel: UILabel!
    @IBOutlet weak private var iconView: AssetIconView!

    @IBOutlet weak private var stackView: UIStackView!
    @IBOutlet weak private var topOffset: NSLayoutConstraint!
    
    @IBOutlet weak private var assetIdView: UIView!
    @IBOutlet weak private var assetIdLabel: UILabel!

    var assetId:UInt64 = 0
    
    public var increaseSpace = false {
        didSet {
            if increaseSpace {
     
            }
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        selectionStyle = .none
        selectedBackgroundView = nil
        
        nameLabel.font = BoldFont(size: 14)
        nameLabel.textColor = UIColor.main.blueyGrey
        nameLabel.textAlignment = .left
        nameLabel.adjustFontSize = true
        
        assetIdView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(onAssetIdClicked)))
    }
    
    @objc func onAssetIdClicked() {
        if let url = URL(string: Settings.sharedManager().assetBlockchainUrl(Int32(self.assetId))) {
            UIApplication.getTopMostViewController()?.openUrl(url: url)
        }
    }
    
    func addDots() {
        let text = (self.nameLabel.text ?? "") + ":"
        self.nameLabel.text = text
        nameLabel.letterSpacing = 2
    }
    
    func configure(asset:BMAsset?, item:BMThreeLineItem) {
        nameLabel.text = item.title.uppercased()
        nameLabel.letterSpacing = 2
        
        detailLabel.textColor = item.detailColor
        detailLabel.text = item.detail
        secondDetailLabel.text = item.subDetail

        if let asset = asset {
            self.assetId = asset.assetId
            
            if asset.assetId == 0 {
                assetIdView.isHidden = true
            }
            else {
                assetIdView.isHidden = false
            }
            assetIdLabel.text = "\(asset.assetId)"
            iconView.setAsset(asset)
        }
        else {
            assetIdView.isHidden = true
        }
        
        stackView.spacing = 10
        topOffset.constant = 15
        
        if item.subDetail.isEmpty {
            secondDetailLabel.isHidden = true
        }
        else {
            secondDetailLabel.isHidden = false
        }
    }
}
