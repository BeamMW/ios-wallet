//
// AssetSwapDetailsViewController.swift
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

class AssetSwapDetailsViewController: BaseViewController {

    private let viewModel: AssetSwapDetailsViewModel

    private let scrollView = UIScrollView()
    private let contentView = UIView()

    private let amountsLabel = UILabel()
    private let rateLabel = UILabel()
    private let statusValueLabel = UILabel()
    private let createdValueLabel = UILabel()
    private let expiresValueLabel = UILabel()
    private let peerValueLabel = UILabel()

    private let actionButton = BMButton.defaultButton(frame: CGRect(x: 0, y: 0, width: 240, height: 44), color: UIColor.main.brightTeal)

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

        configureLabels()
        layoutContent()
        configureActionButton()
    }

    private func configureLabels() {
        amountsLabel.font = BoldFont(size: 18)
        amountsLabel.textColor = UIColor.white
        amountsLabel.textAlignment = .center
        amountsLabel.numberOfLines = 0
        amountsLabel.text = "\(viewModel.order.displaySendAmount())\n→\n\(viewModel.order.displayReceiveAmount())"

        rateLabel.font = RegularFont(size: 14)
        rateLabel.textColor = UIColor.main.steelGrey
        rateLabel.textAlignment = .center
        rateLabel.text = viewModel.order.displayRate()

        statusValueLabel.font = SemiboldFont(size: 14)
        statusValueLabel.textColor = UIColor.main.brightTeal
        statusValueLabel.text = "\(Localizable.shared.strings.asset_swap_status): \(viewModel.order.displayStatus())"

        createdValueLabel.font = RegularFont(size: 14)
        createdValueLabel.textColor = UIColor.main.steelGrey
        createdValueLabel.text = viewModel.order.displayCreatedDate()

        expiresValueLabel.font = RegularFont(size: 14)
        expiresValueLabel.textColor = UIColor.main.steelGrey
        expiresValueLabel.text = "\(Localizable.shared.strings.asset_swap_expiration): \(viewModel.order.displayExpiresIn())"

        peerValueLabel.font = RegularFont(size: 12)
        peerValueLabel.textColor = UIColor.main.steelGrey
        peerValueLabel.numberOfLines = 0
        peerValueLabel.lineBreakMode = .byCharWrapping
        peerValueLabel.text = viewModel.order.sbbsID
    }

    private func layoutContent() {
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scrollView)

        contentView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(contentView)

        let stack = UIStackView(arrangedSubviews: [amountsLabel, rateLabel, statusValueLabel, createdValueLabel, expiresValueLabel, peerValueLabel])
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.axis = .vertical
        stack.spacing = 14
        stack.alignment = .center
        contentView.addSubview(stack)

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

            stack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: defaultX),
            stack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -defaultX),
            stack.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 28),
        ])

        actionButton.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(actionButton)
        NSLayoutConstraint.activate([
            actionButton.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            actionButton.topAnchor.constraint(equalTo: stack.bottomAnchor, constant: 36),
            actionButton.widthAnchor.constraint(equalToConstant: 240),
            actionButton.heightAnchor.constraint(equalToConstant: 44),
            actionButton.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -30),
        ])
    }

    private func configureActionButton() {
        actionButton.titleLabel?.font = BoldFont(size: 14)
        actionButton.setTitleColor(UIColor.main.marineOriginal, for: .normal)
        actionButton.setTitleColor(UIColor.main.marineOriginal.withAlphaComponent(0.5), for: .highlighted)

        if viewModel.canCancel {
            actionButton.backgroundColor = UIColor.main.red
            actionButton.setTitle(Localizable.shared.strings.asset_swap_cancel_order.lowercased(), for: .normal)
            actionButton.addTarget(self, action: #selector(onCancel), for: .touchUpInside)
        } else if viewModel.canAccept {
            actionButton.setTitle(Localizable.shared.strings.asset_swap_accept.lowercased(), for: .normal)
            actionButton.addTarget(self, action: #selector(onAccept), for: .touchUpInside)
        } else {
            actionButton.isHidden = true
        }
    }

    @objc private func onCancel() {
        let confirm = UIAlertController(title: Localizable.shared.strings.asset_swap_confirm_cancel, message: nil, preferredStyle: .alert)
        confirm.addAction(UIAlertAction(title: Localizable.shared.strings.cancel, style: .cancel))
        confirm.addAction(UIAlertAction(title: Localizable.shared.strings.asset_swap_cancel_order, style: .destructive) { [weak self] _ in
            self?.viewModel.cancel()
            self?.navigationController?.popViewController(animated: true)
        })
        present(confirm, animated: true)
    }

    @objc private func onAccept() {
        if viewModel.accept() {
            navigationController?.popViewController(animated: true)
        }
    }
}
