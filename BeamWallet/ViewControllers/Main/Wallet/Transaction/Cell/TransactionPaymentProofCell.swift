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

    @IBOutlet weak private var buttonDetails: BMButton!
    @IBOutlet weak private var buttonCopy: BMButton!
    @IBOutlet weak private var titleLabel: UILabel!

    override func awakeFromNib() {
        super.awakeFromNib()
        
        selectionStyle = .none
        allowHighlighted = false

        titleLabel.text = Localizable.shared.strings.payment_proof.uppercased()
        titleLabel.letterSpacing = 1.5
        
        if !Settings.sharedManager().isDarkMode {
            buttonDetails.backgroundColor = UIColor.main.marineThree
            buttonCopy.backgroundColor = UIColor.main.marineThree
        }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        if Settings.sharedManager().isDarkMode {
              buttonDetails.setBackgroundColor(color: UIColor.main.marineThree, forState: .normal)
              buttonDetails.setTitleColor(UIColor.white, for: .normal)
              
              buttonCopy.setBackgroundColor(color: UIColor.main.marineThree, forState: .normal)
              buttonCopy.setTitleColor(UIColor.white, for: .normal)
              
              titleLabel.textColor = UIColor.main.steel
          }
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
