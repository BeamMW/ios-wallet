//
// SendAllCell.swift
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

class SendAllCell: BaseCell {
    
    @IBOutlet private weak var amountLabel: UILabel!
    @IBOutlet private weak var allButton: UIButton!
    @IBOutlet private weak var titleLabel: UILabel!
    @IBOutlet private weak var secondAvailableLabel: UILabel!

    @IBOutlet var bottomOffset: NSLayoutConstraint!

    weak var delegate: BMCellProtocol?

    public var titleColor: UIColor? {
        didSet {
            if let color = titleColor {
                titleLabel.textColor = color
            }
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()

        allowHighlighted = false

        secondAvailableLabel.textColor = Settings.sharedManager().isDarkMode ? UIColor.main.steel : UIColor.main.blueyGrey
        secondAvailableLabel.font = RegularFont(size: 14)
        
        selectionStyle = .none
        
        allButton.setTitle(Localizable.shared.strings.add_max.lowercased(), for: .normal)

        if Settings.sharedManager().isDarkMode {
            titleLabel.textColor = UIColor.main.steel;
        }
    }

    @IBAction func onSendAll(sender: UIButton) {
        delegate?.onRightButton?(self)
    }
    
    func sendUnlinkOnly(value:Bool)  {
        
    }
}

extension SendAllCell: Configurable {
    func configure(with options: (realAmount: Double, assetId:Int, isAll: Bool, type: BMTransactionType)) {
        let asset = AssetsManager.shared().getAsset(Int32(options.assetId))
        let total = String.currency(value: options.realAmount, name: asset?.unitName ?? "")
        
        amountLabel.text = total
        secondAvailableLabel.text = ExchangeManager.shared().exchangeValueAsset(options.realAmount, assetID: UInt64(options.assetId))

        if options.realAmount == 0 {
            secondAvailableLabel.isHidden = true
        }
        
        if options.isAll {
            allButton.isUserInteractionEnabled = false
            allButton.alpha = 0.5
        }
        else {
            allButton.isUserInteractionEnabled = true
            allButton.alpha = 1
        }
        
        titleLabel.text = Localizable.shared.strings.available.uppercased()
        titleLabel.letterSpacing = 1.5
    }
}
