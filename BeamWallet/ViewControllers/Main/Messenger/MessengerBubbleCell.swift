//
// MessengerBubbleCell.swift
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

class MessengerBubbleCell: RippleCell {

    private let bubble = UIView()
    private let label = UILabel()
    private var leadingConstraint: NSLayoutConstraint?
    private var trailingConstraint: NSLayoutConstraint?

    private static let maxBubbleRatio: CGFloat = 0.75
    private static let messageFont: UIFont = RegularFont(size: 15)
    private static let timeFont: UIFont = RegularFont(size: 11)

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        backgroundColor = .clear
        contentView.backgroundColor = .clear
        selectionStyle = .none

        bubble.translatesAutoresizingMaskIntoConstraints = false
        bubble.layer.cornerRadius = 12
        contentView.addSubview(bubble)

        label.translatesAutoresizingMaskIntoConstraints = false
        label.numberOfLines = 0
        label.lineBreakMode = .byWordWrapping
        bubble.addSubview(label)

        let leading = bubble.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16)
        let trailing = bubble.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16)
        leadingConstraint = leading
        trailingConstraint = trailing

        let maxLabelWidth = UIScreen.main.bounds.width * MessengerBubbleCell.maxBubbleRatio - 24

        NSLayoutConstraint.activate([
            bubble.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 4),
            bubble.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -4),

            label.leadingAnchor.constraint(equalTo: bubble.leadingAnchor, constant: 12),
            label.trailingAnchor.constraint(equalTo: bubble.trailingAnchor, constant: -12),
            label.topAnchor.constraint(equalTo: bubble.topAnchor, constant: 8),
            label.bottomAnchor.constraint(equalTo: bubble.bottomAnchor, constant: -8),
            label.widthAnchor.constraint(lessThanOrEqualToConstant: maxLabelWidth),
        ])
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) is not supported")
    }

    func configure(with message: BMInstantMessage) {
        let textColor: UIColor
        if message.isIncome {
            bubble.backgroundColor = UIColor.main.brightSkyBlue
            textColor = UIColor.main.marineOriginal
            leadingConstraint?.isActive = true
            trailingConstraint?.isActive = false
        } else {
            bubble.backgroundColor = UIColor.main.heliotrope
            textColor = UIColor.main.marineOriginal
            leadingConstraint?.isActive = false
            trailingConstraint?.isActive = true
        }

        let attributed = NSMutableAttributedString()
        attributed.append(NSAttributedString(
            string: message.message,
            attributes: [
                .font: MessengerBubbleCell.messageFont,
                .foregroundColor: textColor,
            ]
        ))
        attributed.append(NSAttributedString(
            string: "  \(message.formattedTime())",
            attributes: [
                .font: MessengerBubbleCell.timeFont,
                .foregroundColor: textColor.withAlphaComponent(0.55),
                .baselineOffset: -1,
            ]
        ))

        label.attributedText = attributed
    }
}
