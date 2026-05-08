//
//  ReceiveTokenCell.swift
//  BeamWallet
//
//  Created by Denis on 04.11.2020.
//  Copyright © 2020 Denis. All rights reserved.
//

import UIKit

@objc protocol ReceiveAddressTokensCellDelegate: AnyObject {
    @objc optional func onShowToken(token: String)
    @objc optional func onShowQR(token: String)
    @objc optional func onShareToken(token: String)
    @objc optional func onCopyToken(token: String)
}

class ReceiveTokenCell: BaseCell {

    weak var delegate: ReceiveAddressTokensCellDelegate?

    private let nameLabel = UILabel()
    private let detailButton = UIButton(type: .system)
    private let detailLabel = BMCopyLabel()
    private let copyButton = UIButton(type: .system)
    private let qrButton = UIButton(type: .system)
    private let shareButton = UIButton(type: .system)
    private let sbbsContainer = UIStackView()
    private let sbbsSeparator = UIView()
    private let sbbsTitleLabel = UILabel()
    private let sbbsValueLabel = BMCopyLabel()
    private let sbbsCopyButton = UIButton(type: .system)
    private let sbbsHintLabel = UILabel()
    private let hintLabel = UILabel()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setup()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }

    private func setup() {
        backgroundColor = .clear
        contentView.backgroundColor = UIColor.main.marineThree
        selectionStyle = .none
        allowHighlighted = false

        let accent = UIColor.main.brightSkyBlue
        let hintColor = Settings.sharedManager().isDarkMode ? UIColor.main.steel : UIColor.main.blueyGrey

        nameLabel.text = Localizable.shared.strings.address.uppercased()
        nameLabel.textColor = .white
        nameLabel.font = BoldFont(size: 14)
        nameLabel.numberOfLines = 1
        nameLabel.letterSpacing = 2
        nameLabel.setContentHuggingPriority(.defaultLow, for: .horizontal)
        nameLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)

        detailButton.setTitle(Localizable.shared.strings.address_details.lowercased(), for: .normal)
        detailButton.setTitleColor(accent, for: .normal)
        detailButton.contentHorizontalAlignment = .right
        detailButton.addTarget(self, action: #selector(onShowTokenTap), for: .touchUpInside)
        detailButton.setContentHuggingPriority(.required, for: .horizontal)
        detailButton.setContentCompressionResistancePriority(.required, for: .horizontal)

        let titleRow = UIStackView(arrangedSubviews: [nameLabel, detailButton])
        titleRow.axis = .horizontal
        titleRow.alignment = .center
        titleRow.spacing = 8

        detailLabel.font = RegularFont(size: 16)
        detailLabel.textColor = .white
        detailLabel.lineBreakMode = .byTruncatingMiddle
        detailLabel.adjustsFontSizeToFitWidth = false
        detailLabel.copiedText = Localizable.shared.strings.address_copied

        configureIconButton(copyButton, image: UIImage(named: "iconCopyWhite24") ?? UIImage(named: "iconCopyWhite"), tint: accent, action: #selector(onCopyTap))
        configureIconButton(qrButton, image: UIImage(named: "iconScanQr"), tint: accent, action: #selector(onQRTap))
        configureIconButton(shareButton, image: UIImage(named: "iconShareNew"), tint: accent, action: #selector(onShareTap))

        let actionRow = UIStackView(arrangedSubviews: [copyButton, qrButton, shareButton])
        actionRow.axis = .horizontal
        actionRow.alignment = .center
        actionRow.distribution = .fillEqually
        actionRow.spacing = 16

        sbbsSeparator.backgroundColor = UIColor.white.withAlphaComponent(0.1)
        sbbsSeparator.translatesAutoresizingMaskIntoConstraints = false
        sbbsSeparator.heightAnchor.constraint(equalToConstant: 1).isActive = true

        sbbsTitleLabel.text = Localizable.shared.strings.sbbs_address.uppercased()
        sbbsTitleLabel.textColor = .white
        sbbsTitleLabel.font = BoldFont(size: 14)
        sbbsTitleLabel.letterSpacing = 2

        sbbsValueLabel.font = RegularFont(size: 16)
        sbbsValueLabel.textColor = .white
        sbbsValueLabel.lineBreakMode = .byTruncatingMiddle
        sbbsValueLabel.adjustsFontSizeToFitWidth = false
        sbbsValueLabel.copiedText = Localizable.shared.strings.address_copied
        sbbsValueLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        sbbsValueLabel.setContentHuggingPriority(.defaultLow, for: .horizontal)

        configureIconButton(sbbsCopyButton, image: UIImage(named: "iconCopyWhite24") ?? UIImage(named: "iconCopyWhite"), tint: accent, action: #selector(onCopySBBSTap))
        sbbsCopyButton.setContentHuggingPriority(.required, for: .horizontal)
        sbbsCopyButton.setContentCompressionResistancePriority(.required, for: .horizontal)

        let sbbsRow = UIStackView(arrangedSubviews: [sbbsValueLabel, sbbsCopyButton])
        sbbsRow.axis = .horizontal
        sbbsRow.alignment = .center
        sbbsRow.spacing = 8

        sbbsHintLabel.font = ItalicFont(size: 12)
        sbbsHintLabel.textColor = hintColor
        sbbsHintLabel.numberOfLines = 0
        sbbsHintLabel.text = Localizable.shared.strings.sbbs_address_hint

        sbbsContainer.axis = .vertical
        sbbsContainer.spacing = 8
        sbbsContainer.addArrangedSubview(sbbsSeparator)
        sbbsContainer.addArrangedSubview(sbbsTitleLabel)
        sbbsContainer.addArrangedSubview(sbbsRow)
        sbbsContainer.addArrangedSubview(sbbsHintLabel)
        sbbsContainer.isHidden = true
        sbbsContainer.setCustomSpacing(14, after: sbbsSeparator)
        sbbsContainer.setCustomSpacing(4, after: sbbsRow)

        hintLabel.font = ItalicFont(size: 12)
        hintLabel.textColor = hintColor
        hintLabel.numberOfLines = 0
        hintLabel.text = Localizable.shared.strings.receive_address_hint
        hintLabel.isHidden = true

        let mainStack = UIStackView(arrangedSubviews: [titleRow, detailLabel, actionRow, sbbsContainer, hintLabel])
        mainStack.axis = .vertical
        mainStack.spacing = 14
        mainStack.translatesAutoresizingMaskIntoConstraints = false
        mainStack.setCustomSpacing(12, after: detailLabel)

        contentView.addSubview(mainStack)
        NSLayoutConstraint.activate([
            mainStack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 15),
            mainStack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -15),
            mainStack.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 20),
            mainStack.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -20),
        ])
    }

    private func configureIconButton(_ button: UIButton, image: UIImage?, tint: UIColor, action: Selector) {
        button.setImage(image?.withRenderingMode(.alwaysTemplate), for: .normal)
        button.tintColor = tint
        button.imageView?.contentMode = .scaleAspectFit
        button.addTarget(self, action: action, for: .touchUpInside)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.heightAnchor.constraint(equalToConstant: 32).isActive = true
    }

    @objc private func onShowTokenTap() {
        if let token = detailLabel.text { delegate?.onShowToken?(token: token) }
    }

    @objc private func onCopyTap() {
        if let token = detailLabel.text { delegate?.onCopyToken?(token: token) }
    }

    @objc private func onQRTap() {
        if let token = detailLabel.text { delegate?.onShowQR?(token: token) }
    }

    @objc private func onShareTap() {
        if let token = detailLabel.text { delegate?.onShareToken?(token: token) }
    }

    @objc private func onCopySBBSTap() {
        guard let token = sbbsValueLabel.text, !token.isEmpty else { return }
        delegate?.onCopyToken?(token: token)
    }

    func configure(with value: String, title: String, sbbsAddress: String?, showHint: Bool) {
        detailLabel.text = value
        detailLabel.copyText = value
        nameLabel.text = title
        nameLabel.letterSpacing = 2

        let trimmedSBBS = sbbsAddress?.trimmingCharacters(in: .whitespacesAndNewlines)
        if let sbbs = trimmedSBBS, !sbbs.isEmpty, sbbs != value {
            sbbsValueLabel.text = sbbs
            sbbsValueLabel.copyText = sbbs
            sbbsContainer.isHidden = false
        } else {
            sbbsValueLabel.text = nil
            sbbsValueLabel.copyText = nil
            sbbsContainer.isHidden = true
        }

        hintLabel.isHidden = !showHint
        hintLabel.text = showHint ? Localizable.shared.strings.receive_address_hint : nil
    }
}
