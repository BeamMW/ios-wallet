//
// AssetSwapDetailsViewController.swift
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

class AssetSwapDetailsViewController: BaseViewController {

    private let viewModel: AssetSwapDetailsViewModel

    private let scrollView = UIScrollView()
    private let contentView = UIView()
    private let footerContainer = UIView()

    private let sendIconView = AssetIconView(frame: CGRect(x: 0, y: 0, width: 48, height: 48))
    private let receiveIconView = AssetIconView(frame: CGRect(x: 0, y: 0, width: 48, height: 48))

    private let detailsCard = UIView()
    private let technicalContainer = UIView()
    private let disclosureLabel = UILabel()
    private let disclosureChevron = UIImageView(image: UIImage(named: "iconDownArrow"))

    private var technicalExpanded = false

    private var isSubmitting = false
    private weak var acceptButton: BMButton?

    init(order: BMDexOrder) {
        self.viewModel = AssetSwapDetailsViewModel(order: order)
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) is not supported")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        setGradientTopBar(mainColor: UIColor.main.peacockBlue, addedStatusView: true)
        title = Localizable.shared.strings.asset_swap_details

        layoutFooter()
        layoutScrollView()

        let header = makeSwapHeaderCard()
        let rateStrip = makeRateStrip()
        let details = makeDetailsCard()

