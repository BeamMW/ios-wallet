//
// MessengerNewChatViewController.swift
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

class MessengerNewChatViewController: BaseViewController {

    private let scrollView = UIScrollView()
    private let contentView = UIView()

    private let myAddressLabel = sectionLabel()
    private let myAddressField = BMField()

    private let peerLabel = sectionLabel()
    private let peerField = BMField()

    private let nameLabel = sectionLabel()
    private let nameField = BMField()

    private lazy var startButton: BMButton = {
        let button = BMButton.defaultButton(frame: CGRect(x: 0, y: 0, width: 220, height: 44), color: UIColor.main.brightTeal)
        button.setTitle(Localizable.shared.strings.messenger_start.lowercased(), for: .normal)
        button.setTitleColor(UIColor.main.marineOriginal, for: .normal)
        button.setTitleColor(UIColor.main.marineOriginal.withAlphaComponent(0.5), for: .highlighted)
        button.titleLabel?.font = BoldFont(size: 14)
        button.addTarget(self, action: #selector(onStart), for: .touchUpInside)
        return button
    }()

    private var ownAddresses: [BMAddress] = []
    private var selectedMyAddress: BMAddress?

    override func viewDidLoad() {
        super.viewDidLoad()

        setGradientTopBar(mainColor: UIColor.main.peacockBlue, addedStatusView: true)
        title = Localizable.shared.strings.messenger_new_chat

        ownAddresses = (AppModel.sharedManager().walletAddresses as? [BMAddress] ?? [])
            .filter { !$0.isExpired() }
        selectedMyAddress = ownAddresses.first

        configureLabels()
        configureFields()
        layoutForm()

        refreshMyAddressField()
        validate()
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
        myAddressLabel.text = Localizable.shared.strings.messenger_my_address.uppercased()
        peerLabel.text = Localizable.shared.strings.messenger_peer_address.uppercased()
        nameLabel.text = Localizable.shared.strings.messenger_contact_name.uppercased()
    }

    private func configureFields() {
        for field in [myAddressField, peerField, nameField] {
            field.font = RegularFont(size: 16)
            field.tintColor = UIColor.white
            field.textColor = UIColor.white
            field.adjustFontSize = true
            field.spellCheckingType = .no
            field.autocorrectionType = .no
        }

        myAddressField.placeholder = Localizable.shared.strings.messenger_my_address
        myAddressField.delegate = self
        myAddressField.clearButtonMode = .never
        myAddressField.awakeFromNib()

        peerField.placeholder = Localizable.shared.strings.messenger_peer_address
        peerField.autocapitalizationType = .none
        peerField.addTarget(self, action: #selector(onPeerChanged), for: .editingChanged)
        peerField.awakeFromNib()

        nameField.placeholder = Localizable.shared.strings.messenger_contact_name
        nameField.autocapitalizationType = .words
        nameField.awakeFromNib()
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
        let groupSpacing: CGFloat = 26
        let labelHeight: CGFloat = 20

        var previousAnchor: NSLayoutYAxisAnchor = contentView.topAnchor
        var topConstant: CGFloat = topInset

        for (label, field) in [(myAddressLabel, myAddressField), (peerLabel, peerField), (nameLabel, nameField)] {
            label.translatesAutoresizingMaskIntoConstraints = false
            field.translatesAutoresizingMaskIntoConstraints = false
            contentView.addSubview(label)
            contentView.addSubview(field)

            NSLayoutConstraint.activate([
                label.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: defaultX),
                label.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -defaultX),
                label.topAnchor.constraint(equalTo: previousAnchor, constant: topConstant),
                label.heightAnchor.constraint(equalToConstant: labelHeight),

                field.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: defaultX),
                field.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -defaultX),
                field.topAnchor.constraint(equalTo: label.bottomAnchor, constant: labelToFieldSpacing),
                field.heightAnchor.constraint(equalToConstant: fieldHeight),
            ])

            previousAnchor = field.bottomAnchor
            topConstant = groupSpacing
        }

        startButton.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(startButton)

        NSLayoutConstraint.activate([
            startButton.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            startButton.topAnchor.constraint(equalTo: previousAnchor, constant: 30),
            startButton.widthAnchor.constraint(equalToConstant: 220),
            startButton.heightAnchor.constraint(equalToConstant: 44),
            startButton.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -30),
        ])
    }

    private func refreshMyAddressField() {
        myAddressField.text = selectedMyAddress.map(addressTitle(for:)) ?? ""
        validate()
    }

    private func addressTitle(for addr: BMAddress) -> String {
        let label = addr.label.isEmpty ? "" : "\(addr.label) — "
        let id = addr.walletId
        let short = id.count > 12 ? "\(id.prefix(6))…\(id.suffix(6))" : id
        return "\(label)\(short)"
    }

    private func validate() {
        let peer = (peerField.text ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        let valid = !peer.isEmpty && AppModel.sharedManager().isAddress(peer) && selectedMyAddress != nil
        startButton.isEnabled = valid
        startButton.alpha = valid ? 1.0 : 0.5
    }

    @objc private func onPickMyAddress() {
        guard !ownAddresses.isEmpty else { return }
        let alert = UIAlertController(title: Localizable.shared.strings.messenger_my_address, message: nil, preferredStyle: .actionSheet)
        for addr in ownAddresses {
            alert.addAction(UIAlertAction(title: addressTitle(for: addr), style: .default) { [weak self] _ in
                self?.selectedMyAddress = addr
                self?.refreshMyAddressField()
            })
        }
        alert.addAction(UIAlertAction(title: Localizable.shared.strings.cancel, style: .cancel))
        present(alert, animated: true)
    }

    @objc private func onPeerChanged() {
        validate()
    }

    @objc private func onStart() {
        let peer = (peerField.text ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        guard !peer.isEmpty,
              AppModel.sharedManager().isAddress(peer),
              let myAddress = selectedMyAddress else { return }

        let name = (nameField.text ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        let resolvedPeer = AppModel.sharedManager().resolvedPeerWalletId(peer)

        if !name.isEmpty {
            AppModel.sharedManager().addContact(resolvedPeer, address: resolvedPeer, name: name, identidy: nil)
        }

        AppModel.sharedManager().addChatStub(resolvedPeer, contactName: name.isEmpty ? nil : name, myWalletId: myAddress.walletId)

        let chatVC = MessengerChatViewController(peerWalletId: resolvedPeer, contactName: name.isEmpty ? nil : name)
        chatVC.setMyAddress(myAddress.walletId)

        if var stack = navigationController?.viewControllers {
            stack.removeLast()
            stack.append(chatVC)
            navigationController?.setViewControllers(stack, animated: true)
        } else {
            pushViewController(vc: chatVC)
        }
    }
}

extension MessengerNewChatViewController: UITextFieldDelegate {
    func textFieldShouldBeginEditing(_ textField: UITextField) -> Bool {
        if textField === myAddressField {
            onPickMyAddress()
            return false
        }
        return true
    }
}
