//
// TransactionShareView.swift
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

import Foundation

class TransactionShareView: UIView {
    
    @IBOutlet private weak var mainView: UIView!

    @IBOutlet private weak var bgView: UIImageView!
    @IBOutlet private weak var titleLabel: UILabel!
    @IBOutlet private weak var dateLabel: UILabel!
    
    @IBOutlet private weak var amountLabel: UILabel!
    @IBOutlet private weak var typeLabel: UILabel!
    @IBOutlet private weak var currencyIcon: UIImageView!

    @IBOutlet private weak var statusIcon: UIImageView!

    @IBOutlet private weak var senderTitleLabel: UILabel!
    @IBOutlet private weak var senderValueLabel: UILabel!
    
    @IBOutlet private weak var receiverTitleLabel: UILabel!
    @IBOutlet private weak var receiverValueLabel: UILabel!
    
    @IBOutlet private weak var transactionIDTitleLabel: UILabel!
    @IBOutlet private weak var transactionIDValueLabel: UILabel!
    
    @IBOutlet private weak var transactionFeeTitleLabel: UILabel!
    @IBOutlet private weak var transactionFeeValueLabel: UILabel!
    
    @IBOutlet private weak var kernelStackView: UIStackView!
    @IBOutlet private weak var transactionKernelTitleLabel: UILabel!
    @IBOutlet private weak var transactionKernelValueLabel: UILabel!

    var transaction:BMTransaction! {
        didSet{
            setupView()
        }
    }
    
    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }
    
    private func setupView() {
        statusIcon.image = transaction.statusIcon()
        
        currencyIcon.image = IconSymbolBeam()?.withRenderingMode(.alwaysTemplate)
        currencyIcon.tintAdjustmentMode = .normal
        
        titleLabel.text = Localizable.shared.strings.transaction_details.uppercased()
        titleLabel.letterSpacing = 1.5
        
        dateLabel.text = transaction.formattedDate()
        
        senderValueLabel.text = transaction.senderAddress
        receiverValueLabel.text = transaction.receiverAddress
        
        typeLabel.text = transaction.status.capitalizingFirstLetter()

        if transaction.isSelf {
            senderTitleLabel.text = Localizable.shared.strings.my_send_address
            receiverTitleLabel.text = Localizable.shared.strings.my_rec_address
        }
        else if transaction.isIncome {
            senderTitleLabel.text = Localizable.shared.strings.contact
            receiverTitleLabel.text = Localizable.shared.strings.my_address
        }
        else{
            senderTitleLabel.text = Localizable.shared.strings.contact
            receiverTitleLabel.text = Localizable.shared.strings.my_address
        }
        
        transactionFeeTitleLabel.text = Localizable.shared.strings.transaction_fee
        transactionFeeValueLabel.text = String(transaction.realFee) + " GROTH"
        
        transactionIDTitleLabel.text  = Localizable.shared.strings.transaction_id
        transactionIDValueLabel.text = transaction.id
        
        
        if transaction.isFailed() || transaction.isCancelled() || transaction.isExpired() {
            typeLabel.textColor = UIColor.main.greyish
        }
        else if transaction.isSelf {
            typeLabel.textColor = UIColor.white
        }
        else if transaction.isIncome
        {
            typeLabel.textColor = UIColor.main.brightSkyBlue
        }
        else if !transaction.isIncome
        {
            typeLabel.textColor = UIColor.main.heliotrope
        }
        
        switch transaction.isIncome {
        case true:
            amountLabel.text = "+" + String.currency(value: transaction.realAmount)
            amountLabel.textColor = UIColor.main.brightSkyBlue
            currencyIcon.tintColor = UIColor.main.brightSkyBlue
        case false:
            amountLabel.text = "-" + String.currency(value: transaction.realAmount)
            amountLabel.textColor = UIColor.main.heliotrope
            currencyIcon.tintColor = UIColor.main.heliotrope
        }
        
        transactionKernelValueLabel.text = transaction.kernelId
        if transaction.kernelId.contains("000000") || transaction.isExpired() || transaction.isFailed() {
            kernelStackView.isHidden = true
        }
        
        senderTitleLabel.text = senderTitleLabel.text?.uppercased()
        receiverTitleLabel.text = receiverTitleLabel.text?.uppercased()
        transactionIDTitleLabel.text = transactionIDTitleLabel.text?.uppercased()
        transactionFeeTitleLabel.text = transactionFeeTitleLabel.text?.uppercased()
        transactionKernelTitleLabel.text = transactionKernelTitleLabel.text?.uppercased()
        
    
        let colors = [UIColor.main.navyTwo, UIColor.main.deepSeaBlueTwo]
        
        let gradient: CAGradientLayer = CAGradientLayer()
        gradient.colors = colors.map { $0.cgColor }
        gradient.frame = CGRect(x: 0.0, y: 0.0, width: mainView.width, height: mainView.h)
        
        let backgroundImage = UIImageView()
        backgroundImage.clipsToBounds = true
        backgroundImage.contentMode = .scaleToFill
        backgroundImage.frame = CGRect(x: 0.0, y: 0.0, width: mainView.width, height: mainView.h)
        backgroundImage.tag = 10
        backgroundImage.layer.addSublayer(gradient)
        mainView.insertSubview(backgroundImage, at: 0)
        
        switch Settings.sharedManager().target {
        case Testnet:
            bgView.image = BackgroundTestnet()
        case Masternet:
            bgView.image = BackgroundMasternet()
        default:
            break
        }
    
    }
}
