//
// ReceiveAddressButtonsCell.swift
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

class ReceiveAddressButtonsCell: BaseCell {
    @IBOutlet private var infoLabel: UILabel!

    weak var delegate: BMCellProtocol?

    private lazy var copyButton: BMButton = {
        let button = BMButton.defaultButton(frame: CGRect(x: 0, y: 0, width: 240, height: 44), color: UIColor.main.brightSkyBlue)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setImage(IconCopyBlue(), for: .normal)
        button.setTitle(Localizable.shared.strings.copy_address_close.lowercased(), for: .normal)
        button.setTitleColor(UIColor.main.marineOriginal, for: .normal)
        button.setTitleColor(UIColor.main.marineOriginal.withAlphaComponent(0.5), for: .highlighted)
        button.addTarget(self, action: #selector(onCopyAndClose), for: .touchUpInside)
        return button
    }()

    override func awakeFromNib() {
        super.awakeFromNib()

        allowHighlighted = false

        selectionStyle = .none

        if Settings.sharedManager().isDarkMode {
            infoLabel.textColor = UIColor.main.steel
        }
        else {
            infoLabel.textColor = UIColor.main.blueyGrey
        }

        contentView.addSubview(copyButton)
        NSLayoutConstraint.activate([
            copyButton.topAnchor.constraint(equalTo: infoLabel.bottomAnchor, constant: 24),
            copyButton.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            copyButton.widthAnchor.constraint(equalToConstant: 240),
            copyButton.heightAnchor.constraint(equalToConstant: 44),
            copyButton.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -24),
        ])
    }


    public func setText(text:String) {
        infoLabel.text = text
    }

    @objc private func onCopyAndClose() {
        delegate?.onClickCopyAndClose?()
    }
}