        let stack = UIStackView(arrangedSubviews: [header, rateStrip, details])
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.axis = .vertical
        stack.spacing = 18
        stack.alignment = .fill
        contentView.addSubview(stack)

        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: defaultX),
            stack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -defaultX),
            stack.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 24),
            stack.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -24)
        ])
    }

    // MARK: - Footer (sticky, pinned to safe area)

    private func layoutFooter() {
        footerContainer.translatesAutoresizingMaskIntoConstraints = false
        footerContainer.backgroundColor = view.backgroundColor
        view.addSubview(footerContainer)

        NSLayoutConstraint.activate([
            footerContainer.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            footerContainer.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            footerContainer.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
        ])

        populateFooter(footerContainer)
    }

    // MARK: - Scroll container

    private func layoutScrollView() {
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scrollView)

        contentView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(contentView)

        NSLayoutConstraint.activate([
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.topAnchor.constraint(equalTo: view.topAnchor, constant: navigationBarOffset),
            scrollView.bottomAnchor.constraint(equalTo: footerContainer.topAnchor),

            contentView.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor),
            contentView.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor)
        ])
    }

    // MARK: - Swap header card (you send / you receive)

    private func makeSwapHeaderCard() -> UIView {
        let card = UIView()
        card.translatesAutoresizingMaskIntoConstraints = false
        card.backgroundColor = UIColor.main.cellBackgroundColor
        card.layer.cornerRadius = 12
        card.layer.masksToBounds = true

        let sendRow = makeAssetRow(
            iconView: sendIconView,
            asset: viewModel.sendAsset,
            caption: Localizable.shared.strings.asset_swap_send,
            amount: viewModel.order.displaySendAmount(),
            assetSymbol: "\(viewModel.order.sendAssetSName) (\(viewModel.order.sendAssetId))"
        )

        let receiveRow = makeAssetRow(
            iconView: receiveIconView,
            asset: viewModel.receiveAsset,
            caption: Localizable.shared.strings.asset_swap_receive,
            amount: viewModel.order.displayReceiveAmount(),
            assetSymbol: "\(viewModel.order.receiveAssetSName) (\(viewModel.order.receiveAssetId))"
        )

        let separator = UIView()
        separator.translatesAutoresizingMaskIntoConstraints = false
        separator.backgroundColor = UIColor.main.marineOriginal.withAlphaComponent(0.4)

        let arrow = UIView()
        arrow.translatesAutoresizingMaskIntoConstraints = false
        arrow.backgroundColor = UIColor.main.marineOriginal
        arrow.layer.cornerRadius = 16
        arrow.layer.borderWidth = 2
        arrow.layer.borderColor = UIColor.main.cellBackgroundColor.cgColor

        let arrowGlyph = UILabel()
        arrowGlyph.translatesAutoresizingMaskIntoConstraints = false
        arrowGlyph.text = "↓"
        arrowGlyph.font = BoldFont(size: 18)
        arrowGlyph.textColor = UIColor.main.brightTeal
        arrowGlyph.textAlignment = .center
        arrow.addSubview(arrowGlyph)

        card.addSubview(sendRow)
        card.addSubview(separator)
        card.addSubview(receiveRow)
        card.addSubview(arrow)

        NSLayoutConstraint.activate([
            sendRow.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 16),
            sendRow.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -16),
            sendRow.topAnchor.constraint(equalTo: card.topAnchor, constant: 18),

            separator.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 16),
            separator.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -16),
            separator.topAnchor.constraint(equalTo: sendRow.bottomAnchor, constant: 18),
            separator.heightAnchor.constraint(equalToConstant: 1),

            receiveRow.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 16),
            receiveRow.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -16),
            receiveRow.topAnchor.constraint(equalTo: separator.bottomAnchor, constant: 18),
            receiveRow.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -18),

            arrow.centerXAnchor.constraint(equalTo: card.centerXAnchor),
            arrow.centerYAnchor.constraint(equalTo: separator.centerYAnchor),
            arrow.widthAnchor.constraint(equalToConstant: 32),
            arrow.heightAnchor.constraint(equalToConstant: 32),

            arrowGlyph.centerXAnchor.constraint(equalTo: arrow.centerXAnchor),
            arrowGlyph.centerYAnchor.constraint(equalTo: arrow.centerYAnchor, constant: -1)
        ])

        return card
    }

    private func makeAssetRow(iconView: AssetIconView, asset: BMAsset?, caption: String, amount: String, assetSymbol: String) -> UIView {
        let row = UIView()
        row.translatesAutoresizingMaskIntoConstraints = false

        iconView.translatesAutoresizingMaskIntoConstraints = false
        if let asset = asset {
            iconView.setAsset(asset)
        }
        row.addSubview(iconView)

        let captionLabel = UILabel()
        captionLabel.translatesAutoresizingMaskIntoConstraints = false
        captionLabel.font = RegularFont(size: 11)
        captionLabel.textColor = UIColor.main.steelGrey
        captionLabel.numberOfLines = 1
        captionLabel.attributedText = NSAttributedString(string: caption.uppercased(), attributes: [.kern: 1.0])
        captionLabel.setContentCompressionResistancePriority(.required, for: .horizontal)
        captionLabel.setContentHuggingPriority(.required, for: .horizontal)
        row.addSubview(captionLabel)

        let symbolLabel = UILabel()
        symbolLabel.translatesAutoresizingMaskIntoConstraints = false
        symbolLabel.font = SemiboldFont(size: 15)
        symbolLabel.textColor = UIColor.white
        symbolLabel.numberOfLines = 1
        symbolLabel.text = assetSymbol
        symbolLabel.setContentCompressionResistancePriority(.required, for: .horizontal)
        symbolLabel.setContentHuggingPriority(.required, for: .horizontal)
        row.addSubview(symbolLabel)

        let amountLabel = UILabel()
        amountLabel.translatesAutoresizingMaskIntoConstraints = false
        amountLabel.font = BoldFont(size: 22)
        amountLabel.textColor = UIColor.white
        amountLabel.textAlignment = .right
        amountLabel.numberOfLines = 1
        amountLabel.adjustsFontSizeToFitWidth = true
        amountLabel.minimumScaleFactor = 0.6
        amountLabel.text = amount
        amountLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        amountLabel.setContentHuggingPriority(.defaultLow, for: .horizontal)
        row.addSubview(amountLabel)

        NSLayoutConstraint.activate([
            iconView.leadingAnchor.constraint(equalTo: row.leadingAnchor),
            iconView.centerYAnchor.constraint(equalTo: row.centerYAnchor),
            iconView.widthAnchor.constraint(equalToConstant: 48),
            iconView.heightAnchor.constraint(equalToConstant: 48),

            captionLabel.leadingAnchor.constraint(equalTo: iconView.trailingAnchor, constant: 12),
            captionLabel.topAnchor.constraint(equalTo: iconView.topAnchor, constant: 4),
            captionLabel.trailingAnchor.constraint(lessThanOrEqualTo: amountLabel.leadingAnchor, constant: -8),

            symbolLabel.leadingAnchor.constraint(equalTo: captionLabel.leadingAnchor),
            symbolLabel.topAnchor.constraint(equalTo: captionLabel.bottomAnchor, constant: 4),
            symbolLabel.trailingAnchor.constraint(lessThanOrEqualTo: amountLabel.leadingAnchor, constant: -8),

            amountLabel.trailingAnchor.constraint(equalTo: row.trailingAnchor),
            amountLabel.centerYAnchor.constraint(equalTo: row.centerYAnchor),

            row.heightAnchor.constraint(greaterThanOrEqualToConstant: 48)
        ])

        return row
    }

    // MARK: - Rate strip

    private func makeRateStrip() -> UIView {
        let strip = UIView()
        strip.translatesAutoresizingMaskIntoConstraints = false

        let captionLabel = UILabel()
        captionLabel.translatesAutoresizingMaskIntoConstraints = false
        captionLabel.font = RegularFont(size: 11)
        captionLabel.textColor = UIColor.main.steelGrey
        captionLabel.attributedText = NSAttributedString(
            string: Localizable.shared.strings.asset_swap_rate.uppercased(),
            attributes: [.kern: 1.0]
        )
        strip.addSubview(captionLabel)

        let valueLabel = UILabel()
        valueLabel.translatesAutoresizingMaskIntoConstraints = false
        valueLabel.font = SemiboldFont(size: 13)
        valueLabel.textColor = UIColor.main.brightTeal
        valueLabel.textAlignment = .right
        valueLabel.adjustsFontSizeToFitWidth = true
        valueLabel.minimumScaleFactor = 0.7
        valueLabel.text = viewModel.order.displayRate()
        strip.addSubview(valueLabel)

        NSLayoutConstraint.activate([
            captionLabel.leadingAnchor.constraint(equalTo: strip.leadingAnchor, constant: 4),
            captionLabel.centerYAnchor.constraint(equalTo: strip.centerYAnchor),

            valueLabel.trailingAnchor.constraint(equalTo: strip.trailingAnchor, constant: -4),
            valueLabel.centerYAnchor.constraint(equalTo: strip.centerYAnchor),
            valueLabel.leadingAnchor.constraint(greaterThanOrEqualTo: captionLabel.trailingAnchor, constant: 12),

            strip.heightAnchor.constraint(equalToConstant: 24)
        ])

        return strip
    }

    // MARK: - Details card (status / created / expires + collapsible technical)

    private func makeDetailsCard() -> UIView {
        detailsCard.translatesAutoresizingMaskIntoConstraints = false
        detailsCard.backgroundColor = UIColor.main.cellBackgroundColor
        detailsCard.layer.cornerRadius = 12
        detailsCard.layer.masksToBounds = true

        let order = viewModel.order

        var visibleRows: [UIView] = []

        let statusRow = makeDetailRow(
            label: Localizable.shared.strings.asset_swap_status,
            value: order.displayStatus().capitalized,
            valueColor: viewModel.statusColor
        )
        visibleRows.append(statusRow)

        let createdRow = makeDetailRow(
            label: Localizable.shared.strings.asset_swap_created,
            value: order.displayCreatedDate(),
            valueColor: UIColor.white
        )
        visibleRows.append(createdRow)

        if order.isActive() {
            let expiresRow = makeDetailRow(
                label: Localizable.shared.strings.asset_swap_expires_in,
                value: order.displayExpiresIn(),
                valueColor: viewModel.isExpiringSoon ? UIColor.main.coral : UIColor.white
            )
            visibleRows.append(expiresRow)
        }

        let primaryStack = UIStackView(arrangedSubviews: visibleRows)
        primaryStack.translatesAutoresizingMaskIntoConstraints = false
        primaryStack.axis = .vertical
        primaryStack.spacing = 0
        addRowSeparators(to: primaryStack)
        detailsCard.addSubview(primaryStack)

        // Disclosure
        let disclosure = makeDisclosureRow()
        detailsCard.addSubview(disclosure)

        // Technical section (initially hidden)
        technicalContainer.translatesAutoresizingMaskIntoConstraints = false
        technicalContainer.isHidden = true
        technicalContainer.alpha = 0
        detailsCard.addSubview(technicalContainer)

        var techRows: [UIView] = []

        if !order.sbbsID.isEmpty {
            techRows.append(makeCopyableRow(
                label: Localizable.shared.strings.asset_swap_peer_id,
                value: order.sbbsID,
                copyToast: Localizable.shared.strings.copied_to_clipboard
            ))
        }
        techRows.append(makeCopyableRow(
            label: Localizable.shared.strings.asset_swap_order_id,
            value: order.orderID,
            copyToast: Localizable.shared.strings.copied_to_clipboard
        ))

        let techStack = UIStackView(arrangedSubviews: techRows)
        techStack.translatesAutoresizingMaskIntoConstraints = false
        techStack.axis = .vertical
        techStack.spacing = 0
        addRowSeparators(to: techStack)

        let techTopSeparator = UIView()
        techTopSeparator.translatesAutoresizingMaskIntoConstraints = false
        techTopSeparator.backgroundColor = UIColor.main.marineOriginal.withAlphaComponent(0.4)

        technicalContainer.addSubview(techTopSeparator)
        technicalContainer.addSubview(techStack)

        NSLayoutConstraint.activate([
            techTopSeparator.leadingAnchor.constraint(equalTo: technicalContainer.leadingAnchor, constant: 16),
            techTopSeparator.trailingAnchor.constraint(equalTo: technicalContainer.trailingAnchor, constant: -16),
            techTopSeparator.topAnchor.constraint(equalTo: technicalContainer.topAnchor),
            techTopSeparator.heightAnchor.constraint(equalToConstant: 1),

            techStack.leadingAnchor.constraint(equalTo: technicalContainer.leadingAnchor),
            techStack.trailingAnchor.constraint(equalTo: technicalContainer.trailingAnchor),
            techStack.topAnchor.constraint(equalTo: techTopSeparator.bottomAnchor),
            techStack.bottomAnchor.constraint(equalTo: technicalContainer.bottomAnchor)
        ])

        NSLayoutConstraint.activate([
            primaryStack.leadingAnchor.constraint(equalTo: detailsCard.leadingAnchor),
            primaryStack.trailingAnchor.constraint(equalTo: detailsCard.trailingAnchor),
            primaryStack.topAnchor.constraint(equalTo: detailsCard.topAnchor, constant: 6),

            disclosure.leadingAnchor.constraint(equalTo: detailsCard.leadingAnchor),
            disclosure.trailingAnchor.constraint(equalTo: detailsCard.trailingAnchor),
            disclosure.topAnchor.constraint(equalTo: primaryStack.bottomAnchor),

            technicalContainer.leadingAnchor.constraint(equalTo: detailsCard.leadingAnchor),
            technicalContainer.trailingAnchor.constraint(equalTo: detailsCard.trailingAnchor),
            technicalContainer.topAnchor.constraint(equalTo: disclosure.bottomAnchor),
            technicalContainer.bottomAnchor.constraint(equalTo: detailsCard.bottomAnchor, constant: -6)
        ])

        return detailsCard
    }

    private func makeDetailRow(label: String, value: String, valueColor: UIColor) -> UIView {
        let row = UIView()
        row.translatesAutoresizingMaskIntoConstraints = false

        let labelView = UILabel()
        labelView.translatesAutoresizingMaskIntoConstraints = false
        labelView.font = RegularFont(size: 13)
        labelView.textColor = UIColor.main.steelGrey
        labelView.text = label
        row.addSubview(labelView)

        let valueView = UILabel()
        valueView.translatesAutoresizingMaskIntoConstraints = false
        valueView.font = SemiboldFont(size: 13)
        valueView.textColor = valueColor
        valueView.text = value
        valueView.textAlignment = .right
        valueView.adjustsFontSizeToFitWidth = true
        valueView.minimumScaleFactor = 0.7
        row.addSubview(valueView)

        NSLayoutConstraint.activate([
            labelView.leadingAnchor.constraint(equalTo: row.leadingAnchor, constant: 16),
            labelView.centerYAnchor.constraint(equalTo: row.centerYAnchor),

            valueView.trailingAnchor.constraint(equalTo: row.trailingAnchor, constant: -16),
            valueView.centerYAnchor.constraint(equalTo: row.centerYAnchor),
            valueView.leadingAnchor.constraint(greaterThanOrEqualTo: labelView.trailingAnchor, constant: 12),

            row.heightAnchor.constraint(equalToConstant: 44)
        ])

        return row
    }

    private func makeCopyableRow(label: String, value: String, copyToast: String) -> UIView {
        let row = UIView()
        row.translatesAutoresizingMaskIntoConstraints = false

        let labelView = UILabel()
        labelView.translatesAutoresizingMaskIntoConstraints = false
        labelView.font = RegularFont(size: 13)
        labelView.textColor = UIColor.main.steelGrey
        labelView.text = label
        row.addSubview(labelView)

        let valueView = UILabel()
        valueView.translatesAutoresizingMaskIntoConstraints = false
        valueView.font = RegularFont(size: 11)
        valueView.textColor = UIColor.main.steelGrey
        valueView.text = value
        valueView.numberOfLines = 2
        valueView.lineBreakMode = .byTruncatingMiddle
        valueView.textAlignment = .right
        row.addSubview(valueView)

        let copyButton = UIButton(type: .system)
        copyButton.translatesAutoresizingMaskIntoConstraints = false
        copyButton.setImage(UIImage(named: "iconCopyBlue"), for: .normal)
        copyButton.tintColor = UIColor.main.brightTeal
        copyButton.contentEdgeInsets = UIEdgeInsets(top: 4, left: 4, bottom: 4, right: 4)
        copyButton.accessibilityLabel = copyToast
        copyButton.addAction(UIAction { _ in
            UIPasteboard.general.string = value
            BMToast.show(text: copyToast)
        }, for: .touchUpInside)
        row.addSubview(copyButton)

        NSLayoutConstraint.activate([
            labelView.leadingAnchor.constraint(equalTo: row.leadingAnchor, constant: 16),
            labelView.topAnchor.constraint(equalTo: row.topAnchor, constant: 12),

            copyButton.trailingAnchor.constraint(equalTo: row.trailingAnchor, constant: -10),
            copyButton.centerYAnchor.constraint(equalTo: labelView.centerYAnchor),
            copyButton.widthAnchor.constraint(equalToConstant: 28),
            copyButton.heightAnchor.constraint(equalToConstant: 28),

            valueView.leadingAnchor.constraint(equalTo: labelView.trailingAnchor, constant: 12),
            valueView.trailingAnchor.constraint(equalTo: copyButton.leadingAnchor, constant: -8),
            valueView.centerYAnchor.constraint(equalTo: labelView.centerYAnchor),

            row.bottomAnchor.constraint(equalTo: valueView.bottomAnchor, constant: 12),
            row.heightAnchor.constraint(greaterThanOrEqualToConstant: 48)
        ])

        return row
    }

    private func addRowSeparators(to stack: UIStackView) {
        let rows = stack.arrangedSubviews
        for index in 1..<rows.count {
            let separator = UIView()
            separator.translatesAutoresizingMaskIntoConstraints = false
            separator.backgroundColor = UIColor.main.marineOriginal.withAlphaComponent(0.4)
            stack.insertArrangedSubview(separator, at: index * 2 - 1)
            NSLayoutConstraint.activate([
                separator.heightAnchor.constraint(equalToConstant: 1),
                separator.leadingAnchor.constraint(equalTo: stack.leadingAnchor, constant: 16),
                separator.trailingAnchor.constraint(equalTo: stack.trailingAnchor, constant: -16)
            ])
        }
    }

    private func makeDisclosureRow() -> UIView {
        let row = UIControl()
        row.translatesAutoresizingMaskIntoConstraints = false
        row.addTarget(self, action: #selector(toggleTechnical), for: .touchUpInside)

        disclosureLabel.translatesAutoresizingMaskIntoConstraints = false
        disclosureLabel.font = SemiboldFont(size: 12)
        disclosureLabel.textColor = UIColor.main.brightTeal
        disclosureLabel.text = Localizable.shared.strings.asset_swap_show_details.uppercased()
        row.addSubview(disclosureLabel)

        disclosureChevron.translatesAutoresizingMaskIntoConstraints = false
        disclosureChevron.tintColor = UIColor.main.brightTeal
        disclosureChevron.contentMode = .scaleAspectFit
        row.addSubview(disclosureChevron)

        NSLayoutConstraint.activate([
            disclosureLabel.leadingAnchor.constraint(equalTo: row.leadingAnchor, constant: 16),
            disclosureLabel.centerYAnchor.constraint(equalTo: row.centerYAnchor),

            disclosureChevron.leadingAnchor.constraint(equalTo: disclosureLabel.trailingAnchor, constant: 6),
            disclosureChevron.centerYAnchor.constraint(equalTo: row.centerYAnchor),
            disclosureChevron.widthAnchor.constraint(equalToConstant: 12),
            disclosureChevron.heightAnchor.constraint(equalToConstant: 12),

            row.heightAnchor.constraint(equalToConstant: 44)
        ])

        return row
    }

    @objc private func toggleTechnical() {
        technicalExpanded.toggle()

        let strings = Localizable.shared.strings
        let title = (technicalExpanded ? strings.asset_swap_hide_details : strings.asset_swap_show_details).uppercased()

        UIView.animate(withDuration: 0.25) {
            self.disclosureLabel.text = title
            self.disclosureChevron.transform = self.technicalExpanded
                ? CGAffineTransform(rotationAngle: .pi)
                : .identity
            self.technicalContainer.isHidden = !self.technicalExpanded
            self.technicalContainer.alpha = self.technicalExpanded ? 1 : 0
            self.view.layoutIfNeeded()
        }
    }

    // MARK: - Footer

    private func populateFooter(_ footer: UIView) {
        if !viewModel.canAccept && !viewModel.canCancel {
            return
        }

        let separator = UIView()
        separator.translatesAutoresizingMaskIntoConstraints = false
        separator.backgroundColor = UIColor.main.marineOriginal.withAlphaComponent(0.4)
        footer.addSubview(separator)

        let leftButton = makeOutlineButton(title: Localizable.shared.strings.cancel)
        let rightButton: BMButton
        if viewModel.canCancel {
            rightButton = BMButton.defaultButton(
                frame: CGRect(x: 0, y: 0, width: 0, height: 44),
                color: UIColor.main.red
            )
            rightButton.setTitle(Localizable.shared.strings.asset_swap_cancel_order, for: .normal)
            rightButton.setTitleColor(UIColor.white, for: .normal)
            rightButton.setTitleColor(UIColor.white.withAlphaComponent(0.5), for: .highlighted)
            rightButton.titleLabel?.font = BoldFont(size: 14)
            rightButton.addTarget(self, action: #selector(onCancel), for: .touchUpInside)
        } else {
            rightButton = BMButton.defaultButton(
                frame: CGRect(x: 0, y: 0, width: 0, height: 44),
                color: UIColor.main.brightTeal
            )
            rightButton.setTitle(Localizable.shared.strings.asset_swap_accept, for: .normal)
            rightButton.setTitleColor(UIColor.main.marineOriginal, for: .normal)
            rightButton.setTitleColor(UIColor.main.marineOriginal.withAlphaComponent(0.5), for: .highlighted)
            rightButton.titleLabel?.font = BoldFont(size: 14)
            rightButton.addTarget(self, action: #selector(onAccept), for: .touchUpInside)
            acceptButton = rightButton
        }

        leftButton.addTarget(self, action: #selector(onLeftButton), for: .touchUpInside)

        leftButton.translatesAutoresizingMaskIntoConstraints = false
        rightButton.translatesAutoresizingMaskIntoConstraints = false
        footer.addSubview(leftButton)
        footer.addSubview(rightButton)

        NSLayoutConstraint.activate([
            separator.leadingAnchor.constraint(equalTo: footer.leadingAnchor),
            separator.trailingAnchor.constraint(equalTo: footer.trailingAnchor),
            separator.topAnchor.constraint(equalTo: footer.topAnchor),
            separator.heightAnchor.constraint(equalToConstant: 1),

            leftButton.leadingAnchor.constraint(equalTo: footer.leadingAnchor, constant: defaultX),
            leftButton.topAnchor.constraint(equalTo: separator.bottomAnchor, constant: 16),
            leftButton.heightAnchor.constraint(equalToConstant: 44),

            rightButton.trailingAnchor.constraint(equalTo: footer.trailingAnchor, constant: -defaultX),
            rightButton.topAnchor.constraint(equalTo: leftButton.topAnchor),
            rightButton.heightAnchor.constraint(equalToConstant: 44),

            rightButton.leadingAnchor.constraint(equalTo: leftButton.trailingAnchor, constant: defaultX),
            leftButton.widthAnchor.constraint(equalTo: rightButton.widthAnchor),

            footer.bottomAnchor.constraint(equalTo: leftButton.bottomAnchor, constant: 12)
        ])
    }

    private func makeOutlineButton(title: String) -> BMButton {
        let button = BMButton(frame: CGRect(x: 0, y: 0, width: 0, height: 44))
        button.cornerRadius = 22
        button.layer.borderWidth = 1
        button.layer.borderColor = UIColor.white.cgColor
        button.setTitle(title, for: .normal)
        button.setTitleColor(UIColor.white, for: .normal)
        button.setTitleColor(UIColor.white.withAlphaComponent(0.5), for: .highlighted)
        button.titleLabel?.font = BoldFont(size: 14)
        button.adjustFontSize = true
        button.titleEdgeInsets = .zero
        button.imageEdgeInsets = .zero
        return button
    }

    // MARK: - Actions

    @objc private func onLeftButton() {
        navigationController?.popViewController(animated: true)
    }

    @objc private func onCancel() {
        confirmAlert(
            title: Localizable.shared.strings.asset_swap_confirm_cancel,
            message: "",
            cancelTitle: Localizable.shared.strings.cancel,
            confirmTitle: Localizable.shared.strings.asset_swap_cancel_order,
            cancelHandler: { _ in },
            confirmHandler: { [weak self] _ in
                self?.viewModel.cancel()
                self?.navigationController?.popViewController(animated: true)
            }
        )
    }

    @objc private func onAccept() {
        guard !isSubmitting else { return }
        if let error = viewModel.validationError {
            alert(message: error)
            return
        }
        isSubmitting = true
        acceptButton?.isEnabled = false
        if viewModel.accept() {
            navigationController?.popViewController(animated: true)
        } else {
            isSubmitting = false
            acceptButton?.isEnabled = true
        }
    }
}
