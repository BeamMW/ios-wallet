//
// UTXOViewController.swift
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

class UTXOViewController: BaseTableViewController {

    private let viewModel = UTXOViewModel()
    private var groups: [AssetUTXOGroup] = []

    private let emptyView: BMEmptyView = UIView.fromNib()
    private let hideUTXOView: BMEmptyView = UIView.fromNib()

    override func viewDidLoad() {
        tableStyle = .plain
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
        title = Localizable.shared.strings.utxo

        tableView.register([AssetAvailableCell.self])
        tableView.dataSource = self
        tableView.delegate = self
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 120

        rightButton()
    }

    deinit {
        Settings.sharedManager().removeDelegate(self)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        AppModel.sharedManager().addDelegate(self)
        AppModel.sharedManager().getUTXO()
        reloadGroups()
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

    private func reloadGroups() {
        groups = viewModel.groupedByAsset()
        emptyView.isHidden = !groups.isEmpty
        tableView.reloadData()
    }

    private func rightButton() {
        addRightButton(
            image: Settings.sharedManager().isHideAmounts ? IconShowBalance() : IconHideBalance(),
            target: self,
            selector: #selector(onHideAmounts)
        )
    }
}

extension UTXOViewController: UITableViewDataSource, UITableViewDelegate {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return groups.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let group = groups[indexPath.row]
        let cell = tableView.dequeueReusableCell(withType: AssetAvailableCell.self, for: indexPath)
        cell.setAsset(group.asset)
        cell.setUTXOAccessory(count: group.utxos.count)
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let group = groups[indexPath.row]
        let vc = AssetUTXOListViewController(assetId: group.assetId)
        pushViewController(vc: vc)
    }
}

extension UTXOViewController: SettingsModelDelegate {
    func onChangeHideAmounts() {
        rightButton()

        hideUTXOView.isHidden = !Settings.sharedManager().isHideAmounts
        tableView.isUserInteractionEnabled = !Settings.sharedManager().isHideAmounts
        tableView.reloadData()
    }
}

extension UTXOViewController: WalletModelDelegate {

    func onWalletStatusChange(_ status: BMWalletStatus) {
        DispatchQueue.main.async { [weak self] in
            self?.reloadGroups()
        }
    }

    func onReceivedUTXOs(_ utxos: [BMUTXO]) {
        DispatchQueue.main.async { [weak self] in
            self?.reloadGroups()
        }
    }
}
