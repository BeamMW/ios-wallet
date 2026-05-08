//
// AssetSearchViewController.swift
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

import UIKit

final class AssetSearchViewController: BaseViewController {

    public var completion: ((BMAsset) -> Void)?

    private let searchView = BMSearchView()
    private let tableView = UITableView()

    private var allAssets: [BMAsset] = []
    private var filtered: [BMAsset] = []
    private let initialSelectedId: Int

    init(selectedAssetId: Int) {
        self.initialSelectedId = selectedAssetId
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError(Localizable.shared.strings.fatalInitCoderError)
    }

    deinit {
        AppModel.sharedManager().removeDelegate(self)
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        setGradientTopBar(mainColor: UIColor.main.brightSkyBlue)
        title = Localizable.shared.strings.select_asset.uppercased()
        addRightButton(title: Localizable.shared.strings.cancel.lowercased(), target: self, selector: #selector(onCancel), enabled: true)

        searchView.searchField.placeholder = Localizable.shared.strings.search_assets
        searchView.onSearchTextChanged = { [weak self] text in
            self?.applyFilter(text)
        }
        searchView.onCancelSearch = { [weak self] in
            self?.applyFilter("")
        }
        view.addSubview(searchView)

        tableView.delegate = self
        tableView.dataSource = self
        tableView.backgroundColor = .clear
        tableView.separatorStyle = .none
        tableView.rowHeight = 56
        tableView.keyboardDismissMode = .onDrag
        view.addSubview(tableView)

        AppModel.sharedManager().addDelegate(self)

        AppModel.sharedManager().loadFullAssetsList()

        reloadAssets()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        let top = navigationBarOffset
        searchView.frame = CGRect(x: 0, y: top, width: view.bounds.width, height: 46)
        let tableY = searchView.frame.maxY + 6
        tableView.frame = CGRect(x: 0, y: tableY, width: view.bounds.width, height: view.bounds.height - tableY)
    }

    @objc private func onCancel() {
        dismiss(animated: true)
    }

    private func reloadAssets() {
        let assets = (AssetsManager.shared().assets as? [BMAsset]) ?? []
        let beam = assets.first(where: { $0.isBeam() })
        let others = assets.filter { !$0.isBeam() }
        allAssets = (beam.map { [$0] } ?? []) + others
        applyFilter(searchView.searchField.text ?? "")
    }

    private func applyFilter(_ text: String) {
        let q = text.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        if q.isEmpty {
            filtered = allAssets
        } else {
            filtered = allAssets.filter { asset in
                if asset.unitName.lowercased().contains(q) { return true }
                if asset.name.lowercased().contains(q) { return true }
                if asset.shortName.lowercased().contains(q) { return true }
                if String(asset.assetId).contains(q) { return true }
                return false
            }
        }
        tableView.reloadData()
    }
}

extension AssetSearchViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return filtered.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let identifier = "AssetSearchCell"
        let cell = tableView.dequeueReusableCell(withIdentifier: identifier) as? AssetSearchCell
            ?? AssetSearchCell(style: .default, reuseIdentifier: identifier)
        let asset = filtered[indexPath.row]
        cell.configure(with: asset, isSelected: Int(asset.assetId) == initialSelectedId)
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let asset = filtered[indexPath.row]
        let completion = self.completion
        dismiss(animated: true) { completion?(asset) }
    }
}

extension AssetSearchViewController: WalletModelDelegate {
    func onAssetInfoChange() {
        DispatchQueue.main.async { [weak self] in self?.reloadAssets() }
    }
}

private final class AssetSearchCell: UITableViewCell {

    private let iconView = AssetIconView()
    private let unitLabel = UILabel()
    private let idLabel = UILabel()
    private let checkmark = UIImageView()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        backgroundColor = .clear
        contentView.backgroundColor = .clear
        selectionStyle = .none

        iconView.frame = CGRect(x: 0, y: 0, width: 26, height: 26)
        iconView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(iconView)
        iconView.awakeFromNib()

        unitLabel.font = BoldFont(size: 16)
        unitLabel.textColor = .white
        unitLabel.translatesAutoresizingMaskIntoConstraints = false
        unitLabel.setContentCompressionResistancePriority(.required, for: .horizontal)
        contentView.addSubview(unitLabel)

        idLabel.font = RegularFont(size: 14)
        idLabel.textColor = UIColor.white.withAlphaComponent(0.5)
        idLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(idLabel)

        checkmark.image = UIImage(named: "iconDoneBlue")?.withRenderingMode(.alwaysTemplate)
        checkmark.tintColor = UIColor.main.brightSkyBlue
        checkmark.contentMode = .scaleAspectFit
        checkmark.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(checkmark)

        NSLayoutConstraint.activate([
            iconView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            iconView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            iconView.widthAnchor.constraint(equalToConstant: 26),
            iconView.heightAnchor.constraint(equalToConstant: 26),

            unitLabel.leadingAnchor.constraint(equalTo: iconView.trailingAnchor, constant: 12),
            unitLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),

            idLabel.leadingAnchor.constraint(equalTo: unitLabel.trailingAnchor, constant: 8),
            idLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            idLabel.trailingAnchor.constraint(lessThanOrEqualTo: checkmark.leadingAnchor, constant: -8),

            checkmark.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            checkmark.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            checkmark.widthAnchor.constraint(equalToConstant: 18),
            checkmark.heightAnchor.constraint(equalToConstant: 18),
        ])

    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func setHighlighted(_ highlighted: Bool, animated: Bool) {
        super.setHighlighted(highlighted, animated: animated)
        contentView.backgroundColor = highlighted ? UIColor.white.withAlphaComponent(0.05) : .clear
    }

    func configure(with asset: BMAsset, isSelected: Bool) {
        iconView.setAsset(asset)
        unitLabel.text = asset.unitName
        idLabel.text = "(\(asset.assetId))"
        checkmark.isHidden = !isSelected
    }
}
