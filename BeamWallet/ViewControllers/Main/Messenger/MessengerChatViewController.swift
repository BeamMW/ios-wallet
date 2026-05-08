//
// MessengerChatViewController.swift
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

class MessengerChatViewController: BaseViewController {

    private let viewModel: MessengerConversationViewModel
    private let contactName: String?

    private let tableView = UITableView(frame: .zero, style: .plain)
    private let inputBar = UIView()
    private let inputContainer = UIView()
    private let textView = UITextView()
    private let sendButton = UIButton(type: .custom)
    private let placeholderLabel = UILabel()

    private var inputBarBottomConstraint: NSLayoutConstraint?
    private let inputBarHeight: CGFloat = 64

    init(peerWalletId: String, contactName: String? = nil) {
        self.viewModel = MessengerConversationViewModel(peerWalletId: peerWalletId)
        self.contactName = contactName
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) is not supported")
    }

    func setMyAddress(_ walletId: String) {
        viewModel.myWalletId = walletId
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        setGradientTopBar(mainColor: UIColor.main.peacockBlue, addedStatusView: true)

        if let name = contactName, !name.isEmpty {
            title = name
        } else {
            let peer = viewModel.peerWalletId
            if peer.count > 12 {
                title = "\(peer.prefix(6))…\(peer.suffix(6))"
            } else {
                title = peer
            }
        }

        addRightButton(image: IconCancel(), target: self, selector: #selector(onDeleteChat))

        setupTable()
        setupInputBar()

        viewModel.onDataChanged = { [weak self] in
            guard let self = self else { return }
            self.tableView.reloadData()
            self.scrollToBottom(animated: true)
        }

        viewModel.load()

        NotificationCenter.default.addObserver(self, selector: #selector(onKeyboard(_:)), name: UIResponder.keyboardWillChangeFrameNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(onKeyboard(_:)), name: UIResponder.keyboardWillHideNotification, object: nil)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        viewModel.markAsRead()
        scrollToBottom(animated: false)
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    private func setupTable() {
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.dataSource = self
        tableView.delegate = self
        tableView.separatorStyle = .none
        tableView.backgroundColor = .clear
        tableView.allowsSelection = false
        tableView.estimatedRowHeight = 60
        tableView.rowHeight = UITableView.automaticDimension
        tableView.keyboardDismissMode = .interactive
        tableView.register(MessengerBubbleCell.self, forCellReuseIdentifier: "MessengerBubbleCell")
        view.addSubview(tableView)
    }

    private func setupInputBar() {
        inputBar.translatesAutoresizingMaskIntoConstraints = false
        inputBar.backgroundColor = UIColor.main.marine
        view.addSubview(inputBar)

        let topDivider = UIView()
        topDivider.translatesAutoresizingMaskIntoConstraints = false
        topDivider.backgroundColor = UIColor.white.withAlphaComponent(0.05)
        inputBar.addSubview(topDivider)

        inputContainer.translatesAutoresizingMaskIntoConstraints = false
        inputContainer.backgroundColor = UIColor.white.withAlphaComponent(0.05)
        inputContainer.layer.cornerRadius = 18
        inputBar.addSubview(inputContainer)

        textView.translatesAutoresizingMaskIntoConstraints = false
        textView.font = RegularFont(size: 15)
        textView.textColor = UIColor.white
        textView.tintColor = UIColor.white
        textView.backgroundColor = .clear
        textView.isScrollEnabled = false
        textView.delegate = self
        textView.returnKeyType = .default
        textView.textContainerInset = UIEdgeInsets(top: 11, left: 4, bottom: 11, right: 4)
        textView.textContainer.lineFragmentPadding = 0
        inputContainer.addSubview(textView)

        placeholderLabel.translatesAutoresizingMaskIntoConstraints = false
        placeholderLabel.text = Localizable.shared.strings.messenger_send_placeholder
        placeholderLabel.font = ItalicFont(size: 15)
        placeholderLabel.textColor = UIColor.white.withAlphaComponent(0.4)
        textView.addSubview(placeholderLabel)

        sendButton.translatesAutoresizingMaskIntoConstraints = false
        sendButton.backgroundColor = UIColor.main.brightTeal
        sendButton.layer.cornerRadius = 22
        sendButton.setImage(IconNextBlue(), for: .normal)
        sendButton.imageView?.contentMode = .scaleAspectFit
        sendButton.tintColor = UIColor.main.marineOriginal
        sendButton.isEnabled = false
        sendButton.alpha = 0.4
        sendButton.addTarget(self, action: #selector(onSend), for: .touchUpInside)
        inputBar.addSubview(sendButton)

        let bottom = inputBar.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        inputBarBottomConstraint = bottom

        NSLayoutConstraint.activate([
            inputBar.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            inputBar.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            bottom,

            topDivider.leadingAnchor.constraint(equalTo: inputBar.leadingAnchor),
            topDivider.trailingAnchor.constraint(equalTo: inputBar.trailingAnchor),
            topDivider.topAnchor.constraint(equalTo: inputBar.topAnchor),
            topDivider.heightAnchor.constraint(equalToConstant: 1),

            inputContainer.leadingAnchor.constraint(equalTo: inputBar.leadingAnchor, constant: defaultX),
            inputContainer.topAnchor.constraint(equalTo: inputBar.topAnchor, constant: 10),
            inputContainer.bottomAnchor.constraint(equalTo: inputBar.safeAreaLayoutGuide.bottomAnchor, constant: -10),
            inputContainer.trailingAnchor.constraint(equalTo: sendButton.leadingAnchor, constant: -10),
            inputContainer.heightAnchor.constraint(greaterThanOrEqualToConstant: 44),

            textView.leadingAnchor.constraint(equalTo: inputContainer.leadingAnchor, constant: 12),
            textView.trailingAnchor.constraint(equalTo: inputContainer.trailingAnchor, constant: -12),
            textView.topAnchor.constraint(equalTo: inputContainer.topAnchor),
            textView.bottomAnchor.constraint(equalTo: inputContainer.bottomAnchor),

            placeholderLabel.leadingAnchor.constraint(equalTo: textView.leadingAnchor),
            placeholderLabel.centerYAnchor.constraint(equalTo: textView.centerYAnchor),

            sendButton.trailingAnchor.constraint(equalTo: inputBar.trailingAnchor, constant: -defaultX),
            sendButton.bottomAnchor.constraint(equalTo: inputContainer.bottomAnchor),
            sendButton.widthAnchor.constraint(equalToConstant: 44),
            sendButton.heightAnchor.constraint(equalToConstant: 44),
        ])

        NSLayoutConstraint.activate([
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.topAnchor.constraint(equalTo: view.topAnchor, constant: navigationBarOffset),
            tableView.bottomAnchor.constraint(equalTo: inputBar.topAnchor),
        ])
    }

    private func scrollToBottom(animated: Bool) {
        let groups = sections
        guard let last = groups.last, !last.messages.isEmpty else { return }
        let indexPath = IndexPath(row: last.messages.count - 1, section: groups.count - 1)
        tableView.scrollToRow(at: indexPath, at: .bottom, animated: animated)
    }

    @objc private func onSend() {
        let text = textView.text ?? ""
        viewModel.send(text)
        textView.text = ""
        placeholderLabel.isHidden = false
        sendButton.isEnabled = false
        sendButton.alpha = 0.4
    }

    @objc private func onDeleteChat() {
        let alert = UIAlertController(title: Localizable.shared.strings.messenger_delete_chat, message: nil, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: Localizable.shared.strings.cancel, style: .cancel))
        alert.addAction(UIAlertAction(title: Localizable.shared.strings.delete, style: .destructive) { [weak self] _ in
            self?.viewModel.remove()
            self?.navigationController?.popViewController(animated: true)
        })
        present(alert, animated: true)
    }

    @objc private func onKeyboard(_ note: Notification) {
        guard let frameEnd = (note.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue,
              let duration = note.userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] as? Double else { return }

        let isHiding = note.name == UIResponder.keyboardWillHideNotification
        let frameInView = view.convert(frameEnd, from: nil)
        let bottomInset = isHiding ? 0 : max(0, view.bounds.height - frameInView.origin.y)
        inputBarBottomConstraint?.constant = -bottomInset

        UIView.animate(withDuration: duration) {
            self.view.layoutIfNeeded()
        } completion: { _ in
            self.scrollToBottom(animated: true)
        }
    }
}

private struct MessengerSection {
    let day: Date
    let title: String
    let messages: [BMInstantMessage]
}

extension MessengerChatViewController {

    fileprivate var sections: [MessengerSection] {
        let calendar = Calendar.current
        let formatter = DateFormatter()
        formatter.doesRelativeDateFormatting = true
        formatter.dateStyle = .medium
        formatter.timeStyle = .none

        var result: [MessengerSection] = []
        var currentDay: Date?
        var bucket: [BMInstantMessage] = []

        func flush() {
            if let day = currentDay, !bucket.isEmpty {
                result.append(MessengerSection(day: day, title: formatter.string(from: day), messages: bucket))
            }
        }

        for msg in viewModel.messages {
            let date = Date(timeIntervalSince1970: TimeInterval(msg.timestamp))
            let day = calendar.startOfDay(for: date)
            if currentDay == day {
                bucket.append(msg)
            } else {
                flush()
                currentDay = day
                bucket = [msg]
            }
        }
        flush()
        return result
    }
}

extension MessengerChatViewController: UITableViewDataSource, UITableViewDelegate {
    func numberOfSections(in tableView: UITableView) -> Int {
        return sections.count
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return sections[section].messages.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "MessengerBubbleCell", for: indexPath) as! MessengerBubbleCell
        cell.configure(with: sections[indexPath.section].messages[indexPath.row])
        return cell
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let container = UIView()
        container.backgroundColor = .clear

        let pill = UIView()
        pill.translatesAutoresizingMaskIntoConstraints = false
        pill.backgroundColor = Settings.sharedManager().isDarkMode
            ? UIColor.white.withAlphaComponent(0.08)
            : UIColor.black.withAlphaComponent(0.06)
        pill.layer.cornerRadius = 11
        container.addSubview(pill)

        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = sections[section].title
        label.font = BoldFont(size: 11)
        label.textColor = Settings.sharedManager().isDarkMode ? UIColor.main.steel : UIColor.main.blueyGrey
        label.textAlignment = .center
        pill.addSubview(label)

        NSLayoutConstraint.activate([
            pill.centerXAnchor.constraint(equalTo: container.centerXAnchor),
            pill.centerYAnchor.constraint(equalTo: container.centerYAnchor),
            pill.heightAnchor.constraint(equalToConstant: 22),

            label.leadingAnchor.constraint(equalTo: pill.leadingAnchor, constant: 12),
            label.trailingAnchor.constraint(equalTo: pill.trailingAnchor, constant: -12),
            label.topAnchor.constraint(equalTo: pill.topAnchor),
            label.bottomAnchor.constraint(equalTo: pill.bottomAnchor),
        ])

        return container
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 36
    }
}

extension MessengerChatViewController: UITextViewDelegate {
    func textViewDidChange(_ textView: UITextView) {
        let trimmed = textView.text.trimmingCharacters(in: .whitespacesAndNewlines)
        let canSend = !trimmed.isEmpty && (viewModel.myWalletId?.isEmpty == false)
        sendButton.isEnabled = canSend
        sendButton.alpha = canSend ? 1.0 : 0.4
        placeholderLabel.isHidden = !textView.text.isEmpty
    }
}
