//
//  GeneralTransactionInfoCell.swift
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

class GeneralTransactionInfoCell: BaseCell {
    
    @IBOutlet weak private var titleLabel: UILabel!
    @IBOutlet weak private var detailLabel: BMCopyLabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        selectionStyle = .none
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
}

extension GeneralTransactionInfoCell: Configurable {
    
    func configure(with info:TransactionViewController.TransactionGeneralInfo) {
        titleLabel.text = info.text
        detailLabel.text = info.detail
        detailLabel.copyText = nil
        
        if info.failed {
            titleLabel.textColor = UIColor.main.red
            detailLabel.textColor = UIColor.main.red
        }
        else{
            titleLabel.textColor = UIColor.main.blueyGrey
            detailLabel.textColor = UIColor.white
        }
        
        if info.text == "Contact:" {
            let split = info.detail.split(separator: "\n")
            if split.count == 2 {
                let contact = split[0]
                
                let range = (info.detail as NSString).range(of: String(contact))
               
                let attributedString = NSMutableAttributedString(string:info.detail)
                attributedString.addAttribute(NSAttributedString.Key.font, value: UIFont(name: "SFProDisplay-Bold", size: 15) ?? UIFont.boldSystemFont(ofSize: 15) , range: range)
                detailLabel.attributedText = attributedString
            }
        }
        else if info.text == "Transaction ID: " {
            detailLabel.copyText = info.detail
            
            let text = info.detail + "\n" + "not stored on blockchain"
            let range = (text as NSString).range(of: String("not stored on blockchain"))
            
            let attributedString = NSMutableAttributedString(string:text)
            attributedString.addAttribute(NSAttributedString.Key.foregroundColor, value: UIColor.main.blueyGrey , range: range)
            detailLabel.attributedText = attributedString
        }
                
        detailLabel.isUserInteractionEnabled = info.canCopy
    }
}

