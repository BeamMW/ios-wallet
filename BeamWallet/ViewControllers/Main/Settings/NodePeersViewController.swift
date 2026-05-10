//
// NodePeersViewController.swift
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

private class NodePeerCell: UITableViewCell {
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: .subtitle, reuseIdentifier: reuseIdentifier)
    }
    required init?(coder: NSCoder) {
        fatalError(Localizable.shared.strings.fatalInitCoderError)
    }
}

class NodePeersViewController: BaseTableViewController {

    private static let cellId = "NodePeerCell"

    private var poolAddresses: [String] = []

    private static let lastSeenFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateStyle = .none
        f.timeStyle = .medium
        return f
    }()

    override var tableStyle: UITableView.Style {
        get { return .grouped }
        set { super.tableStyle = newValue }
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        setGradientTopBar(mainColor: UIColor.main.peacockBlue, addedStatusView: AppModel.sharedManager().isLoggedin)
        title = Localizable.shared.strings.node_peers

        tableView.register(NodePeerCell.self, forCellReuseIdentifier: NodePeersViewController.cellId)
        tableView.dataSource = self
        tableView.delegate = self
        tableView.backgroundColor = UIColor.main.marine
        tableView.separatorColor = UIColor.white.withAlphaComponent(0.13)
        tableView.separatorStyle = .singleLine
        tableView.contentInsetAdjustmentBehavior = .never
        tableView.sectionHeaderHeight = UITableView.automaticDimension
        tableView.estimatedSectionHeaderHeight = 30
        tableView.sectionFooterHeight = 15
        tableView.tableHeaderView = UIView(frame: CGRect(x: 0, y: 0, width: 0, height: 20))

        reloadPool()
        AppModel.sharedManager().addDelegate(self)
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)

        if isMovingFromParent {
            AppModel.sharedManager().removeDelegate(self)
        }
    }

    private func reloadPool() {
        if Settings.sharedManager().connectToRandomNode {
            let active = Settings.sharedManager().nodeAddress ?? ""
            poolAddresses = AppModel.defaultPeerAddresses().filter { $0 != active }
        } else {
            poolAddresses = []
        }
    }

    private func statusText() -> (text: String, color: UIColor) {
        let app = AppModel.sharedManager()
        if app.isConnected {
            return (Localizable.shared.strings.node_peer_connected, UIColor.main.brightTeal)
        }
        if app.isConnecting {
            return (Localizable.shared.strings.node_peer_connecting, UIColor.main.heliotrope)
        }
        return (Localizable.shared.strings.node_peer_disconnected, UIColor.main.coral)
    }

    private func lastSeenText() -> String? {
        guard let date = AppModel.sharedManager().lastConnectionChangedAt else { return nil }
        let stamp = NodePeersViewController.lastSeenFormatter.string(from: date)
        return String(format: Localizable.shared.strings.node_peer_last_seen, stamp)
    }
}

extension NodePeersViewController: UITableViewDataSource, UITableViewDelegate {

    func numberOfSections(in tableView: UITableView) -> Int {
        return poolAddresses.isEmpty ? 1 : 2
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return section == 0 ? 1 : poolAddresses.count
    }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if section == 0 {
            return Localizable.shared.strings.node_peer_active.uppercased()
        }
        return Localizable.shared.strings.node_peer_pool.uppercased()
    }

    func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        if let header = view as? UITableViewHeaderFooterView {
            header.textLabel?.font = BoldFont(size: 13)
            header.textLabel?.textColor = Settings.sharedManager().isDarkMode ? UIColor.main.steel : UIColor.main.steelGrey
        }
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: NodePeersViewController.cellId, for: indexPath)
        cell.backgroundColor = UIColor.main.cellBackgroundColor
        cell.contentView.backgroundColor = UIColor.main.cellBackgroundColor
        cell.selectionStyle = .none
        cell.textLabel?.textColor = UIColor.white
        cell.textLabel?.font = RegularFont(size: 16)
        cell.textLabel?.numberOfLines = 0
        cell.detailTextLabel?.numberOfLines = 0
        cell.detailTextLabel?.font = RegularFont(size: 13)

        if indexPath.section == 0 {
            cell.textLabel?.text = Settings.sharedManager().nodeAddress
            let status = statusText()
            let detail = NSMutableAttributedString(
                string: status.text,
                attributes: [
                    .foregroundColor: status.color,
                    .font: BoldFont(size: 13)
                ]
            )
            if let last = lastSeenText() {
                detail.append(NSAttributedString(
                    string: "\n" + last,
                    attributes: [
                        .foregroundColor: Settings.sharedManager().isDarkMode ? UIColor.main.steel : UIColor.main.steelGrey,
                        .font: RegularFont(size: 13)
                    ]
                ))
            }
            cell.detailTextLabel?.attributedText = detail
        } else {
            cell.textLabel?.text = poolAddresses[indexPath.row]
            cell.detailTextLabel?.text = nil
        }
        return cell
    }
}

extension NodePeersViewController: WalletModelDelegate {

    private func refreshFromNetworkChange() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.reloadPool()
            self.tableView.reloadData()
        }
    }

    func onNetwotkStatusChange(_ connected: Bool) { refreshFromNetworkChange() }
    func onNetwotkStartConnecting(_ connecting: Bool) { refreshFromNetworkChange() }
    func onNetwotkStartReconnecting() { refreshFromNetworkChange() }
}
