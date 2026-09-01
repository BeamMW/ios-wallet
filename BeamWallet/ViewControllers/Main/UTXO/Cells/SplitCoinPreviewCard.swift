//
// SplitCoinPreviewCard.swift
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

final class SplitCoinPreviewCard: UIView {

    static let preferredHeight: CGFloat = 86
    private static let swatchSize: CGFloat = 20

    private let swatch = UIView()
    private let amountLabel = UILabel()
    private let unitLabel = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupViews() {
        backgroundColor = UIColor.main.cellBackgroundColor
        layer.cornerRadius = 10
        translatesAutoresizingMaskIntoConstraints = false

        swatch.layer.cornerRadius = 5
        swatch.translatesAutoresizingMaskIntoConstraints = false
        addSubview(swatch)

        amountLabel.font = BoldFont(size: 13)
        amountLabel.textColor = UIColor.white
        amountLabel.adjustsFontSizeToFitWidth = true
        amountLabel.minimumScaleFactor = 0.7
        amountLabel.textAlignment = .center
        amountLabel.translatesAutoresizingMaskIntoConstraints = false
        addSubview(amountLabel)

        unitLabel.font = RegularFont(size: 11)
        unitLabel.textColor = UIColor.main.blueyGrey
        unitLabel.textAlignment = .center
        unitLabel.translatesAutoresizingMaskIntoConstraints = false
        addSubview(unitLabel)

        NSLayoutConstraint.activate([
            heightAnchor.constraint(equalToConstant: SplitCoinPreviewCard.preferredHeight),

            swatch.topAnchor.constraint(equalTo: topAnchor, constant: 12),
            swatch.centerXAnchor.constraint(equalTo: centerXAnchor),
            swatch.widthAnchor.constraint(equalToConstant: SplitCoinPreviewCard.swatchSize),
            swatch.heightAnchor.constraint(equalToConstant: SplitCoinPreviewCard.swatchSize),

            amountLabel.topAnchor.constraint(equalTo: swatch.bottomAnchor, constant: 8),
            amountLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 6),
            amountLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -6),

            unitLabel.topAnchor.constraint(equalTo: amountLabel.bottomAnchor, constant: 4),
            unitLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 6),
            unitLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -6),
        ])
    }

    func configure(amountText: String, unitText: String, color: UIColor) {
        swatch.isHidden = false
        swatch.backgroundColor = color
        amountLabel.text = amountText
        amountLabel.textColor = UIColor.white
        amountLabel.font = BoldFont(size: 13)
        unitLabel.text = unitText.uppercased()
        unitLabel.isHidden = false
    }

    func configureMore(text: String) {
        swatch.isHidden = true
        swatch.backgroundColor = .clear
        amountLabel.text = text
        amountLabel.textColor = UIColor.main.blueyGrey
        amountLabel.font = BoldFont(size: 13)
        unitLabel.text = nil
        unitLabel.isHidden = true
    }
}
