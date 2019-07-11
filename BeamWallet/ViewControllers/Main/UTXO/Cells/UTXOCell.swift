//
//  UTXOCell.swift
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

class UTXOCell: UITableViewCell {
    
    @IBOutlet weak private var mainView: UIView!
    @IBOutlet weak private var amountLabel: UILabel!
    @IBOutlet weak private var currencyIcon: UIImageView!
    @IBOutlet weak private var statusLabel: UILabel!
    @IBOutlet weak private var amountView: UIView!

    @IBOutlet weak private var transactionDateLabel: UILabel!
    @IBOutlet weak private var transactionCommentLabel: UILabel!
    @IBOutlet weak private var transactionIcon: UIImageView!
    @IBOutlet weak private var transactionIconHeight: NSLayoutConstraint!
    @IBOutlet weak private var transactionIconWidth: NSLayoutConstraint!

    @IBOutlet weak private var statusY: NSLayoutConstraint!
    @IBOutlet weak private var dateY: NSLayoutConstraint!

    override func awakeFromNib() {
        super.awakeFromNib()
        
        currencyIcon.image = IconSymbolBeam()?.withRenderingMode(.alwaysTemplate)
        currencyIcon.tintColor = UIColor.white
    }
}

extension UTXOCell: Configurable {
    
    func configure(with options: (row: Int, utxo:BMUTXO)) {
    
        mainView.backgroundColor = (options.row % 2 == 0) ? UIColor.main.marineThree : UIColor.main.marine
        
        amountLabel.text = String.currency(value: options.utxo.realAmount)
        statusLabel.text = options.utxo.statusString
        
        if options.utxo.status == 1 || options.utxo.status == 2 {
            statusLabel.textColor = UIColor.white
        }
        else if options.utxo.status == 6 || options.utxo.status == 3 {
            statusLabel.textColor = UIColor.main.heliotrope
        }
        else if options.utxo.status == 4 {
            statusLabel.textColor = UIColor.main.brightSkyBlue
        }
        else{
            statusLabel.textColor = UIColor.main.blueyGrey
        }
                
        statusY.constant = 0
        dateY.constant = 0

        if let tr = options.utxo.transaction {
            transactionIcon.isHidden = (tr.comment.isEmpty)
            transactionDateLabel.text = tr.shortDate()
            
            if tr.comment.isEmpty {
                transactionCommentLabel.text = nil

                transactionIconWidth.constant = 0
                transactionIconHeight.constant = 0
                
                statusY.constant = -10
                dateY.constant = -5
            }
            else{
                transactionCommentLabel.text = "“\(tr.comment ?? String.empty())”"

                transactionIconWidth.constant = 16
                transactionIconHeight.constant = 16
            }
        }
        else{
            transactionIconWidth.constant = 0
            transactionIconHeight.constant = 0
            
            transactionIcon.isHidden = true
            transactionDateLabel.text = nil
            transactionCommentLabel.text = nil
        }
        
        let selectedView = UIView()
        selectedView.backgroundColor = UIColor.black.withAlphaComponent(0.2)
        selectedBackgroundView = selectedView
    }
}


