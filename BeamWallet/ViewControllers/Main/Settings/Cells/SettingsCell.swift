//
//  SettingsCell.swift
//  BeamWallet
//
//  Created by Denis on 4/4/19.
//  Copyright © 2019 Denis. All rights reserved.
//

import UIKit

protocol SettingsCellDelegate: AnyObject {
    func onClickSwitch(value:Bool, cell:SettingsCell)
}


class SettingsCell: BaseCell {

    weak var delegate: SettingsCellDelegate?

    @IBOutlet private weak var titleLabel: UILabel!
    @IBOutlet private weak var detailLabel: UILabel!
    @IBOutlet private weak var mainView: UIView!
    @IBOutlet private weak var switchView: UISwitch!
    @IBOutlet private weak var botLineView: UIView!
    @IBOutlet private weak var arrowView: UIImageView!
    @IBOutlet private weak var titleXOffset: NSLayoutConstraint!

    override func awakeFromNib() {
        super.awakeFromNib()
        
        backgroundColor = UIColor.clear
        mainView.backgroundColor = UIColor.main.marineTwo
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
    
    @IBAction func onSwitch(sender : UISwitch) {
        self.delegate?.onClickSwitch(value: sender.isOn, cell: self)
    }
}

extension SettingsCell: Configurable {
    
    func configure(with item:SettingsViewController.SettingsItem) {

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
        
        if item.id == 5 || item.id == 6 || item.id == 7 {
            arrowView.isHidden = false
            titleXOffset.constant = 25
        }
        else{
            arrowView.isHidden = true
            titleXOffset.constant = 15
        }
        
        botLineView.isHidden = item.position == SettingsViewController.SettingsItem.Position.midle
    }
}
