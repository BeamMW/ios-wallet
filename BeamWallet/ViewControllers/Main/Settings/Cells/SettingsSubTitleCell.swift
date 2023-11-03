//
// SettingsSubTitleCell.swift
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

class SettingsSubTitleCell: BaseCell {
    weak var delegate: SettingsCellDelegate?
    
    @IBOutlet private weak var titleLabel: UILabel!
    @IBOutlet private weak var detailLabel: UILabel!
    @IBOutlet private weak var mainView: UIView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
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
    
    func configure(with item: SettingsViewModel.SettingsItem, search:String) {
        titleLabel.textColor = UIColor.white
        titleLabel?.numberOfLines = 0
        
        if let attr = item.titleAttributed {
            titleLabel?.attributedText = attr
            titleLabel?.numberOfLines = 0
        }
        else {
            if search.isEmpty {
                titleLabel?.text = item.title
            }
            else {
                let detail = NSMutableAttributedString(string: item.title ?? "")
                let rangeName = (detail.string.lowercased() as NSString).range(of: search.lowercased())
                detail.addAttribute(NSAttributedString.Key.foregroundColor, value: UIColor.main.brightSkyBlue, range: rangeName)
                titleLabel?.attributedText = detail
            }
        }
        
        detailLabel?.text = item.detail
    }
}
