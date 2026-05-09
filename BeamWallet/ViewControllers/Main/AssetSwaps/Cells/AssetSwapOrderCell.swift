//
// AssetSwapOrderCell.swift
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

class AssetSwapOrderCell: RippleCell {

    private let mainView = UIView()
    private let amountsLabel = UILabel()
    private let rateLabel = UILabel()
    private let statusLabel = UILabel()
    private let expiryLabel = UILabel()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        backgroundColor = .clear
        contentView.backgroundColor = .clear
        selectionStyle = .none

        mainView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(mainView)

        amountsLabel.translatesAutoresizingMaskIntoConstraints = false
        amountsLabel.font = BoldFont(size: 15)
        amountsLabel.textColor = UIColor.white
        amountsLabel.numberOfLines = 0
        mainView.addSubview(amountsLabel)

        rateLabel.translatesAutoresizingMaskIntoConstraints = false
        rateLabel.font = RegularFont(size: 13)
        rateLabel.textColor = UIColor.main.steelGrey
        mainView.addSubview(rateLabel)

        statusLabel.translatesAutoresizingMaskIntoConstraints = false
        statusLabel.font = SemiboldFont(size: 12)
        statusLabel.textColor = UIColor.main.brightTeal
        statusLabel.textAlignment = .right
        mainView.addSubview(statusLabel)

        expiryLabel.translatesAutoresizingMaskIntoConstraints = false
        expiryLabel.font = RegularFont(size: 12)
        expiryLabel.textColor = UIColor.main.steelGrey
        expiryLabel.textAlignment = .right
        mainView.addSubview(expiryLabel)

        NSLayoutConstraint.activate([
            mainView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            mainView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            mainView.topAnchor.constraint(equalTo: contentView.topAnchor),
            mainView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),

            amountsLabel.leadingAnchor.constraint(equalTo: mainView.leadingAnchor, constant: defaultX),
            amountsLabel.topAnchor.constraint(equalTo: mainView.topAnchor, constant: 14),
            amountsLabel.trailingAnchor.constraint(lessThanOrEqualTo: statusLabel.leadingAnchor, constant: -8),

            statusLabel.trailingAnchor.constraint(equalTo: mainView.trailingAnchor, constant: -defaultX),
            statusLabel.centerYAnchor.constraint(equalTo: amountsLabel.centerYAnchor),
            statusLabel.widthAnchor.constraint(lessThanOrEqualToConstant: 100),

            rateLabel.leadingAnchor.constraint(equalTo: amountsLabel.leadingAnchor),
            rateLabel.topAnchor.constraint(equalTo: amountsLabel.bottomAnchor, constant: 6),
            rateLabel.bottomAnchor.constraint(lessThanOrEqualTo: mainView.bottomAnchor, constant: -14),

            expiryLabel.trailingAnchor.constraint(equalTo: statusLabel.trailingAnchor),
            expiryLabel.centerYAnchor.constraint(equalTo: rateLabel.centerYAnchor),
        ])
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) is not supported")
    }

    func configure(with order: BMDexOrder, row: Int) {
        amountsLabel.text = "\(order.displaySendAmount())  →  \(order.displayReceiveAmount())"
        rateLabel.text = order.displayRate()

        if order.isCompleted {
            statusLabel.text = Localizable.shared.strings.asset_swap_completed
            statusLabel.textColor = UIColor.main.steelGrey
            expiryLabel.text = ""
        } else if order.isCanceled {
            statusLabel.text = Localizable.shared.strings.asset_swap_canceled
            statusLabel.textColor = UIColor.main.steelGrey
            expiryLabel.text = ""
        } else if order.isExpired() {
            statusLabel.text = Localizable.shared.strings.asset_swap_expired
            statusLabel.textColor = UIColor.main.steelGrey
            expiryLabel.text = ""
        } else if order.isAccepted {
            statusLabel.text = Localizable.shared.strings.in_progress
            statusLabel.textColor = UIColor.main.brightTeal
            expiryLabel.text = order.displayExpiresIn()
        } else {
            statusLabel.text = ""
            expiryLabel.text = order.displayExpiresIn()
        }

        mainView.backgroundColor = (row % 2 == 0) ? UIColor.main.cellBackgroundColor : UIColor.main.marine
    }
}
