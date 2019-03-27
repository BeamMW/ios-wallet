//
//  UTXOTransactionCell.swift
//  BeamWallet
//
//  Created by Denis on 3/22/19.
//  Copyright © 2019 Denis. All rights reserved.
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
