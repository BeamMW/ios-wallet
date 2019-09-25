//
// SettingsCell.swift
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

protocol SettingsCellDelegate: AnyObject {
    func onClickSwitch(value: Bool, cell: SettingsCell)
}

class SettingsCell: BaseCell {
    weak var delegate: SettingsCellDelegate?
    
    @IBOutlet private var titleLabel: UILabel!
    @IBOutlet private var detailLabel: UILabel!
    @IBOutlet private var mainView: UIView!
    @IBOutlet private var switchView: UISwitch!
    @IBOutlet private var arrowView: UIImageView!
    @IBOutlet private var titleXOffset: NSLayoutConstraint!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        switchView.tintColor = Settings.sharedManager().target == Testnet ? UIColor(hexString: "#0F0D17") : UIColor.main.marine
        switchView.backgroundColor = Settings.sharedManager().target == Testnet ? UIColor(hexString: "#0F0D17") : UIColor.main.marine
        
        backgroundColor = UIColor.main.marineThree
        mainView.backgroundColor = UIColor.main.marineThree
        
        let selectedView = UIView()
        selectedView.backgroundColor = UIColor.black.withAlphaComponent(0.2)
        selectedBackgroundView = selectedView
    }
    
    @IBAction func onSwitch(sender: UISwitch) {
        delegate?.onClickSwitch(value: sender.isOn, cell: self)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        switchView.layer.cornerRadius = switchView.frame.height / 2
    }
}

extension SettingsCell: Configurable {
    func configure(with item: SettingsViewModel.SettingsItem) {
        titleLabel.textColor = UIColor.white
        
        titleLabel?.text = item.title
        detailLabel?.text = item.detail
        
        if let isSwitch = item.isSwitch {
            switchView.isOn = isSwitch
            switchView.isHidden = false
            
            selectionStyle = .none
        }
        else {
            switchView.isHidden = true
            
            selectionStyle = item.id == 0 ? .none : .default
        }
        
        if let category = item.category {
            arrowView.isHidden = false
            titleXOffset.constant = 25
            titleLabel.textColor = UIColor(hexString: category.color)
        }
        else {
            if item.id == 5 || item.id == 6 || item.id == 7 || item.id == 1 || item.id == 8 || item.id == 12 || item.id == 13 || item.id == 15 {
                arrowView.isHidden = false
                titleXOffset.constant = 25
            }
            else {
                arrowView.isHidden = true
                titleXOffset.constant = 15
            }
        }
        
        if item.id == 5, Settings.sharedManager().connectToRandomNode {
            isUserInteractionEnabled = false
            mainView.alpha = 0.8
            arrowView.isHidden = true
            titleXOffset.constant = 15
        }
        else {
            isUserInteractionEnabled = true
            mainView.alpha = 1
        }
    }
}
