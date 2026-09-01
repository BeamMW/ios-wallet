//
//  PublishersViewController.swift
//  BeamWallet
//
//  Lets the user toggle each known DApp Store publisher on/off. Disabled
//  publishers' DApps are filtered out of the browse listing.
//

import UIKit

final class PublishersViewController: BaseTableViewController {

    private var publishers: [BMPublisher] = []
    private var unwanted: Set<String> = []
    private let cellID = "PublisherCell"

    override func viewDidLoad() {
        super.viewDidLoad()

        setGradientTopBar(mainColor: UIColor.main.peacockBlue, addedStatusView: true)
        title = Localizable.shared.strings.dapps_publishers.uppercased()

        tableView.register(PublisherCell.self, forCellReuseIdentifier: cellID)
        tableView.separatorStyle = .none
        tableView.backgroundColor = .clear
        tableView.delegate = self
        tableView.dataSource = self

        load()
    }

    private func load() {
        unwanted = DAppStore.shared.getUnwantedPublishers()
        SVProgressHUD.show()
        DAppStore.shared.queryPublishers { [weak self] list in
            guard let self = self else { return }
            self.publishers = list.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
            SVProgressHUD.dismiss()
            self.tableView.reloadData()
        }
    }
}

extension PublishersViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat { 64 }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let header = UILabel()
        header.text = "  " + Localizable.shared.strings.dapps_publishers_subtitle
        header.font = RegularFont(size: 13)
        header.textColor = UIColor.white.withAlphaComponent(0.6)
        header.numberOfLines = 0
        return header
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat { 48 }
}

extension PublishersViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return publishers.isEmpty ? 1 : publishers.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if publishers.isEmpty {
            let cell = UITableViewCell(style: .default, reuseIdentifier: "empty")
            cell.backgroundColor = .clear
            cell.textLabel?.text = Localizable.shared.strings.dapps_no_publishers
            cell.textLabel?.textColor = UIColor.white.withAlphaComponent(0.6)
            cell.textLabel?.textAlignment = .center
            cell.textLabel?.font = ItalicFont(size: 14)
            cell.selectionStyle = .none
            return cell
        }
        let cell = tableView.dequeueReusableCell(withIdentifier: cellID, for: indexPath) as! PublisherCell
        let publisher = publishers[indexPath.row]
        let allowed = !unwanted.contains(publisher.pubkey.lowercased())
        cell.configure(with: publisher, allowed: allowed)
        cell.onToggleChanged = { [weak self] isOn in
            guard let self = self else { return }
            if isOn {
                DAppStore.shared.removeUnwantedPublisher(publisher.pubkey)
                self.unwanted.remove(publisher.pubkey.lowercased())
            } else {
                DAppStore.shared.addUnwantedPublisher(publisher.pubkey)
                self.unwanted.insert(publisher.pubkey.lowercased())
            }
        }
        return cell
    }
}
