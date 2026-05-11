//
// AssetUTXOSectionHeaderView.swift
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

final class AssetUTXOSectionHeaderView: UIView {

    static let preferredHeight: CGFloat = 116
    private static let iconSize: CGFloat = 36

    private let card = UIView()
    private let iconHost = UIView()
    private let iconView: AssetIconView
    private let nameLabel = UILabel()
    private let subtitleLabel = UILabel()
    private let labelStack = UIStackView()
    private let splitButton = makePillButton(title: Localizable.shared.strings.split)
    private let consolidateButton = makePillButton(title: Localizable.shared.strings.consolidate)
    private let buttonRow = UIStackView()

    var onSplitTapped: (() -> Void)?
    var onConsolidateTapped: (() -> Void)?

    init(group: AssetUTXOGroup) {
        self.iconView = AssetIconView(frame: CGRect(x: 0, y: 0, width: Self.iconSize, height: Self.iconSize))
        super.init(frame: .zero)
        setupViews()
        configure(with: group)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private static func makePillButton(title: String) -> UIButton {
        let btn = UIButton(type: .system)
        btn.setTitle(title.uppercased(), for: .normal)
        btn.titleLabel?.font = BoldFont(size: 12)
        btn.setTitleColor(UIColor.main.brightTeal, for: .normal)
        btn.setTitleColor(UIColor.main.brightTeal.withAlphaComponent(0.4), for: .disabled)
        btn.layer.borderColor = UIColor.main.brightTeal.cgColor
        btn.layer.borderWidth = 1
        btn.layer.cornerRadius = 16
        btn.contentEdgeInsets = UIEdgeInsets(top: 6, left: 14, bottom: 6, right: 14)
        btn.translatesAutoresizingMaskIntoConstraints = false
        return btn
    }

    private func setupViews() {
        backgroundColor = .clear

        card.backgroundColor = UIColor.main.cellBackgroundColor
        card.layer.cornerRadius = 12
        card.translatesAutoresizingMaskIntoConstraints = false
        addSubview(card)

        iconView.cornerRadius = Self.iconSize / 2
        iconHost.translatesAutoresizingMaskIntoConstraints = false
        iconHost.addSubview(iconView)
        card.addSubview(iconHost)

        nameLabel.font = BoldFont(size: 20)
        nameLabel.textColor = UIColor.white

        subtitleLabel.font = RegularFont(size: 13)
        subtitleLabel.textColor = UIColor.main.blueyGrey

        labelStack.axis = .vertical
        labelStack.alignment = .leading
        labelStack.spacing = 2
        labelStack.translatesAutoresizingMaskIntoConstraints = false
        labelStack.addArrangedSubview(nameLabel)
        labelStack.addArrangedSubview(subtitleLabel)
        card.addSubview(labelStack)

        splitButton.addTarget(self, action: #selector(onSplit), for: .touchUpInside)
        consolidateButton.addTarget(self, action: #selector(onConsolidate), for: .touchUpInside)

        buttonRow.axis = .horizontal
        buttonRow.distribution = .fillEqually
        buttonRow.spacing = 10
        buttonRow.translatesAutoresizingMaskIntoConstraints = false
        buttonRow.addArrangedSubview(splitButton)
        buttonRow.addArrangedSubview(consolidateButton)
        card.addSubview(buttonRow)

        NSLayoutConstraint.activate([
            card.topAnchor.constraint(equalTo: topAnchor, constant: 6),
            card.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -6),
            card.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            card.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),

            iconHost.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 14),
            iconHost.topAnchor.constraint(equalTo: card.topAnchor, constant: 14),
            iconHost.widthAnchor.constraint(equalToConstant: Self.iconSize),
            iconHost.heightAnchor.constraint(equalToConstant: Self.iconSize),

            labelStack.leadingAnchor.constraint(equalTo: iconHost.trailingAnchor, constant: 12),
            labelStack.centerYAnchor.constraint(equalTo: iconHost.centerYAnchor),
            labelStack.trailingAnchor.constraint(lessThanOrEqualTo: card.trailingAnchor, constant: -14),

            buttonRow.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 14),
            buttonRow.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -14),
            buttonRow.topAnchor.constraint(equalTo: iconHost.bottomAnchor, constant: 12),
            buttonRow.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -14),
            buttonRow.heightAnchor.constraint(equalToConstant: 32),
        ])
    }

    private func configure(with group: AssetUTXOGroup) {
        nameLabel.text = group.asset.unitName
        subtitleLabel.text = group.asset.name
        iconView.setAsset(group.asset)
        splitButton.isEnabled = group.canSplit
        consolidateButton.isEnabled = group.utxos.count >= 2
    }

    @objc private func onSplit() {
        onSplitTapped?()
    }

    @objc private func onConsolidate() {
        onConsolidateTapped?()
    }
}
