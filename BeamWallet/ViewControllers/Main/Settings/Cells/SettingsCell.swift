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
    
    @IBOutlet private weak var titleLabel: UILabel!
    @IBOutlet private weak var detailLabel: UILabel!
    @IBOutlet private weak var mainView: UIView!
    @IBOutlet private weak var switchView: UISwitch!
    @IBOutlet private weak var arrowView: UIImageView!
    @IBOutlet private weak var titleXOffset: NSLayoutConstraint!
    @IBOutlet private weak var iconView: UIImageView!
    @IBOutlet private weak var titleLeftOffset: NSLayoutConstraint!

    override func awakeFromNib() {
        super.awakeFromNib()
        
        switchView.tintColor = (Settings.sharedManager().target == Testnet || Settings.sharedManager().isDarkMode) ? UIColor(hexString: "#0F0D17") : UIColor.main.marine
        switchView.backgroundColor = (Settings.sharedManager().target == Testnet || Settings.sharedManager().isDarkMode) ? UIColor(hexString: "#0F0D17")  : UIColor.main.marine
        
        changeBacgkroundView()
        
        detailLabel.textColor = Settings.sharedManager().isDarkMode ? UIColor.main.steel : UIColor.main.steelGrey
    }
    
    override func changeBacgkroundView() {
        super.changeBacgkroundView()
        
        backgroundColor = UIColor.clear
        contentView.backgroundColor = UIColor.clear
        mainView.backgroundColor = UIColor.main.cellBackgroundColor
                
        detailLabel.textColor = Settings.sharedManager().isDarkMode ? UIColor.main.steel : UIColor.main.steelGrey
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
        
        if let attr = item.titleAttributed {
            titleLabel?.attributedText = attr
            titleLabel?.numberOfLines = 0
        }
        else {
            titleLabel?.text = item.title
            titleLabel?.numberOfLines = 1
        }
        
        detailLabel?.text = item.detail
        
        if let isSwitch = item.isSwitch {
            switchView.isOn = isSwitch
            switchView.isHidden = false
            
            selectionStyle = .none
        }
        else {
            switchView.isHidden = true
            
        }
        
        if item.type == .remove_wallet {
            titleLabel.textColor = UIColor.main.red
        }
        if item.hasArrow {
            arrowView.isHidden = false
            titleXOffset.constant = 25
        }
        else {
            arrowView.isHidden = true
            titleXOffset.constant = 15
        }
        
        if item.type == .ip_port , Settings.sharedManager().connectToRandomNode {
            isUserInteractionEnabled = false
            mainView.alpha = 0.8
            arrowView.isHidden = true
            titleXOffset.constant = 15
        }
        else {
            isUserInteractionEnabled = true
            mainView.alpha = 1
        }
        
        if let icon = item.icon {
            iconView.isHidden = false
            titleLeftOffset.constant = 50
            if item.type != .remove_wallet {
                iconView.image = icon.maskWithColor(color: Settings.sharedManager().isDarkMode ? UIColor.main.steel : UIColor.main.steelGrey)
            }
            else{
                iconView.image = icon
            }
        }
        else{
            iconView.isHidden = true
            titleLeftOffset.constant = 15
        }
    }
}
