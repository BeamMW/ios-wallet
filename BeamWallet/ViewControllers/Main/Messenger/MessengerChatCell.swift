//
// MessengerChatCell.swift
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

class MessengerChatCell: RippleCell {

    private let mainView = UIView()
    private let avatarView = UIView()
    private let avatarLabel = UILabel()
    private let nameLabel = UILabel()
    private let previewLabel = UILabel()
    private let dateLabel = UILabel()
    private let unreadDot = UIView()

    private var topConstraint: NSLayoutConstraint!
    private var bottomConstraint: NSLayoutConstraint!

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        backgroundColor = .clear
        contentView.backgroundColor = .clear
        selectionStyle = .none

        mainView.translatesAutoresizingMaskIntoConstraints = false
        mainView.layer.cornerRadius = 0
        contentView.addSubview(mainView)

        avatarView.translatesAutoresizingMaskIntoConstraints = false
        avatarView.backgroundColor = UIColor.main.brightTeal.withAlphaComponent(0.18)
        avatarView.layer.cornerRadius = 20
        mainView.addSubview(avatarView)

        avatarLabel.translatesAutoresizingMaskIntoConstraints = false
        avatarLabel.font = BoldFont(size: 16)
        avatarLabel.textColor = UIColor.main.brightTeal
        avatarLabel.textAlignment = .center
        avatarView.addSubview(avatarLabel)

        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        nameLabel.font = BoldFont(size: 15)
        nameLabel.textColor = UIColor.white
        mainView.addSubview(nameLabel)

        previewLabel.translatesAutoresizingMaskIntoConstraints = false
        previewLabel.font = RegularFont(size: 13)
        previewLabel.textColor = UIColor.main.steelGrey
        previewLabel.numberOfLines = 1
        previewLabel.lineBreakMode = .byTruncatingTail
        mainView.addSubview(previewLabel)

        dateLabel.translatesAutoresizingMaskIntoConstraints = false
        dateLabel.font = RegularFont(size: 12)
        dateLabel.textColor = UIColor.main.steelGrey
        dateLabel.textAlignment = .right
        mainView.addSubview(dateLabel)

        unreadDot.translatesAutoresizingMaskIntoConstraints = false
        unreadDot.backgroundColor = UIColor.main.brightTeal
        unreadDot.layer.cornerRadius = 4
        unreadDot.isHidden = true
        mainView.addSubview(unreadDot)

        topConstraint = mainView.topAnchor.constraint(equalTo: contentView.topAnchor)
        bottomConstraint = mainView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor)

        NSLayoutConstraint.activate([
            mainView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            mainView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            topConstraint,
            bottomConstraint,

            avatarView.leadingAnchor.constraint(equalTo: mainView.leadingAnchor, constant: defaultX),
            avatarView.centerYAnchor.constraint(equalTo: mainView.centerYAnchor),
            avatarView.widthAnchor.constraint(equalToConstant: 40),
            avatarView.heightAnchor.constraint(equalToConstant: 40),

            avatarLabel.centerXAnchor.constraint(equalTo: avatarView.centerXAnchor),
            avatarLabel.centerYAnchor.constraint(equalTo: avatarView.centerYAnchor),

            nameLabel.leadingAnchor.constraint(equalTo: avatarView.trailingAnchor, constant: 12),
            nameLabel.topAnchor.constraint(equalTo: mainView.topAnchor, constant: 12),
            nameLabel.trailingAnchor.constraint(lessThanOrEqualTo: dateLabel.leadingAnchor, constant: -8),

            dateLabel.trailingAnchor.constraint(equalTo: mainView.trailingAnchor, constant: -defaultX),
            dateLabel.centerYAnchor.constraint(equalTo: nameLabel.centerYAnchor),
            dateLabel.widthAnchor.constraint(lessThanOrEqualToConstant: 80),

            previewLabel.leadingAnchor.constraint(equalTo: nameLabel.leadingAnchor),
            previewLabel.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 4),
            previewLabel.trailingAnchor.constraint(lessThanOrEqualTo: unreadDot.leadingAnchor, constant: -8),
            previewLabel.bottomAnchor.constraint(lessThanOrEqualTo: mainView.bottomAnchor, constant: -12),

            unreadDot.trailingAnchor.constraint(equalTo: mainView.trailingAnchor, constant: -defaultX),
            unreadDot.centerYAnchor.constraint(equalTo: previewLabel.centerYAnchor),
            unreadDot.widthAnchor.constraint(equalToConstant: 8),
            unreadDot.heightAnchor.constraint(equalToConstant: 8),
        ])
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) is not supported")
    }

    func configure(with chat: BMChat, row: Int) {
        nameLabel.text = chat.displayName()
        previewLabel.text = chat.lastMessagePreview ?? ""
        dateLabel.text = chat.lastMessageTimestamp > 0
            ? formatRelativeDate(timestamp: chat.lastMessageTimestamp)
            : ""

        let initial = chat.displayName().trimmingCharacters(in: .whitespaces).first.map { String($0).uppercased() } ?? "?"
        avatarLabel.text = initial

        unreadDot.isHidden = !chat.hasUnread

        if chat.hasUnread {
            mainView.backgroundColor = UIColor.main.marineThree
            topConstraint.constant = 5
            bottomConstraint.constant = -5
        } else {
            mainView.backgroundColor = (row % 2 == 0) ? UIColor.main.cellBackgroundColor : UIColor.main.marine
            topConstraint.constant = 0
            bottomConstraint.constant = 0
        }
    }

    private func formatRelativeDate(timestamp: UInt64) -> String {
        let date = Date(timeIntervalSince1970: TimeInterval(timestamp))
        let formatter = DateFormatter()
        if Calendar.current.isDateInToday(date) {
            formatter.dateStyle = .none
            formatter.timeStyle = .short
        } else {
            formatter.dateStyle = .short
            formatter.timeStyle = .none
        }
        return formatter.string(from: date)
    }
}
