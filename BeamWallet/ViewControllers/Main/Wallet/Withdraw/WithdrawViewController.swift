//
// WithdrawViewController.swift
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

class WithdrawViewController: BaseViewController {

    private var viewModel: WithdrawViewModel

    private let amountLabel = UILabel()
    private let infoLabel = UILabel()
    private let confirmButton = BMButton.defaultButton(frame: .zero, color: UIColor.main.heliotrope)
    private let cancelButton = BMButton.defaultButton(frame: .zero, color: UIColor.clear)

    init(amount: String, userId: String) {
        self.viewModel = WithdrawViewModel(amount: amount, userId: userId)
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError(Localizable.shared.strings.fatalInitCoderError)
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        setGradientTopBar(mainColor: UIColor.main.heliotrope)
        title = Localizable.shared.strings.withdraw.uppercased()

        setupLayout()
    }

    private func setupLayout() {
        amountLabel.font = UIFont.boldSystemFont(ofSize: 36)
        amountLabel.textColor = UIColor.white
        amountLabel.textAlignment = .center
        amountLabel.text = String.currency(value: viewModel.amountDouble) + " BEAM"
        amountLabel.translatesAutoresizingMaskIntoConstraints = false

        infoLabel.font = UIFont.systemFont(ofSize: 14)
        infoLabel.textColor = UIColor.main.blueyGrey
        infoLabel.textAlignment = .center
        infoLabel.numberOfLines = 0
        infoLabel.text = Localizable.shared.strings.withdraw_cofirm
        infoLabel.translatesAutoresizingMaskIntoConstraints = false

        confirmButton.setTitle(Localizable.shared.strings.confirm.lowercased(), for: .normal)
        confirmButton.setTitleColor(UIColor.main.marineOriginal, for: .normal)
        confirmButton.setTitleColor(UIColor.main.marineOriginal.withAlphaComponent(0.5), for: .highlighted)
        confirmButton.translatesAutoresizingMaskIntoConstraints = false
        confirmButton.addTarget(self, action: #selector(onConfirm), for: .touchUpInside)

        cancelButton.setTitle(Localizable.shared.strings.cancel.lowercased(), for: .normal)
        cancelButton.setTitleColor(UIColor.white, for: .normal)
        cancelButton.setTitleColor(UIColor.white.withAlphaComponent(0.5), for: .highlighted)
        cancelButton.layer.borderColor = UIColor.white.withAlphaComponent(0.3).cgColor
        cancelButton.layer.borderWidth = 1
        cancelButton.translatesAutoresizingMaskIntoConstraints = false
        cancelButton.addTarget(self, action: #selector(onCancel), for: .touchUpInside)

        view.addSubview(amountLabel)
        view.addSubview(infoLabel)
        view.addSubview(confirmButton)
        view.addSubview(cancelButton)

        NSLayoutConstraint.activate([
            amountLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            amountLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 100),
            amountLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            amountLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),

            infoLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            infoLabel.topAnchor.constraint(equalTo: amountLabel.bottomAnchor, constant: 30),
            infoLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 30),
            infoLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -30),

            confirmButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            confirmButton.bottomAnchor.constraint(equalTo: cancelButton.topAnchor, constant: -15),
            confirmButton.widthAnchor.constraint(equalToConstant: 180),
            confirmButton.heightAnchor.constraint(equalToConstant: 44),

            cancelButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            cancelButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -40),
            cancelButton.widthAnchor.constraint(equalToConstant: 180),
            cancelButton.heightAnchor.constraint(equalToConstant: 44),
        ])
    }

    @objc private func onConfirm() {
        navigationController?.popViewController(animated: true)
    }

    @objc private func onCancel() {
        navigationController?.popViewController(animated: true)
    }
}
