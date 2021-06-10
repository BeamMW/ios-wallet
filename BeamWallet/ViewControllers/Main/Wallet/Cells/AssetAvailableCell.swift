//
// AssetAvailableCell.swift
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

class AssetAvailableCell: UITableViewCell {

    @IBOutlet weak private var mainView: BMGradientView!
    @IBOutlet weak private var balanceLabel: UILabel!
    @IBOutlet weak private var secondBalanceLabel: UILabel!
    @IBOutlet weak private var lockedLabel: UILabel!
    @IBOutlet weak private var lockedView: UIView!
    @IBOutlet weak private var iconView: AssetIconView!
    
    @IBOutlet weak private var topOffset: NSLayoutConstraint!
    @IBOutlet weak private var botOffset: NSLayoutConstraint!

    override func awakeFromNib() {
        super.awakeFromNib()
  
        let selectedView = UIView()
        selectedView.backgroundColor = UIColor.main.selectedColor
        self.selectedBackgroundView = selectedView
    }


    public func setAsset(_ asset:BMAsset) {
        iconView.setAsset(asset)
        
        mainView.gradientLayer.colors = [
            UIColor(hexString: asset.color).withAlphaComponent(0.3).cgColor,
            UIColor.main.cellBackgroundColor.cgColor]
        
        mainView.gradientLayer.startPoint = CGPoint(x: 0.0, y: 0.5)
        mainView.gradientLayer.endPoint = CGPoint(x: 1.0, y: 0.5)
        
        balanceLabel.text = asset.isBeam() ? String.currency(value: asset.realAmount) : String.currency(value: asset.realAmount, name: asset.unitName)
        secondBalanceLabel.text = ExchangeManager.shared().exchangeValueAsset(asset.realAmount, assetID: asset.assetId)
        
        if asset.locked() > 0 {
            lockedLabel.text = asset.isBeam() ? String.currency(value: asset.realLocked())
                : String.currency(value: asset.realLocked(), name: asset.unitName)
            
            lockedView.isHidden = false
            topOffset.constant = 18
            botOffset.constant = 18
        }
        else {
            lockedView.isHidden = true
            topOffset.constant = 23
            botOffset.constant = 23
        }
    }
    
}
