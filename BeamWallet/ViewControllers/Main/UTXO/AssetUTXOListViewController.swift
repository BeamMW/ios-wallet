//
// AssetUTXOListViewController.swift
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

final class AssetUTXOListViewController: BaseTableViewController {

    private let assetId: Int32
    private var group: AssetUTXOGroup?

    private let emptyView: BMEmptyView = UIView.fromNib()
    private let hideUTXOView: BMEmptyView = UIView.fromNib()

    init(assetId: Int32) {
        self.assetId = assetId
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError(Localizable.shared.strings.fatalInitCoderError)
    }

    override func viewDidLoad() {
        tableStyle = .grouped
        super.viewDidLoad()

        Settings.sharedManager().addDelegate(self)

        hideUTXOView.text = Localizable.shared.strings.secutiry_utxo
        hideUTXOView.image = IconUTXOSecurity()

        emptyView.text = Localizable.shared.strings.utxo_empty
        emptyView.image = IconUtxoEmpty()

        emptyView.isHidden = true
        emptyView.backgroundColor = view.backgroundColor
        view.addSubview(emptyView)

        hideUTXOView.isHidden = !Settings.sharedManager().isHideAmounts
        hideUTXOView.backgroundColor = view.backgroundColor
        view.addSubview(hideUTXOView)

        setGradientTopBar(mainColor: UIColor.main.peacockBlue, addedStatusView: true)

        tableView.register([UTXOCell.self])
        tableView.dataSource = self
        tableView.delegate = self
        tableView.sectionFooterHeight = 0
        tableView.estimatedSectionFooterHeight = 0
        if #available(iOS 15.0, *) {
            tableView.sectionHeaderTopPadding = 0
        }
    }

    deinit {
        Settings.sharedManager().removeDelegate(self)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        AppModel.sharedManager().addDelegate(self)
        AppModel.sharedManager().getUTXO()
        reload()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        AppModel.sharedManager().removeDelegate(self)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        emptyView.frame = tableView.frame
        hideUTXOView.frame = tableView.frame
    }

    private func reload() {
        let match = UTXOViewModel().groupedByAsset().first { $0.assetId == assetId }
        group = match

        if let asset = match?.asset ?? AssetsManager.shared().getAsset(assetId) {
            title = asset.unitName.uppercased()
        }

        emptyView.isHidden = match != nil
        tableView.reloadData()
    }

    private func presentSheet(mode: SplitCoinsViewModel.Mode) {
        guard let group = group else { return }
        let vm = SplitCoinsViewModel(group: group, mode: mode)
        let vc = SplitCoinsViewController(viewModel: vm)
        present(vc, animated: false, completion: nil)
    }
}

extension AssetUTXOListViewController: UITableViewDataSource, UITableViewDelegate {

    func numberOfSections(in tableView: UITableView) -> Int {
        return group == nil ? 0 : 1
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return group?.utxos.count ?? 0
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let utxo = group?.utxos[indexPath.row] else { return UITableViewCell() }
        let cell = tableView
            .dequeueReusableCell(withType: UTXOCell.self, for: indexPath)
            .configured(with: (row: indexPath.row, utxo: utxo))
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        guard let utxo = group?.utxos[indexPath.row] else { return }
        let vc = UTXODetailViewController(utxo: utxo)
        pushViewController(vc: vc)
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        guard let group = group else { return nil }
        let header = AssetUTXOSectionHeaderView(group: group)
        header.onSplitTapped = { [weak self] in
            self?.presentSheet(mode: .split)
        }
        header.onConsolidateTapped = { [weak self] in
            self?.presentSheet(mode: .consolidate)
        }
        return header
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return group == nil ? CGFloat.leastNormalMagnitude : AssetUTXOSectionHeaderView.preferredHeight
    }

    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        return nil
    }

    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return CGFloat.leastNormalMagnitude
    }
}

extension AssetUTXOListViewController: SettingsModelDelegate {
    func onChangeHideAmounts() {
        hideUTXOView.isHidden = !Settings.sharedManager().isHideAmounts
        tableView.isUserInteractionEnabled = !Settings.sharedManager().isHideAmounts
        tableView.reloadData()
    }
}

extension AssetUTXOListViewController: WalletModelDelegate {

    func onWalletStatusChange(_ status: BMWalletStatus) {
        DispatchQueue.main.async { [weak self] in
            self?.reload()
        }
    }

    func onReceivedUTXOs(_ utxos: [BMUTXO]) {
        DispatchQueue.main.async { [weak self] in
            self?.reload()
        }
    }
}
