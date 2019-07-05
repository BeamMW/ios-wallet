//
// AddressExpireCell.swift
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

class AddressExpiresCell: BaseCell {

    @IBOutlet weak private var expireLabel: UILabel!
    @IBOutlet weak private var dateLabel: UILabel!
    @IBOutlet weak private var mainView: UIView!

    override func awakeFromNib() {
        super.awakeFromNib()
        
        selectionStyle = .default
        
        backgroundColor = UIColor.clear
       
        mainView.backgroundColor = UIColor.main.marineThree
        
        let selectedView = UIView()
        selectedView.backgroundColor = UIColor.black.withAlphaComponent(0.2)
        self.selectedBackgroundView = selectedView
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
    
}

extension AddressExpiresCell: Configurable {
    
    func configure(with address: BMAddress) {

        if address.isExpired() || address.isNowActive {
            if(address.isNowActiveDuration == 0)
            {
                expireLabel.text = Localizable.shared.strings.never.lowercased()
                dateLabel.isHidden = true
            }
            else{
                expireLabel.text = Localizable.shared.strings.in_24_hours.lowercased()
                dateLabel.text = address.expireNowDate()
                dateLabel.isHidden = false
            }
        }
        else{
            if address.isNowExpired {
                expireLabel.text = Localizable.shared.strings.now.lowercased()
                dateLabel.text = address.nowDate()
                dateLabel.isHidden = false
            }
            else{
                if(address.duration == 0)
                {
                    expireLabel.text = Localizable.shared.strings.never.lowercased()
                    dateLabel.isHidden = true
                }
                else{
                    expireLabel.text = Localizable.shared.strings.in_24_hours.lowercased()
                    dateLabel.text = address.formattedDate()
                    dateLabel.isHidden = false
                }
            }
        }
    }
}

extension AddressExpiresCell: DynamicContentHeight {
    
    static func height() -> CGFloat {
        return 80
    }
}
