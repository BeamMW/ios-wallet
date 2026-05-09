//
// BMOptionPickerViewController.swift
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

class BMOptionPickerViewController: UIViewController {

    struct Option {
        let title: String
        let value: Int
    }

    private let titleText: String
    private let options: [Option]
    private let selectedValue: Int?
    private let onSelect: (Option) -> Void

    private let backdrop = UIView()
    private let card = UIView()
    private let titleLabel = UILabel()
    private let stack = UIStackView()
    private let cancelButton = UIButton(type: .system)
    private var cardBottomConstraint: NSLayoutConstraint!

    private let rowHeight: CGFloat = 56
    private let horizontalInset: CGFloat = 16
    private let cardCornerRadius: CGFloat = 16

    init(title: String, options: [Option], selectedValue: Int?, onSelect: @escaping (Option) -> Void) {
        self.titleText = title
        self.options = options
        self.selectedValue = selectedValue
        self.onSelect = onSelect
        super.init(nibName: nil, bundle: nil)
        self.modalPresentationStyle = .overFullScreen
        self.modalTransitionStyle = .crossDissolve
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .clear

        backdrop.backgroundColor = UIColor.black.withAlphaComponent(0.55)
        backdrop.alpha = 0
        backdrop.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(backdrop)

        let tap = UITapGestureRecognizer(target: self, action: #selector(onCancel))
        backdrop.addGestureRecognizer(tap)

        card.backgroundColor = UIColor.main.peacockBlue
        card.layer.cornerRadius = cardCornerRadius
        card.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        card.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(card)

        titleLabel.text = titleText.uppercased()
        titleLabel.font = BoldFont(size: 14)
        titleLabel.textColor = UIColor.main.blueyGrey
        titleLabel.letterSpacing = 2
        titleLabel.textAlignment = .center
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(titleLabel)

        stack.axis = .vertical
        stack.spacing = 0
        stack.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(stack)

        for (index, option) in options.enumerated() {
            stack.addArrangedSubview(makeRow(for: option, index: index))
            if index < options.count - 1 {
                stack.addArrangedSubview(makeSeparator())
            }
        }

        cancelButton.setTitle(Localizable.shared.strings.cancel.lowercased(), for: .normal)
        cancelButton.titleLabel?.font = BoldFont(size: 14)
        cancelButton.setTitleColor(UIColor.white, for: .normal)
        cancelButton.setTitleColor(UIColor.white.withAlphaComponent(0.5), for: .highlighted)
        cancelButton.backgroundColor = UIColor.white.withAlphaComponent(0.08)
        cancelButton.layer.cornerRadius = 12
        cancelButton.translatesAutoresizingMaskIntoConstraints = false
        cancelButton.addTarget(self, action: #selector(onCancel), for: .touchUpInside)
        card.addSubview(cancelButton)

        cardBottomConstraint = card.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: 600)

        NSLayoutConstraint.activate([
            backdrop.topAnchor.constraint(equalTo: view.topAnchor),
            backdrop.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            backdrop.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            backdrop.trailingAnchor.constraint(equalTo: view.trailingAnchor),

            card.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            card.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            cardBottomConstraint,

            titleLabel.topAnchor.constraint(equalTo: card.topAnchor, constant: 20),
            titleLabel.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: horizontalInset),
            titleLabel.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -horizontalInset),

            stack.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 14),
            stack.leadingAnchor.constraint(equalTo: card.leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: card.trailingAnchor),

            cancelButton.topAnchor.constraint(equalTo: stack.bottomAnchor, constant: 16),
            cancelButton.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: horizontalInset),
            cancelButton.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -horizontalInset),
            cancelButton.heightAnchor.constraint(equalToConstant: 50),
            cancelButton.bottomAnchor.constraint(equalTo: card.safeAreaLayoutGuide.bottomAnchor, constant: -16),
        ])
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        view.layoutIfNeeded()
        cardBottomConstraint.constant = 0
        UIView.animate(withDuration: 0.28, delay: 0, options: [.curveEaseOut], animations: {
            self.backdrop.alpha = 1
            self.view.layoutIfNeeded()
        })
    }

    private func makeRow(for option: Option, index: Int) -> UIControl {
        let row = OptionRow()
        row.translatesAutoresizingMaskIntoConstraints = false
        row.heightAnchor.constraint(equalToConstant: rowHeight).isActive = true
        row.tag = index

        let isSelected = (selectedValue != nil && option.value == selectedValue)
        let label = UILabel()
        label.text = option.title
        label.font = isSelected ? BoldFont(size: 16) : RegularFont(size: 16)
        label.textColor = isSelected ? UIColor.main.brightTeal : UIColor.white
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        row.addSubview(label)

        NSLayoutConstraint.activate([
            label.centerYAnchor.constraint(equalTo: row.centerYAnchor),
            label.leadingAnchor.constraint(equalTo: row.leadingAnchor, constant: horizontalInset),
            label.trailingAnchor.constraint(equalTo: row.trailingAnchor, constant: -horizontalInset),
        ])

        row.addTarget(self, action: #selector(onRowTapped(_:)), for: .touchUpInside)
        return row
    }

    private func makeSeparator() -> UIView {
        let line = UIView()
        line.backgroundColor = UIColor.white.withAlphaComponent(0.08)
        line.translatesAutoresizingMaskIntoConstraints = false
        line.heightAnchor.constraint(equalToConstant: 1.0 / UIScreen.main.scale).isActive = true
        return line
    }

    @objc private func onRowTapped(_ sender: UIControl) {
        let option = options[sender.tag]
        dismissAnimated { [weak self] in
            self?.onSelect(option)
        }
    }

    @objc private func onCancel() {
        dismissAnimated(completion: nil)
    }

    private func dismissAnimated(completion: (() -> Void)?) {
        cardBottomConstraint.constant = card.bounds.height
        UIView.animate(withDuration: 0.22, delay: 0, options: [.curveEaseIn], animations: {
            self.backdrop.alpha = 0
            self.view.layoutIfNeeded()
        }, completion: { _ in
            self.dismiss(animated: false, completion: completion)
        })
    }
}

private class OptionRow: UIControl {
    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .clear
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override var isHighlighted: Bool {
        didSet {
            backgroundColor = isHighlighted ? UIColor.white.withAlphaComponent(0.06) : .clear
        }
    }
}
