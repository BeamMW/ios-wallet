//
//  AddressExpireCell.swift
//  BeamWallet
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

protocol AddressExpireCellDelegate: AnyObject {
    func onShowPopover()
}


class AddressExpireCell: BaseCell {

    weak var delegate: AddressExpireCellDelegate?

    @IBOutlet weak private var expireLabel: UILabel!
    @IBOutlet weak private var dateLabel: UILabel!
    @IBOutlet weak private var lineView: UIView!
    @IBOutlet weak private var arrowView: UIImageView!
    @IBOutlet weak private var expireView: UIView!

    override func awakeFromNib() {
        super.awakeFromNib()
        
        selectionStyle = .none
        
        lineView.backgroundColor = UIColor.white.withAlphaComponent(0.1)
        
        let tapGesture = UITapGestureRecognizer(target: self,
                                                action: #selector(hideKeyboard))
        expireView.addGestureRecognizer(tapGesture)
    }
    
    
    @objc private func hideKeyboard() {
        self.delegate?.onShowPopover()
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
    
}

extension AddressExpireCell: Configurable {
    
    func configure(with address: BMAddress) {
        lineView.alpha = 1
        arrowView.alpha = 1
        expireView.isUserInteractionEnabled = true
        
        if address.isExpired() {
            if(address.isNowActiveDuration == 0)
            {
                expireLabel.text = "never"
                dateLabel.text = ""
            }
            else{
                expireLabel.text = "in 24 hours"
                dateLabel.text = address.expireNowDate()
            }
        }
        else{
            if address.isNowExpired {
                expireView.isUserInteractionEnabled = false

                lineView.alpha = 0
                arrowView.alpha = 0

                expireLabel.text = "now"
                dateLabel.text = address.nowDate()
            }
            else{
                
                if(address.duration == 0)
                {
                    expireLabel.text = "never"
                    dateLabel.text = ""
                }
                else{
                    expireLabel.text = "in 24 hours"
                    dateLabel.text = address.formattedDate()
                }
            }
        }
    }
}
