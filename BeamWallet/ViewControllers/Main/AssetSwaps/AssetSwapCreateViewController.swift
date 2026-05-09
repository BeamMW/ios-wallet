//
// AssetSwapCreateViewController.swift
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

class AssetSwapCreateViewController: BaseViewController {

    private let viewModel = AssetSwapCreateViewModel()

    private let scrollView = UIScrollView()
    private let contentView = UIView()

    private let sendLabel = sectionLabel()
    private let sendAssetField = BMField()
    private let sendAmountField = BMField()

    private let receiveLabel = sectionLabel()
    private let receiveAssetField = BMField()
    private let receiveAmountField = BMField()

    private let expirationLabel = sectionLabel()
    private let expirationField = BMField()

    private let rateValueLabel = UILabel()
    private let errorLabel = UILabel()

    private lazy var publishButton: BMButton = {
        let button = BMButton.defaultButton(frame: CGRect(x: 0, y: 0, width: 240, height: 44), color: UIColor.main.brightTeal)
        button.setTitle(Localizable.shared.strings.asset_swap_publish.lowercased(), for: .normal)
        button.setTitleColor(UIColor.main.marineOriginal, for: .normal)
        button.setTitleColor(UIColor.main.marineOriginal.withAlphaComponent(0.5), for: .highlighted)
        button.titleLabel?.font = BoldFont(size: 14)
        button.addTarget(self, action: #selector(onPublish), for: .touchUpInside)
        return button
    }()

    override func viewDidLoad() {
        super.viewDidLoad()

        setGradientTopBar(mainColor: UIColor.main.peacockBlue, addedStatusView: true)
        title = Localizable.shared.strings.asset_swap_new

        configureLabels()
        configureFields()
        layoutForm()

        AppModel.sharedManager().addDelegate(self)
        refresh()
    }

    deinit {
        AppModel.sharedManager().removeDelegate(self)
    }

    private static func sectionLabel() -> UILabel {
        let label = UILabel()
        label.font = BoldFont(size: 14)
        label.textColor = UIColor.main.blueyGrey
        label.letterSpacing = 2
        label.adjustFontSize = true
        return label
    }

    private func configureLabels() {
        sendLabel.text = Localizable.shared.strings.asset_swap_send.uppercased()
        receiveLabel.text = Localizable.shared.strings.asset_swap_receive.uppercased()
        expirationLabel.text = Localizable.shared.strings.asset_swap_expiration.uppercased()

        rateValueLabel.font = RegularFont(size: 14)
        rateValueLabel.textColor = UIColor.main.steelGrey
        rateValueLabel.textAlignment = .center
        rateValueLabel.numberOfLines = 0

        errorLabel.font = RegularFont(size: 12)
        errorLabel.textColor = UIColor.main.red
        errorLabel.textAlignment = .center
        errorLabel.numberOfLines = 0
    }

    private func configureFields() {
        sendAssetField.placeholder = Localizable.shared.strings.asset_swap_pick_send_asset
        sendAmountField.placeholder = Localizable.shared.strings.asset_swap_send_amount
        receiveAssetField.placeholder = Localizable.shared.strings.asset_swap_pick_receive_asset
        receiveAmountField.placeholder = Localizable.shared.strings.asset_swap_receive_amount

        for field in [sendAssetField, sendAmountField, receiveAssetField, receiveAmountField, expirationField] {
            field.font = RegularFont(size: 16)
            field.tintColor = UIColor.white
            field.textColor = UIColor.white
            field.adjustFontSize = true
            field.spellCheckingType = .no
            field.autocorrectionType = .no
            field.awakeFromNib()
        }

        sendAssetField.delegate = self
        sendAssetField.clearButtonMode = .never

        sendAmountField.keyboardType = .decimalPad
        sendAmountField.addTarget(self, action: #selector(onAmountChanged), for: .editingChanged)

        receiveAssetField.delegate = self
        receiveAssetField.clearButtonMode = .never

        receiveAmountField.keyboardType = .decimalPad
        receiveAmountField.addTarget(self, action: #selector(onAmountChanged), for: .editingChanged)

        expirationField.delegate = self
        expirationField.clearButtonMode = .never
        expirationField.text = expirationDisplayString(viewModel.expirationMinutes)
    }

    private func layoutForm() {
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.keyboardDismissMode = .interactive
        view.addSubview(scrollView)

        contentView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(contentView)

        NSLayoutConstraint.activate([
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.topAnchor.constraint(equalTo: view.topAnchor, constant: navigationBarOffset),
            scrollView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),

            contentView.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor),
            contentView.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor),
        ])

        let topInset: CGFloat = 16
        let labelToFieldSpacing: CGFloat = 8
        let fieldHeight: CGFloat = 45
        let groupSpacing: CGFloat = 14
        let sectionSpacing: CGFloat = 26
        let labelHeight: CGFloat = 20

        var previousAnchor: NSLayoutYAxisAnchor = contentView.topAnchor
        var topConstant: CGFloat = topInset

        let sections: [(UILabel, [BMField])] = [
            (sendLabel, [sendAssetField, sendAmountField]),
            (receiveLabel, [receiveAssetField, receiveAmountField]),
            (expirationLabel, [expirationField]),
        ]

        for (label, fields) in sections {
            label.translatesAutoresizingMaskIntoConstraints = false
            contentView.addSubview(label)
            NSLayoutConstraint.activate([
                label.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: defaultX),
                label.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -defaultX),
                label.topAnchor.constraint(equalTo: previousAnchor, constant: topConstant),
                label.heightAnchor.constraint(equalToConstant: labelHeight),
            ])
            previousAnchor = label.bottomAnchor
            topConstant = labelToFieldSpacing

