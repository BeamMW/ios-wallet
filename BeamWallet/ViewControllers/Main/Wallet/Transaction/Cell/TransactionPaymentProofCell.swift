//
// GeneralInfoCell.swift
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

protocol TransactionPaymentProofCellDelegate: AnyObject {
    func onPaymentProofDetails()
    func onPaymentProofCopy()
}

class TransactionPaymentProofCell: BaseCell {

    weak var delegate: TransactionPaymentProofCellDelegate?

    @IBOutlet weak private var buttonDetails: UIButton!
    @IBOutlet weak private var buttonCopy: UIButton!

    override func awakeFromNib() {
        super.awakeFromNib()
        
        selectionStyle = .none
        
        buttonDetails.backgroundColor = UIColor.main.marineTwo;
        buttonCopy.backgroundColor = UIColor.main.marineTwo;
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
    
    @IBAction func onDetails(sender :UIButton) {

        self.delegate?.onPaymentProofDetails()
    }
    
    @IBAction func onCopy(sender :UIButton) {

        self.delegate?.onPaymentProofCopy()
    }
    
}
