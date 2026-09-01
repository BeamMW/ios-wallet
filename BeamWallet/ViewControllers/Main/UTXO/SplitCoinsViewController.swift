//
// SplitCoinsViewController.swift
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

final class SplitCoinsViewController: UIViewController {

    private let viewModel: SplitCoinsViewModel

    private let backdrop = UIView()
    private let card = UIView()
    private let grabHandle = UIView()
    private let scrollView = UIScrollView()
    private let contentStack = UIStackView()

    private let titleLabel = UILabel()
    private let subtitleLabel = UILabel()
    private let balanceTitleLabel = UILabel()
    private let balanceValueLabel = UILabel()
    private let currentCoinsLabel = UILabel()
    private let stripeView = SplitCoinsStripeView()
    private let summaryLabel = UILabel()
    private let tileStack = UIStackView()
    private let warningContainer = UIView()
    private let warningLabel = UILabel()
    private let splitIntoLabel = UILabel()
    private let splitIntoStack = UIStackView()
    private let previewLabel = UILabel()
    private let previewValueLabel = UILabel()
    private let feeTitleLabel = UILabel()
    private let feeValueLabel = UILabel()
    private let previewLeadingLabel = UILabel()
    private let offlineContainer = UIView()
    private let offlineTitleLabel = UILabel()
    private let offlineHintLabel = UILabel()
    private let offlineSwitch = UISwitch()
    private let ctaButton: BMButton

    private var splitButtons: [UIButton] = []

    init(viewModel: SplitCoinsViewModel) {
        self.viewModel = viewModel
        self.ctaButton = BMButton.defaultButton(
            frame: CGRect(x: 0, y: 0, width: 100, height: 56),
            color: UIColor.main.brightTeal
        )
        super.init(nibName: nil, bundle: nil)
        modalPresentationStyle = .overFullScreen
        modalTransitionStyle = .crossDissolve
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .clear

        setupBackdrop()
        setupCard()
        setupContent()

        viewModel.onDataChanged = { [weak self] in self?.refresh() }
        viewModel.onError = { [weak self] msg in self?.alertWithMessage(msg) }
        viewModel.onSubmitted = { [weak self] in
            guard let self = self else { return }
            let message = self.viewModel.mode == .consolidate
                ? Localizable.shared.strings.consolidate_started_message
                : Localizable.shared.strings.split_started_message
            let presenter = self.presentingViewController
            self.dismissAnimated {
                presenter?.alert(message: message)
            }
        }

        viewModel.recalculateFee()
        refresh()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        view.layoutIfNeeded()
        card.transform = CGAffineTransform(translationX: 0, y: card.bounds.height)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        UIView.animate(withDuration: 0.28, delay: 0, options: [.curveEaseOut], animations: {
            self.backdrop.alpha = 1
            self.card.transform = .identity
        })
    }

    private func setupBackdrop() {
        backdrop.backgroundColor = UIColor.black.withAlphaComponent(0.55)
        backdrop.alpha = 0
        backdrop.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(backdrop)
        let tap = UITapGestureRecognizer(target: self, action: #selector(onCancel))
        backdrop.addGestureRecognizer(tap)

        NSLayoutConstraint.activate([
            backdrop.topAnchor.constraint(equalTo: view.topAnchor),
            backdrop.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            backdrop.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            backdrop.trailingAnchor.constraint(equalTo: view.trailingAnchor),
        ])
    }

    private func setupCard() {
        card.backgroundColor = UIColor.main.peacockBlue
        card.layer.cornerRadius = 16
        card.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        card.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(card)

        NSLayoutConstraint.activate([
            card.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            card.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            card.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 12),
            card.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])

        grabHandle.backgroundColor = UIColor.white.withAlphaComponent(0.25)
        grabHandle.layer.cornerRadius = 2
        grabHandle.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(grabHandle)

        let pan = UIPanGestureRecognizer(target: self, action: #selector(handleDragDown(_:)))
        pan.delegate = self
        card.addGestureRecognizer(pan)

        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.alwaysBounceVertical = true
        scrollView.showsVerticalScrollIndicator = false
        card.addSubview(scrollView)

        contentStack.axis = .vertical
        contentStack.spacing = 0
        contentStack.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(contentStack)

        let ctaTitle = viewModel.mode == .consolidate
            ? Localizable.shared.strings.consolidate_coins_cta
            : Localizable.shared.strings.split_coins_cta
        ctaButton.translatesAutoresizingMaskIntoConstraints = false
        ctaButton.setTitle(ctaTitle.uppercased(), for: .normal)
        ctaButton.setTitleColor(UIColor.main.marine, for: .normal)
        ctaButton.addTarget(self, action: #selector(onSplitTapped), for: .touchUpInside)
        card.addSubview(ctaButton)

        NSLayoutConstraint.activate([
            grabHandle.topAnchor.constraint(equalTo: card.topAnchor, constant: 8),
            grabHandle.centerXAnchor.constraint(equalTo: card.centerXAnchor),
            grabHandle.widthAnchor.constraint(equalToConstant: 36),
            grabHandle.heightAnchor.constraint(equalToConstant: 4),

            scrollView.topAnchor.constraint(equalTo: grabHandle.bottomAnchor, constant: 12),
            scrollView.leadingAnchor.constraint(equalTo: card.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: card.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: ctaButton.topAnchor, constant: -12),

            contentStack.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor),
            contentStack.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor),
            contentStack.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor, constant: 20),
            contentStack.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor, constant: -20),
            contentStack.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor, constant: -40),