            for field in fields {
                field.translatesAutoresizingMaskIntoConstraints = false
                contentView.addSubview(field)
                NSLayoutConstraint.activate([
                    field.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: defaultX),
                    field.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -defaultX),
                    field.topAnchor.constraint(equalTo: previousAnchor, constant: topConstant),
                    field.heightAnchor.constraint(equalToConstant: fieldHeight),
                ])
                previousAnchor = field.bottomAnchor
                topConstant = groupSpacing
            }

            topConstant = sectionSpacing
        }

        rateValueLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(rateValueLabel)
        NSLayoutConstraint.activate([
            rateValueLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: defaultX),
            rateValueLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -defaultX),
            rateValueLabel.topAnchor.constraint(equalTo: previousAnchor, constant: 18),
        ])

        errorLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(errorLabel)
        NSLayoutConstraint.activate([
            errorLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: defaultX),
            errorLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -defaultX),
            errorLabel.topAnchor.constraint(equalTo: rateValueLabel.bottomAnchor, constant: 6),
        ])

        publishButton.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(publishButton)
        NSLayoutConstraint.activate([
            publishButton.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            publishButton.topAnchor.constraint(equalTo: errorLabel.bottomAnchor, constant: 30),
            publishButton.widthAnchor.constraint(equalToConstant: 240),
            publishButton.heightAnchor.constraint(equalToConstant: 44),
            publishButton.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -30),
        ])
    }

    private func refresh() {
        sendAssetField.text = viewModel.sendAsset.map { "\($0.unitName)" } ?? ""
        receiveAssetField.text = viewModel.receiveAsset.map { "\($0.unitName)" } ?? ""
        expirationField.text = expirationDisplayString(viewModel.expirationMinutes)
        rateValueLabel.text = "\(Localizable.shared.strings.asset_swap_rate): \(viewModel.displayRate())"
        errorLabel.text = viewModel.validationError ?? ""
        publishButton.isEnabled = viewModel.canSubmit
        publishButton.alpha = viewModel.canSubmit ? 1.0 : 0.5
    }

    private func expirationDisplayString(_ minutes: UInt32) -> String {
        switch minutes {
        case 60: return "1h"
        case 360: return "6h"
        case 720: return "12h"
        default:
            if minutes >= 60 { return "\(minutes / 60)h" }
            return "\(minutes)m"
        }
    }

    @objc private func onAmountChanged() {
        viewModel.sendAmountString = sendAmountField.text ?? ""
        viewModel.receiveAmountString = receiveAmountField.text ?? ""
        rateValueLabel.text = "\(Localizable.shared.strings.asset_swap_rate): \(viewModel.displayRate())"
        errorLabel.text = viewModel.validationError ?? ""
        publishButton.isEnabled = viewModel.canSubmit
        publishButton.alpha = viewModel.canSubmit ? 1.0 : 0.5
    }

    private func presentAssetPicker(currentId: Int, completion: @escaping (BMAsset) -> Void) {
        let picker = AssetSearchViewController(selectedAssetId: currentId)
        picker.completion = completion
        let nav = BaseNavigationController.navigationController(rootViewController: picker)
        nav.modalPresentationStyle = .fullScreen
        present(nav, animated: true)
    }

    @objc private func onPickSendAsset() {
        let currentId = Int(viewModel.sendAsset?.assetId ?? 0)
        presentAssetPicker(currentId: currentId) { [weak self] asset in
            self?.viewModel.sendAsset = asset
            self?.refresh()
        }
    }

    @objc private func onPickReceiveAsset() {
        let currentId = Int(viewModel.receiveAsset?.assetId ?? 0)
        presentAssetPicker(currentId: currentId) { [weak self] asset in
            self?.viewModel.receiveAsset = asset
            self?.refresh()
        }
    }

    @objc private func onPickExpiration() {
        let options: [BMOptionPickerViewController.Option] = [
            .init(title: "1 hour", value: 60),
            .init(title: "6 hours", value: 360),
            .init(title: "12 hours", value: 720),
        ]
        let picker = BMOptionPickerViewController(
            title: Localizable.shared.strings.asset_swap_expiration,
            options: options,
            selectedValue: Int(viewModel.expirationMinutes)
        ) { [weak self] selected in
            self?.viewModel.expirationMinutes = UInt32(selected.value)
            self?.refresh()
        }
        present(picker, animated: true)
    }

    @objc private func onPublish() {
        guard viewModel.canSubmit else { return }
        if viewModel.submit() {
            navigationController?.popViewController(animated: true)
        } else {
            errorLabel.text = Localizable.shared.strings.error
        }
    }
}

extension AssetSwapCreateViewController: UITextFieldDelegate {
    func textFieldShouldBeginEditing(_ textField: UITextField) -> Bool {
        if textField === sendAssetField {
            onPickSendAsset()
            return false
        }
        if textField === receiveAssetField {
            onPickReceiveAsset()
            return false
        }
        if textField === expirationField {
            onPickExpiration()
            return false
        }
        return true
    }
}

extension AssetSwapCreateViewController: WalletModelDelegate {
    func onAssetInfoChange() {
        refresh()
    }
}
