//
// BMAlertViewController.swift
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

class BMAlertViewController: UIViewController {

    enum ActionStyle {
        case `default`
        case destructive
        case cancel
    }

    struct Action {
        let title: String
        let style: ActionStyle
        let handler: (() -> Void)?

        init(title: String, style: ActionStyle, handler: (() -> Void)? = nil) {
            self.title = title
            self.style = style
            self.handler = handler
        }
    }

    private let titleText: String?
    private let messageText: String?
    private let actions: [Action]

    private let backdrop = UIView()
    private let card = UIView()
    private let titleLabel = UILabel()
    private let messageLabel = UILabel()
    private let buttonStack = UIStackView()

    private let horizontalInset: CGFloat = 32
    private let cardCornerRadius: CGFloat = 18
    private let cardPadding: CGFloat = 24
    private let buttonHeight: CGFloat = 48

    init(title: String?, message: String?, actions: [Action]) {
        self.titleText = title
        self.messageText = message
        self.actions = actions
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
        setupTitle()
        setupMessage()
        setupButtons()
        setupConstraints()
    }

    private func setupBackdrop() {
        backdrop.backgroundColor = UIColor.black.withAlphaComponent(0.6)
        backdrop.alpha = 0
        backdrop.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(backdrop)
    }

    private func setupCard() {
        card.backgroundColor = BMAlertViewController.cardBackgroundColor
        card.layer.cornerRadius = cardCornerRadius
        card.layer.borderWidth = 1
        card.layer.borderColor = UIColor.white.withAlphaComponent(0.06).cgColor
        card.layer.shadowColor = UIColor.black.cgColor
        card.layer.shadowOpacity = 0.35
        card.layer.shadowRadius = 24
        card.layer.shadowOffset = CGSize(width: 0, height: 12)
        card.alpha = 0
        card.transform = CGAffineTransform(scaleX: 0.92, y: 0.92)
        card.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(card)
    }

    private func setupTitle() {
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        guard let titleText = titleText, !titleText.isEmpty else {
            titleLabel.isHidden = true
            return
        }
        titleLabel.text = titleText
        titleLabel.font = BoldFont(size: 18)
        titleLabel.textColor = UIColor.white
        titleLabel.textAlignment = .center
        titleLabel.numberOfLines = 0
        card.addSubview(titleLabel)
    }

    private func setupMessage() {
        messageLabel.translatesAutoresizingMaskIntoConstraints = false
        guard let messageText = messageText, !messageText.isEmpty else {
            messageLabel.isHidden = true
            return
        }
        let paragraph = NSMutableParagraphStyle()
        paragraph.alignment = .center
        paragraph.lineSpacing = 3
        messageLabel.attributedText = NSAttributedString(
            string: messageText,
            attributes: [
                .font: RegularFont(size: 14),
                .foregroundColor: UIColor.white.withAlphaComponent(0.72),
                .paragraphStyle: paragraph
            ]
        )
        messageLabel.numberOfLines = 0
        card.addSubview(messageLabel)
    }

    private func setupButtons() {
        buttonStack.axis = .vertical
        buttonStack.spacing = 10
        buttonStack.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(buttonStack)

        let indexed = Array(actions.enumerated())
        let ordered = indexed.filter { $0.element.style != .cancel } + indexed.filter { $0.element.style == .cancel }

        for (originalIndex, action) in ordered {
            let button = makeButton(for: action, originalIndex: originalIndex)
            buttonStack.addArrangedSubview(button)
            button.heightAnchor.constraint(equalToConstant: buttonHeight).isActive = true
        }
    }

