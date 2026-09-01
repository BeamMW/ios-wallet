//
// AssetAvailableCell.swift
// BeamWallet
//
// Copyright 2026 Beam Development
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

class AssetAvailableCell: RippleCell {

    @IBOutlet weak private var mainView: BMGradientView!
    @IBOutlet weak private var balanceLabel: UILabel!
    @IBOutlet weak private var secondBalanceLabel: UILabel!
    @IBOutlet weak private var lockedLabel: UILabel!
    @IBOutlet weak private var lockedView: UIView!
    @IBOutlet weak private var iconView: AssetIconView!
    
    @IBOutlet weak private var topOffset: NSLayoutConstraint!
    @IBOutlet weak private var botOffset: NSLayoutConstraint!

    @IBOutlet weak private var assedIdLabel: UILabel!
    @IBOutlet weak private var assedIdStackView: UIStackView!

    var assetId = 0
    @objc func onAssetIdClicked() {
        if let url = URL(string: Settings.sharedManager().assetBlockchainUrl(Int32(self.assetId))) {
            UIApplication.getTopMostViewController()?.openUrl(url: url)
        }
    }

    private var utxoAccessory: UIStackView?
    private var utxoCountLabel: UILabel?

    override func awakeFromNib() {
        super.awakeFromNib()

        assedIdStackView.isUserInteractionEnabled = true
        assedIdStackView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(onAssetIdClicked)))
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        utxoAccessory?.isHidden = true
    }

    func setUTXOAccessory(count: Int?) {
        guard let count = count else {
            utxoAccessory?.isHidden = true
            return
        }
        if utxoAccessory == nil {
            let label = UILabel()
            label.font = RegularFont(size: 12)
            label.textColor = UIColor.white.withAlphaComponent(0.7)

            let arrow = UIImageView(image: IconNextArrow())
            arrow.contentMode = .scaleAspectFit
            arrow.translatesAutoresizingMaskIntoConstraints = false
            arrow.widthAnchor.constraint(equalToConstant: 6).isActive = true
            arrow.heightAnchor.constraint(equalToConstant: 10).isActive = true

            let stack = UIStackView(arrangedSubviews: [label, arrow])
            stack.axis = .horizontal
            stack.alignment = .center
            stack.spacing = 6
            stack.translatesAutoresizingMaskIntoConstraints = false
            mainView.addSubview(stack)
            NSLayoutConstraint.activate([
                stack.trailingAnchor.constraint(equalTo: mainView.trailingAnchor, constant: -15),
                stack.bottomAnchor.constraint(equalTo: mainView.bottomAnchor, constant: -15),
            ])

            utxoAccessory = stack
            utxoCountLabel = label
        }
        utxoAccessory?.isHidden = false
        utxoCountLabel?.text = Localizable.shared.strings.coin_count_format
            .replacingOccurrences(of: "(count)", with: "\(count)")
    }
    
    public func setAsset(_ asset:BMAsset) {
        assetId = Int(asset.assetId)
        iconView.setAsset(asset)
        assedIdLabel.text = "#\(asset.assetId)"
        
        if Settings.sharedManager().target == Testnet {
            mainView.gradientLayer.colors = [
                UIColor(hexString: asset.color).withAlphaComponent(0.3).cgColor,
                UIColor(red: 12 / 255, green: 12 / 255, blue: 12 / 255, alpha: 1).cgColor]
        }
        else {
            mainView.gradientLayer.colors = [
                UIColor(hexString: asset.color).withAlphaComponent(0.3).cgColor,
                UIColor.main.cellBackgroundColor.cgColor]
        }
        
        mainView.gradientLayer.startPoint = CGPoint(x: 0.0, y: 0.5)
        mainView.gradientLayer.endPoint = CGPoint(x: 1.0, y: 0.5)
        
        balanceLabel.text = asset.isBeam() ? String.currency(value: asset.realAmount) : String.currency(value: asset.realAmount, name: asset.unitName)
        secondBalanceLabel.text = ExchangeManager.shared().exchangeValueAsset(asset.realAmount, assetID: asset.assetId)
        
        if asset.locked() > 0 {
            lockedLabel.text = asset.isBeam() ? String.currency(value: asset.realLocked())
                : String.currencyShort(value: asset.realLocked(), name: asset.unitName)
            
            lockedView.isHidden = false
            topOffset.constant = 18
            botOffset.constant = 18
        }
        else {
            lockedView.isHidden = true
            topOffset.constant = 23
            botOffset.constant = 23
        }
    }
    
}
