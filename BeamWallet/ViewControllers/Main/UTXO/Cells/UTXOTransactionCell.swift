//
// UTXOTransactionCell.swift
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

class UTXOTransactionCell: BaseCell {

    @IBOutlet weak private var arrowImage: UIImageView!
    @IBOutlet weak private var dateLabel: UILabel!
    @IBOutlet weak private var typeLabel: UILabel!
    @IBOutlet weak private var commentLabel: UILabel!
    @IBOutlet weak private var commentView: UIStackView!
    @IBOutlet weak private var mainView: UIView!

    override func awakeFromNib() {
        super.awakeFromNib()
        
        let selectedView = UIView()
        selectedView.backgroundColor = UIColor.main.selectedColor
        self.selectedBackgroundView = selectedView
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
}

extension UTXOTransactionCell: Configurable {
    
    func configure(with options: (row: Int, transaction:BMTransaction)) {
     
        mainView.backgroundColor = (options.row % 2 == 0) ? UIColor.main.marine : UIColor.main.cellBackgroundColor

        dateLabel.text = options.transaction.formattedDate()
        
        if !options.transaction.isIncome {
            arrowImage.image = IconSent()
            typeLabel.text = Localizable.shared.strings.send_beam
        }
        else{
            arrowImage.image = IconReceived()
            typeLabel.text = Localizable.shared.strings.receive_beam
        }
        
        if options.transaction.comment.isEmpty {
            commentView.isHidden = true
        }
        else{
            commentLabel.text = "”" + options.transaction.comment + "”"
            commentView.isHidden = false
        }
    }
}
