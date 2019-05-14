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

    @IBOutlet weak private var idLabel: BMCopyLabel!
    @IBOutlet weak private var dateLabel: UILabel!
    @IBOutlet weak private var arrowImage: UIImageView!
    @IBOutlet weak private var commentLabel: UILabel!

    override func awakeFromNib() {
        super.awakeFromNib()
        
        selectionStyle = .none
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
}

extension UTXOTransactionCell: Configurable {
    
    func configure(with transaction:BMTransaction) {
     
        dateLabel.text = transaction.formattedDate()
        
        if !transaction.isIncome {
            arrowImage.image = UIImage.init(named: "iconSendPink")
        }
        else{
            arrowImage.image = UIImage(named: "iconReceiveLightBlue")
        }
        
        idLabel.text = transaction.id
        commentLabel.text = transaction.comment
    }
}
