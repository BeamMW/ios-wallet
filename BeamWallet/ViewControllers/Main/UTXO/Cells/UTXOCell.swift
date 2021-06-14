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
    @IBOutlet weak private var statusLabel: UILabel!
    @IBOutlet weak private var amountView: UIView!
    @IBOutlet weak private var typeLabel: UILabel!
    @IBOutlet weak private var dateLabel: UILabel!

//    @IBOutlet weak private var transactionDateLabel: UILabel!
//    @IBOutlet weak private var transactionCommentLabel: UILabel!
//    @IBOutlet weak private var transactionIcon: UIImageView!
//    @IBOutlet weak private var transactionIconHeight: NSLayoutConstraint!
//    @IBOutlet weak private var transactionIconWidth: NSLayoutConstraint!
//    @IBOutlet weak private var transactionDateWidth: NSLayoutConstraint!
//    @IBOutlet weak private var statusY: NSLayoutConstraint!
//    @IBOutlet weak private var dateY: NSLayoutConstraint!

    override func awakeFromNib() {
        super.awakeFromNib()
    }
}

extension UTXOCell: Configurable {
    
    func configure(with options: (row: Int, utxo:BMUTXO)) {
    
        mainView.backgroundColor = (options.row % 2 == 0) ? UIColor.main.cellBackgroundColor : UIColor.main.marine
        
        amountLabel.text = options.utxo.amountString
        statusLabel.text = options.utxo.statusString
        typeLabel.text = options.utxo.typeString.capitalizingFirstLetter()
        
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
                
        if let tr = options.utxo.transaction {
            dateLabel.text = tr.shortDate()
        }
        else{
            dateLabel.text = nil
            
            if(options.utxo.status == BMUTXOMaturing)
            {
                dateLabel.text = "\(Localizable.shared.strings.till_block.lowercased()) \(options.utxo.maturity)"
            }
        }
        
        let selectedView = UIView()
        selectedView.backgroundColor = UIColor.main.selectedColor
        selectedBackgroundView = selectedView
    }
}


