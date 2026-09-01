//
//  DAppStoreCells.swift
//  BeamWallet
//
//  Cells used by the My DApps / DApp Store browse / Publishers screens.
//

import UIKit
import SDWebImage

private enum CellMetrics {
    static let iconSize: CGFloat = 44
    static let inset: CGFloat = 16
}

// MARK: - Installed DApp row

final class MyDAppCell: UITableViewCell {

    let iconView = UIImageView()
    let nameLabel = UILabel()
    let detailLabel = UILabel()
    let removeButton = UIButton(type: .system)
    var onRemoveTapped: (() -> Void)?

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        backgroundColor = .clear
        selectionStyle = .none

        iconView.contentMode = .scaleAspectFit
        iconView.translatesAutoresizingMaskIntoConstraints = false
        iconView.layer.cornerRadius = CellMetrics.iconSize / 2
        iconView.clipsToBounds = true
        contentView.addSubview(iconView)

        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        nameLabel.font = SemiboldFont(size: 16)
        nameLabel.textColor = .white
        contentView.addSubview(nameLabel)

        detailLabel.translatesAutoresizingMaskIntoConstraints = false
        detailLabel.font = RegularFont(size: 13)
        detailLabel.textColor = UIColor.white.withAlphaComponent(0.7)
        detailLabel.numberOfLines = 2
        contentView.addSubview(detailLabel)

        removeButton.translatesAutoresizingMaskIntoConstraints = false
        removeButton.setTitle("✕", for: .normal)
        removeButton.titleLabel?.font = SemiboldFont(size: 20)
        removeButton.tintColor = UIColor.white.withAlphaComponent(0.7)
        removeButton.setTitleColor(UIColor.white.withAlphaComponent(0.7), for: .normal)
        removeButton.addTarget(self, action: #selector(removeTapped), for: .touchUpInside)
        contentView.addSubview(removeButton)

        NSLayoutConstraint.activate([
            iconView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: CellMetrics.inset),
            iconView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            iconView.widthAnchor.constraint(equalToConstant: CellMetrics.iconSize),
            iconView.heightAnchor.constraint(equalToConstant: CellMetrics.iconSize),

            removeButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -CellMetrics.inset),
            removeButton.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            removeButton.widthAnchor.constraint(equalToConstant: 32),
            removeButton.heightAnchor.constraint(equalToConstant: 32),

            nameLabel.leadingAnchor.constraint(equalTo: iconView.trailingAnchor, constant: 12),
            nameLabel.trailingAnchor.constraint(lessThanOrEqualTo: removeButton.leadingAnchor, constant: -8),
            nameLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 12),

            detailLabel.leadingAnchor.constraint(equalTo: nameLabel.leadingAnchor),
            detailLabel.trailingAnchor.constraint(equalTo: nameLabel.trailingAnchor),
            detailLabel.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 2),
            detailLabel.bottomAnchor.constraint(lessThanOrEqualTo: contentView.bottomAnchor, constant: -12),
        ])
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func prepareForReuse() {
        super.prepareForReuse()
        iconView.image = nil
    }

    @objc private func removeTapped() { onRemoveTapped?() }

    func configure(with dapp: BMInstalledDApp) {
        nameLabel.text = dapp.name
        detailLabel.text = dapp.desc.isEmpty ? "v\(dapp.version)" : "\(dapp.desc) • v\(dapp.version)"
        DAppIconLoader.load(svg: dapp.icon, into: iconView)
    }
}

// MARK: - Store row (install / installed / update)

final class DAppStoreCell: UITableViewCell {

    enum Action {
        case install
        case installed
        case update
    }

    let iconView = UIImageView()
    let nameLabel = UILabel()
    let detailLabel = UILabel()
    let actionButton = UIButton(type: .system)
    var onActionTapped: (() -> Void)?

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        backgroundColor = .clear
        selectionStyle = .none

        iconView.contentMode = .scaleAspectFit
        iconView.translatesAutoresizingMaskIntoConstraints = false
        iconView.layer.cornerRadius = CellMetrics.iconSize / 2
        iconView.clipsToBounds = true
        contentView.addSubview(iconView)

        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        nameLabel.font = SemiboldFont(size: 16)
        nameLabel.textColor = .white
        contentView.addSubview(nameLabel)

        detailLabel.translatesAutoresizingMaskIntoConstraints = false
        detailLabel.font = RegularFont(size: 13)
        detailLabel.textColor = UIColor.white.withAlphaComponent(0.7)
        detailLabel.numberOfLines = 2
        contentView.addSubview(detailLabel)

        actionButton.translatesAutoresizingMaskIntoConstraints = false
        actionButton.titleLabel?.font = SemiboldFont(size: 13)
        actionButton.layer.cornerRadius = 14
        actionButton.contentEdgeInsets = UIEdgeInsets(top: 6, left: 12, bottom: 6, right: 12)
        actionButton.addTarget(self, action: #selector(actionTapped), for: .touchUpInside)
        contentView.addSubview(actionButton)

        NSLayoutConstraint.activate([
            iconView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: CellMetrics.inset),
            iconView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            iconView.widthAnchor.constraint(equalToConstant: CellMetrics.iconSize),
            iconView.heightAnchor.constraint(equalToConstant: CellMetrics.iconSize),

            actionButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -CellMetrics.inset),
            actionButton.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            actionButton.heightAnchor.constraint(equalToConstant: 28),

            nameLabel.leadingAnchor.constraint(equalTo: iconView.trailingAnchor, constant: 12),
            nameLabel.trailingAnchor.constraint(lessThanOrEqualTo: actionButton.leadingAnchor, constant: -8),
            nameLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 12),