    private func makeButton(for action: Action, originalIndex: Int) -> UIButton {
        let button = UIButton(type: .custom)
        button.titleLabel?.font = BoldFont(size: 14)
        button.titleLabel?.adjustsFontSizeToFitWidth = true
        button.titleLabel?.minimumScaleFactor = 0.7
        button.layer.cornerRadius = buttonHeight / 2
        button.layer.masksToBounds = true
        button.setTitle(action.title, for: .normal)
        button.tag = originalIndex
        button.addTarget(self, action: #selector(onButtonTap(_:)), for: .touchUpInside)

        switch action.style {
        case .default:
            button.setTitleColor(UIColor.main.marineOriginal, for: .normal)
            button.setTitleColor(UIColor.main.marineOriginal.withAlphaComponent(0.5), for: .highlighted)
            button.setBackgroundColor(color: UIColor.main.brightTeal, forState: .normal)
            button.setBackgroundColor(color: UIColor.main.brightTeal.withAlphaComponent(0.7), forState: .highlighted)
        case .destructive:
            button.setTitleColor(UIColor.white, for: .normal)
            button.setTitleColor(UIColor.white.withAlphaComponent(0.5), for: .highlighted)
            button.setBackgroundColor(color: UIColor.main.failed, forState: .normal)
            button.setBackgroundColor(color: UIColor.main.failed.withAlphaComponent(0.7), forState: .highlighted)
        case .cancel:
            button.setTitleColor(UIColor.white, for: .normal)
            button.setTitleColor(UIColor.white.withAlphaComponent(0.5), for: .highlighted)
            button.setBackgroundColor(color: UIColor.white.withAlphaComponent(0.08), forState: .normal)
            button.setBackgroundColor(color: UIColor.white.withAlphaComponent(0.04), forState: .highlighted)
        }

        return button
    }

    private func setupConstraints() {
        var constraints: [NSLayoutConstraint] = [
            backdrop.topAnchor.constraint(equalTo: view.topAnchor),
            backdrop.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            backdrop.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            backdrop.trailingAnchor.constraint(equalTo: view.trailingAnchor),

            card.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            card.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            card.leadingAnchor.constraint(greaterThanOrEqualTo: view.leadingAnchor, constant: horizontalInset),
            card.trailingAnchor.constraint(lessThanOrEqualTo: view.trailingAnchor, constant: -horizontalInset),

            buttonStack.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: cardPadding),
            buttonStack.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -cardPadding),
            buttonStack.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -cardPadding)
        ]

        let widthCap = card.widthAnchor.constraint(equalToConstant: 320)
        widthCap.priority = .defaultHigh
        constraints.append(widthCap)

        let hasTitle = !(titleText?.isEmpty ?? true)
        let hasMessage = !(messageText?.isEmpty ?? true)

        if hasTitle {
            constraints.append(contentsOf: [
                titleLabel.topAnchor.constraint(equalTo: card.topAnchor, constant: cardPadding),
                titleLabel.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: cardPadding),
                titleLabel.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -cardPadding)
            ])
        }

        if hasMessage {
            constraints.append(contentsOf: [
                messageLabel.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: cardPadding),
                messageLabel.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -cardPadding)
            ])
            if hasTitle {
                constraints.append(messageLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 10))
            } else {
                constraints.append(messageLabel.topAnchor.constraint(equalTo: card.topAnchor, constant: cardPadding))
            }
            constraints.append(buttonStack.topAnchor.constraint(equalTo: messageLabel.bottomAnchor, constant: 22))
        } else if hasTitle {
            constraints.append(buttonStack.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 22))
        } else {
            constraints.append(buttonStack.topAnchor.constraint(equalTo: card.topAnchor, constant: cardPadding))
        }

        NSLayoutConstraint.activate(constraints)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        // Set an explicit shadowPath so iOS doesn't recompute the shadow off the layer's
        // alpha channel each frame during the spring + dismiss animations.
        card.layer.shadowPath = UIBezierPath(roundedRect: card.bounds, cornerRadius: cardCornerRadius).cgPath
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        UIView.animate(withDuration: 0.18, delay: 0, options: [.curveEaseOut], animations: {
            self.backdrop.alpha = 1
        })
        UIView.animate(
            withDuration: 0.32,
            delay: 0,
            usingSpringWithDamping: 0.85,
            initialSpringVelocity: 0.2,
            options: [.allowUserInteraction],
            animations: {
                self.card.alpha = 1
                self.card.transform = .identity
            }
        )
    }

    @objc private func onButtonTap(_ sender: UIButton) {
        guard actions.indices.contains(sender.tag) else { return }
        let action = actions[sender.tag]
        view.isUserInteractionEnabled = false
        UIView.animate(
            withDuration: 0.18,
            animations: {
                self.backdrop.alpha = 0
                self.card.alpha = 0
                self.card.transform = CGAffineTransform(scaleX: 0.96, y: 0.96)
            },
            completion: { _ in
                self.dismiss(animated: false) {
                    action.handler?()
                }
            }
        )
    }

    private static var cardBackgroundColor: UIColor {
        if Settings.sharedManager().isDarkMode {
            return UIColor(red: 36 / 255, green: 36 / 255, blue: 38 / 255, alpha: 1)
        }
        if Settings.sharedManager().target == Testnet {
            return UIColor(red: 40 / 255, green: 34 / 255, blue: 54 / 255, alpha: 1)
        }
        if Settings.sharedManager().target == Masternet {
            return UIColor(red: 28 / 255, green: 28 / 255, blue: 30 / 255, alpha: 1)
        }
        return UIColor(red: 23 / 255, green: 57 / 255, blue: 97 / 255, alpha: 1)
    }
}

extension BMAlertViewController {

    static func present(
        from presenter: UIViewController?,
        title: String?,
        message: String?,
        actions: [Action]
    ) {
        guard let presenter = presenter else { return }
        if presenter.presentedViewController is BMAlertViewController { return }
        if presenter.presentedViewController is UIAlertController { return }

        presenter.view.endEditing(true)

        let alert = BMAlertViewController(title: title, message: message, actions: actions)
        presenter.present(alert, animated: false, completion: nil)
    }
}
