//
//  ReceiveCreateCell.swift
//  BeamWallet
//
//  Created by Denis on 5/27/19.
//  Copyright © 2019 Denis. All rights reserved.
//

import UIKit

class ReceiveCreateCell: BaseCell {
    
    weak var delegate: ReceiveCellProtocol?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        selectionStyle = .none
    }
    
    @IBAction func onCancel(sender :UIButton) {
        delegate?.onCancelCreate?()
    }
    
    @IBAction func onCreate(sender :UIButton) {
        delegate?.onConfirmCreate?()
    }
}
