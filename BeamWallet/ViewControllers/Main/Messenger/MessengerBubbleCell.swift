//
// MessengerBubbleCell.swift
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

class MessengerBubbleCell: RippleCell {

    private let bubble = UIView()
    private let stack = UIStackView()
    private let label = UILabel()
    private let timeLabel = UILabel()
    private var leadingConstraint: NSLayoutConstraint?
    private var trailingConstraint: NSLayoutConstraint?

    private static let maxBubbleRatio: CGFloat = 0.75

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        backgroundColor = .clear
        contentView.backgroundColor = .clear
        selectionStyle = .none

        bubble.translatesAutoresizingMaskIntoConstraints = false
        bubble.layer.cornerRadius = 12
        contentView.addSubview(bubble)

        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = RegularFont(size: 15)
        label.numberOfLines = 0
        label.lineBreakMode = .byWordWrapping
        label.textAlignment = .left

        timeLabel.translatesAutoresizingMaskIntoConstraints = false
        timeLabel.font = RegularFont(size: 11)
        timeLabel.textAlignment = .right
        timeLabel.setContentHuggingPriority(.required, for: .horizontal)
        timeLabel.setContentCompressionResistancePriority(.required, for: .horizontal)

        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.axis = .vertical
        stack.alignment = .fill
        stack.spacing = 2
        stack.addArrangedSubview(label)
        stack.addArrangedSubview(timeLabel)
        bubble.addSubview(stack)

        let leading = bubble.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16)
        let trailing = bubble.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16)
        leadingConstraint = leading
        trailingConstraint = trailing

        let maxLabelWidth = UIScreen.main.bounds.width * MessengerBubbleCell.maxBubbleRatio - 24

        NSLayoutConstraint.activate([
            bubble.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 4),
            bubble.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -4),
            bubble.widthAnchor.constraint(lessThanOrEqualTo: contentView.widthAnchor, multiplier: MessengerBubbleCell.maxBubbleRatio),

            stack.leadingAnchor.constraint(equalTo: bubble.leadingAnchor, constant: 12),
            stack.trailingAnchor.constraint(equalTo: bubble.trailingAnchor, constant: -12),
            stack.topAnchor.constraint(equalTo: bubble.topAnchor, constant: 8),
            stack.bottomAnchor.constraint(equalTo: bubble.bottomAnchor, constant: -8),

            label.widthAnchor.constraint(lessThanOrEqualToConstant: maxLabelWidth),
        ])
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) is not supported")
    }

    func configure(with message: BMInstantMessage) {
        label.text = message.message
        timeLabel.text = message.formattedTime()

        if message.isIncome {
            bubble.backgroundColor = UIColor.main.brightSkyBlue
            label.textColor = UIColor.main.marineOriginal
            timeLabel.textColor = UIColor.main.marineOriginal.withAlphaComponent(0.6)
            leadingConstraint?.isActive = true
            trailingConstraint?.isActive = false
        } else {
            bubble.backgroundColor = UIColor.main.heliotrope
            label.textColor = UIColor.main.marineOriginal
            timeLabel.textColor = UIColor.main.marineOriginal.withAlphaComponent(0.6)
            leadingConstraint?.isActive = false
            trailingConstraint?.isActive = true
        }
    }
}