            detailLabel.leadingAnchor.constraint(equalTo: nameLabel.leadingAnchor),
            detailLabel.trailingAnchor.constraint(equalTo: nameLabel.trailingAnchor),
            detailLabel.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 2),
            detailLabel.bottomAnchor.constraint(lessThanOrEqualTo: contentView.bottomAnchor, constant: -12),
        ])
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func prepareForReuse() {
        super.prepareForReuse()
        iconView.image = nil
    }

    @objc private func actionTapped() { onActionTapped?() }

    func configure(with dapp: BMAvailableDApp, action: Action) {
        nameLabel.text = dapp.name
        var detail = dapp.desc
        if !dapp.publisherName.isEmpty {
            detail = detail.isEmpty ? dapp.publisherName : "\(detail) • \(dapp.publisherName)"
        }
        detailLabel.text = detail

        DAppIconLoader.load(svg: dapp.icon, into: iconView)

        // Reset borrowed-from-recycled-state styling — `.installed` sets a border
        // that other actions don't, and would otherwise carry across reuse.
        actionButton.layer.borderColor = nil
        actionButton.layer.borderWidth = 0

        switch action {
        case .install:
            actionButton.setTitle(Localizable.shared.strings.dapps_install_label, for: .normal)
            actionButton.backgroundColor = UIColor.main.brightTeal
            actionButton.setTitleColor(.black, for: .normal)
            actionButton.isEnabled = true
        case .installed:
            actionButton.setTitle(Localizable.shared.strings.dapps_installed_label, for: .normal)
            actionButton.backgroundColor = UIColor.clear
            actionButton.setTitleColor(UIColor.white.withAlphaComponent(0.5), for: .normal)
            actionButton.layer.borderColor = UIColor.white.withAlphaComponent(0.3).cgColor
            actionButton.layer.borderWidth = 1
            actionButton.isEnabled = false
        case .update:
            actionButton.setTitle(Localizable.shared.strings.dapps_update, for: .normal)
            actionButton.backgroundColor = UIColor.main.heliotrope
            actionButton.setTitleColor(.black, for: .normal)
            actionButton.isEnabled = true
        }
    }
}

// MARK: - Sideload row

final class SideloadCell: UITableViewCell {

    let titleLabel = UILabel()
    let detailLabel = UILabel()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        backgroundColor = .clear
        accessoryType = .disclosureIndicator

        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.font = SemiboldFont(size: 15)
        titleLabel.textColor = .white
        titleLabel.text = Localizable.shared.strings.dapps_install_from_file
        contentView.addSubview(titleLabel)

        detailLabel.translatesAutoresizingMaskIntoConstraints = false
        detailLabel.font = RegularFont(size: 12)
        detailLabel.textColor = UIColor.white.withAlphaComponent(0.6)
        detailLabel.numberOfLines = 2
        detailLabel.text = Localizable.shared.strings.dapps_sideload_desc
        contentView.addSubview(detailLabel)

        NSLayoutConstraint.activate([
            titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: CellMetrics.inset),
            titleLabel.trailingAnchor.constraint(lessThanOrEqualTo: contentView.trailingAnchor, constant: -CellMetrics.inset),
            titleLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 12),

            detailLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            detailLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -CellMetrics.inset),
            detailLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 4),
            detailLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -12),
        ])
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
}

// MARK: - Publisher row

final class PublisherCell: UITableViewCell {

    let titleLabel = UILabel()
    let detailLabel = UILabel()
    let toggle = UISwitch()
    var onToggleChanged: ((Bool) -> Void)?

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        backgroundColor = .clear
        selectionStyle = .none

        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.font = SemiboldFont(size: 15)
        titleLabel.textColor = .white
        contentView.addSubview(titleLabel)

        detailLabel.translatesAutoresizingMaskIntoConstraints = false
        detailLabel.font = RegularFont(size: 12)
        detailLabel.textColor = UIColor.white.withAlphaComponent(0.6)
        detailLabel.numberOfLines = 1
        contentView.addSubview(detailLabel)

        toggle.translatesAutoresizingMaskIntoConstraints = false
        toggle.addTarget(self, action: #selector(toggleChanged), for: .valueChanged)
        contentView.addSubview(toggle)

        NSLayoutConstraint.activate([
            toggle.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -CellMetrics.inset),
            toggle.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),

            titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: CellMetrics.inset),
            titleLabel.trailingAnchor.constraint(lessThanOrEqualTo: toggle.leadingAnchor, constant: -8),
            titleLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 12),

            detailLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            detailLabel.trailingAnchor.constraint(equalTo: titleLabel.trailingAnchor),
            detailLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 2),
            detailLabel.bottomAnchor.constraint(lessThanOrEqualTo: contentView.bottomAnchor, constant: -12),
        ])
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    @objc private func toggleChanged() {
        onToggleChanged?(toggle.isOn)
    }

    func configure(with publisher: BMPublisher, allowed: Bool) {
        titleLabel.text = publisher.name
        detailLabel.text = publisher.pubkey
        toggle.setOn(allowed, animated: false)
    }
}

// MARK: - Icon loader

/// Bridges in-memory SVG bytes to a UIImageView via the project's bundled
/// SDImageSVGCoder. Falls back to the bundled DApp icon when decoding fails.
enum DAppIconLoader {
    static func load(svg: String, into view: UIImageView) {
        guard !svg.isEmpty, let data = svg.data(using: .utf8) else {
            view.image = UIImage(named: "dao_app_icon")
            return
        }
        if let image = SDImageSVGCoder.shared.decodedImage(with: data, options: nil) {
            view.image = image
        } else {
            view.image = UIImage(named: "dao_app_icon")
        }
    }
}