            ctaButton.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 20),
            ctaButton.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -20),
            ctaButton.heightAnchor.constraint(equalToConstant: 56),
            ctaButton.bottomAnchor.constraint(equalTo: card.safeAreaLayoutGuide.bottomAnchor, constant: -16),
        ])
    }

    private func setupContent() {
        titleLabel.font = BoldFont(size: 22)
        titleLabel.textColor = UIColor.white
        contentStack.addArrangedSubview(titleLabel)

        contentStack.setCustomSpacing(8, after: titleLabel)
        subtitleLabel.font = RegularFont(size: 14)
        subtitleLabel.textColor = UIColor.main.blueyGrey
        subtitleLabel.numberOfLines = 0
        contentStack.addArrangedSubview(subtitleLabel)
        contentStack.setCustomSpacing(20, after: subtitleLabel)

        let balanceRow = UIStackView()
        balanceRow.axis = .horizontal
        balanceRow.alignment = .center
        balanceRow.distribution = .equalSpacing
        balanceTitleLabel.font = RegularFont(size: 14)
        balanceTitleLabel.textColor = UIColor.main.blueyGrey
        balanceTitleLabel.text = Localizable.shared.strings.regular_balance
        balanceValueLabel.font = BoldFont(size: 16)
        balanceValueLabel.textColor = UIColor.white
        balanceRow.addArrangedSubview(balanceTitleLabel)
        balanceRow.addArrangedSubview(balanceValueLabel)
        contentStack.addArrangedSubview(balanceRow)
        contentStack.setCustomSpacing(20, after: balanceRow)

        currentCoinsLabel.font = BoldFont(size: 11)
        currentCoinsLabel.textColor = UIColor.main.blueyGrey
        currentCoinsLabel.letterSpacing = 2
        currentCoinsLabel.text = Localizable.shared.strings.current_coins.uppercased()
        contentStack.addArrangedSubview(currentCoinsLabel)
        contentStack.setCustomSpacing(12, after: currentCoinsLabel)

        stripeView.translatesAutoresizingMaskIntoConstraints = false
        contentStack.addArrangedSubview(stripeView)
        stripeView.heightAnchor.constraint(equalToConstant: 12).isActive = true
        contentStack.setCustomSpacing(8, after: stripeView)

        summaryLabel.font = RegularFont(size: 13)
        summaryLabel.textColor = UIColor.main.blueyGrey
        summaryLabel.numberOfLines = 0
        contentStack.addArrangedSubview(summaryLabel)
        contentStack.setCustomSpacing(14, after: summaryLabel)

        tileStack.axis = .horizontal
        tileStack.alignment = .fill
        tileStack.distribution = .fillEqually
        tileStack.spacing = 8
        contentStack.addArrangedSubview(tileStack)
        contentStack.setCustomSpacing(20, after: tileStack)

        warningContainer.backgroundColor = UIColor.main.heliotrope.withAlphaComponent(0.12)
        warningContainer.layer.cornerRadius = 8
        warningContainer.translatesAutoresizingMaskIntoConstraints = false
        warningLabel.font = RegularFont(size: 12)
        warningLabel.textColor = UIColor.main.heliotrope
        warningLabel.numberOfLines = 0
        warningLabel.translatesAutoresizingMaskIntoConstraints = false
        warningContainer.addSubview(warningLabel)
        NSLayoutConstraint.activate([
            warningLabel.topAnchor.constraint(equalTo: warningContainer.topAnchor, constant: 10),
            warningLabel.bottomAnchor.constraint(equalTo: warningContainer.bottomAnchor, constant: -10),
            warningLabel.leadingAnchor.constraint(equalTo: warningContainer.leadingAnchor, constant: 12),
            warningLabel.trailingAnchor.constraint(equalTo: warningContainer.trailingAnchor, constant: -12),
        ])
        contentStack.addArrangedSubview(warningContainer)
        contentStack.setCustomSpacing(20, after: warningContainer)

        setupOfflineToggle()

        splitIntoLabel.font = BoldFont(size: 11)
        splitIntoLabel.textColor = UIColor.main.blueyGrey
        splitIntoLabel.letterSpacing = 2
        splitIntoLabel.text = Localizable.shared.strings.split_into.uppercased()
        contentStack.addArrangedSubview(splitIntoLabel)
        contentStack.setCustomSpacing(12, after: splitIntoLabel)

        splitIntoStack.axis = .horizontal
        splitIntoStack.distribution = .equalSpacing
        splitIntoStack.alignment = .center
        for count in viewModel.allowedSplitCounts {
            let btn = makeSplitCountButton(count: count)
            splitIntoStack.addArrangedSubview(btn)
            splitButtons.append(btn)
        }
        contentStack.addArrangedSubview(splitIntoStack)
        contentStack.setCustomSpacing(24, after: splitIntoStack)

        previewLabel.font = BoldFont(size: 11)
        previewLabel.textColor = UIColor.main.blueyGrey
        previewLabel.letterSpacing = 2
        previewLabel.text = Localizable.shared.strings.preview.uppercased()
        contentStack.addArrangedSubview(previewLabel)
        contentStack.setCustomSpacing(10, after: previewLabel)

        let previewRow = UIStackView()
        previewRow.axis = .horizontal
        previewRow.alignment = .center
        previewRow.distribution = .fill
        previewRow.spacing = 8
        previewLeadingLabel.font = RegularFont(size: 14)
        previewLeadingLabel.textColor = UIColor.main.blueyGrey
        previewLeadingLabel.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        previewLeadingLabel.setContentCompressionResistancePriority(.defaultHigh, for: .horizontal)
        previewValueLabel.font = BoldFont(size: 16)
        previewValueLabel.textColor = UIColor.white
        previewValueLabel.numberOfLines = 0
        previewValueLabel.textAlignment = .right
        previewValueLabel.adjustsFontSizeToFitWidth = true
        previewValueLabel.minimumScaleFactor = 0.7
        previewRow.addArrangedSubview(previewLeadingLabel)
        previewRow.addArrangedSubview(previewValueLabel)
        contentStack.addArrangedSubview(previewRow)
        contentStack.setCustomSpacing(10, after: previewRow)

        let feeRow = UIStackView()
        feeRow.axis = .horizontal
        feeRow.alignment = .center
        feeRow.distribution = .fill
        feeRow.spacing = 8
        feeTitleLabel.font = RegularFont(size: 13)
        feeTitleLabel.textColor = UIColor.main.blueyGrey
        feeTitleLabel.text = Localizable.shared.strings.fee.uppercased()
        feeTitleLabel.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        feeValueLabel.font = RegularFont(size: 13)
        feeValueLabel.textColor = UIColor.white
        feeValueLabel.textAlignment = .right
        feeRow.addArrangedSubview(feeTitleLabel)
        feeRow.addArrangedSubview(feeValueLabel)
        contentStack.addArrangedSubview(feeRow)
        contentStack.setCustomSpacing(20, after: feeRow)
    }

    private func setupOfflineToggle() {
        offlineContainer.translatesAutoresizingMaskIntoConstraints = false
        offlineContainer.backgroundColor = UIColor.white.withAlphaComponent(0.04)
        offlineContainer.layer.cornerRadius = 10

        offlineTitleLabel.font = SemiboldFont(size: 14)
        offlineTitleLabel.textColor = UIColor.white
        offlineTitleLabel.text = Localizable.shared.strings.consolidate_offline_toggle
        offlineTitleLabel.translatesAutoresizingMaskIntoConstraints = false

        offlineHintLabel.font = RegularFont(size: 12)
        offlineHintLabel.textColor = UIColor.main.blueyGrey
        offlineHintLabel.numberOfLines = 0
        offlineHintLabel.text = Localizable.shared.strings.consolidate_offline_hint
        offlineHintLabel.translatesAutoresizingMaskIntoConstraints = false

        offlineSwitch.onTintColor = UIColor.main.brightTeal
        offlineSwitch.translatesAutoresizingMaskIntoConstraints = false
        offlineSwitch.addTarget(self, action: #selector(onOfflineToggleChanged(_:)), for: .valueChanged)

        offlineContainer.addSubview(offlineTitleLabel)
        offlineContainer.addSubview(offlineHintLabel)
        offlineContainer.addSubview(offlineSwitch)

        NSLayoutConstraint.activate([
            offlineTitleLabel.topAnchor.constraint(equalTo: offlineContainer.topAnchor, constant: 12),
            offlineTitleLabel.leadingAnchor.constraint(equalTo: offlineContainer.leadingAnchor, constant: 14),
            offlineTitleLabel.trailingAnchor.constraint(lessThanOrEqualTo: offlineSwitch.leadingAnchor, constant: -8),

            offlineHintLabel.topAnchor.constraint(equalTo: offlineTitleLabel.bottomAnchor, constant: 2),
            offlineHintLabel.leadingAnchor.constraint(equalTo: offlineTitleLabel.leadingAnchor),
            offlineHintLabel.trailingAnchor.constraint(lessThanOrEqualTo: offlineSwitch.leadingAnchor, constant: -8),
            offlineHintLabel.bottomAnchor.constraint(equalTo: offlineContainer.bottomAnchor, constant: -12),

            offlineSwitch.trailingAnchor.constraint(equalTo: offlineContainer.trailingAnchor, constant: -14),
            offlineSwitch.centerYAnchor.constraint(equalTo: offlineContainer.centerYAnchor),
        ])

        contentStack.addArrangedSubview(offlineContainer)
        contentStack.setCustomSpacing(20, after: offlineContainer)
    }

    private func makeSplitCountButton(count: Int) -> UIButton {
        let btn = UIButton(type: .system)
        btn.tag = count
        btn.setTitle("\(count)", for: .normal)
        btn.titleLabel?.font = BoldFont(size: 16)
        btn.layer.cornerRadius = 22
        btn.layer.borderWidth = 1
        btn.translatesAutoresizingMaskIntoConstraints = false
        btn.widthAnchor.constraint(equalToConstant: 56).isActive = true
        btn.heightAnchor.constraint(equalToConstant: 44).isActive = true
        btn.addTarget(self, action: #selector(onSplitCountTapped(_:)), for: .touchUpInside)
        return btn
    }

    private func refresh() {
        let group = viewModel.group
        let asset = group.asset
        let isConsolidate = viewModel.mode == .consolidate

        let actionWord = isConsolidate
            ? Localizable.shared.strings.consolidate
            : Localizable.shared.strings.split
        titleLabel.text = "\(actionWord.capitalized) \(asset.unitName.uppercased())"
        subtitleLabel.text = isConsolidate
            ? Localizable.shared.strings.consolidate_coins_subtitle
            : Localizable.shared.strings.split_coins_subtitle

        balanceValueLabel.text = formattedAmount(real: asset.realAmount, unit: asset.unitName)

        stripeView.setAmounts(group.utxos.map { $0.amount })

        let countText = Localizable.shared.strings.coin_count_format
            .replacingOccurrences(of: "(count)", with: "\(group.utxos.count)")
        if isConsolidate {
            summaryLabel.text = countText
        } else {
            let largestText = formattedAmount(real: group.largestUtxo?.realAmount ?? 0, unit: asset.unitName)
            let largestRow = Localizable.shared.strings.largest_coin_format
                .replacingOccurrences(of: "(amount)", with: largestText)
            summaryLabel.text = "\(countText) · \(largestRow)"
        }

        rebuildTiles(group: group)

        if let warn = viewModel.concentrationWarning {
            warningLabel.text = warn
            warningContainer.isHidden = false
        } else {
            warningContainer.isHidden = true
        }

        // Hide the split-into selector in consolidate mode or whenever the
        // shielded toggle collapses the output to a single push.
        let hideSplitInto = isConsolidate || viewModel.isShielded
        splitIntoLabel.isHidden = hideSplitInto
        splitIntoStack.isHidden = hideSplitInto
        offlineContainer.isHidden = false
        offlineSwitch.isOn = viewModel.sendOffline

        for btn in splitButtons {
            let isSelected = btn.tag == viewModel.splitInto
            btn.backgroundColor = isSelected ? UIColor.main.brightTeal : UIColor.clear
            btn.layer.borderColor = (isSelected
                ? UIColor.main.brightTeal
                : UIColor.white.withAlphaComponent(0.18)).cgColor
            btn.setTitleColor(isSelected ? UIColor.main.marine : UIColor.white, for: .normal)
        }

        let perOutputText = formattedAmount(real: grothToBeam(viewModel.perOutputGroth), unit: asset.unitName)
        previewLeadingLabel.text = (isConsolidate || viewModel.isShielded)
            ? ""
            : "\(viewModel.splitInto)x equal"
        previewValueLabel.text = perOutputText

        feeValueLabel.text = formattedAmount(real: grothToBeam(viewModel.feeGroth), unit: "BEAM")

        ctaButton.isEnabled = viewModel.canSubmit
        ctaButton.alpha = viewModel.canSubmit ? 1 : 0.5
    }

    private func rebuildTiles(group: AssetUTXOGroup) {
        tileStack.arrangedSubviews.forEach {
            tileStack.removeArrangedSubview($0)
            $0.removeFromSuperview()
        }
        let visibleCount = min(4, group.utxos.count)
        for i in 0..<visibleCount {
            let utxo = group.utxos[i]
            let card = SplitCoinPreviewCard()
            card.configure(
                amountText: String.currencyWithoutName(value: utxo.realAmount),
                unitText: group.asset.unitName,
                color: SplitCoinsStripeView.color(forIndex: i)
            )
            tileStack.addArrangedSubview(card)
        }
        if group.utxos.count > 4 {
            let remainder = group.utxos.count - 4
            let card = SplitCoinPreviewCard()
            let label = Localizable.shared.strings.more_coins_format
                .replacingOccurrences(of: "(count)", with: "\(remainder)")
            card.configureMore(text: label)
            tileStack.addArrangedSubview(card)
        }
    }

    private func grothToBeam(_ groth: UInt64) -> Double {
        return Double(groth) / 100_000_000
    }

    private func formattedAmount(real: Double, unit: String) -> String {
        return String.currency(value: real, name: unit)
    }

    @objc private func onSplitCountTapped(_ sender: UIButton) {
        viewModel.splitInto = sender.tag
    }

    @objc private func onOfflineToggleChanged(_ sender: UISwitch) {
        viewModel.sendOffline = sender.isOn
    }

    @objc private func onSplitTapped() {
        if Settings.sharedManager().isNeedaskPasswordForSend {
            let popover = UnlockPasswordPopover(event: .transaction)
            popover.completion = { [weak self] ok in
                if ok { self?.viewModel.submit() }
            }
            popover.modalPresentationStyle = .overFullScreen
            popover.modalTransitionStyle = .crossDissolve
            present(popover, animated: true, completion: nil)
        } else {
            viewModel.submit()
        }
    }

    @objc private func onCancel() {
        dismissAnimated(completion: nil)
    }

    @objc private func handleDragDown(_ pan: UIPanGestureRecognizer) {
        let translation = pan.translation(in: view).y
        let velocity = pan.velocity(in: view).y
        switch pan.state {
        case .changed:
            let offset = max(0, translation)
            card.transform = CGAffineTransform(translationX: 0, y: offset)
            backdrop.alpha = 1 - min(1, offset / max(1, card.bounds.height)) * 0.5
        case .ended, .cancelled:
            if translation > card.bounds.height * 0.25 || velocity > 800 {
                dismissAnimated(completion: nil)
            } else {
                UIView.animate(withDuration: 0.22, delay: 0, options: [.curveEaseOut], animations: {
                    self.card.transform = .identity
                    self.backdrop.alpha = 1
                })
            }
        default:
            break
        }
    }

    private func dismissAnimated(completion: (() -> Void)?) {
        UIView.animate(withDuration: 0.22, delay: 0, options: [.curveEaseIn], animations: {
            self.backdrop.alpha = 0
            self.card.transform = CGAffineTransform(translationX: 0, y: self.card.bounds.height)
        }, completion: { _ in
            self.dismiss(animated: false, completion: completion)
        })
    }

    private func alertWithMessage(_ message: String) {
        alert(message: message)
    }
}

extension SplitCoinsViewController: UIGestureRecognizerDelegate {
    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        guard let pan = gestureRecognizer as? UIPanGestureRecognizer else { return true }
        let velocity = pan.velocity(in: view)
        return scrollView.contentOffset.y <= 0 && velocity.y > abs(velocity.x)
    }

    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer,
                           shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
}
