//
// BMPickerCell.swift
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


protocol BMPickerCellDelegate: AnyObject {
    func onClickSwitch(value: Bool, cell: BMPickerCell)
}


class BMPickerCell: BaseCell {
    
    weak var delegate: BMPickerCellDelegate?

    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var detailLabel: UILabel!
    @IBOutlet weak var mainView: UIView!
    @IBOutlet private weak var arrowView: UIImageView!
    @IBOutlet weak var switchView: UISwitch!

    public var customBackgroundColor = false
    
    @IBOutlet var topOffset: NSLayoutConstraint?
    @IBOutlet var topSwitchOffset: NSLayoutConstraint?
    @IBOutlet var botOffset: NSLayoutConstraint?

    override func awakeFromNib() {
        super.awakeFromNib()
        
        backgroundColor = UIColor.clear
        contentView.backgroundColor = UIColor.clear
        mainView.backgroundColor = UIColor.main.cellBackgroundColor
        
        arrowView?.image = Tick()?.withRenderingMode(.alwaysTemplate)
        arrowView?.tintColor = UIColor.main.brightTeal

        switchView?.onTintColor = UIColor.main.brightTeal
        switchView?.tintColor = (Settings.sharedManager().target == Testnet || Settings.sharedManager().isDarkMode) ? UIColor(hexString: "#0F0D17") : UIColor.main.marine
      //  switchView?.backgroundColor = (Settings.sharedManager().target == Testnet || Settings.sharedManager().isDarkMode) ? UIColor(hexString: "#0F0D17") : UIColor.main.marine
        
        detailLabel.textColor = UIColor.main.blueyGrey
    }
    
    
    func configure(data:BMPickerData) {
        titleLabel.text = data.title
        detailLabel.isHidden = data.detail == nil
        detailLabel.text = data.detail
        
        if let color = data.titleColor {
            titleLabel.textColor = color
        }
        
        if(data.isSwitch) {
            switchView?.isOn = data.arrowType == BMPickerData.ArrowType.selected
        }
        else if data.multiplie {
            arrowView.image = (data.arrowType == BMPickerData.ArrowType.selected) ? CheckboxFull() : CheckboxEmptyNew()
        }
        else{
            arrowView.isHidden = data.arrowType != BMPickerData.ArrowType.selected
        }
    }
    
    @IBAction func onSwitch(sender: UISwitch) {
        delegate?.onClickSwitch(value: sender.isOn, cell: self)
    }
}
