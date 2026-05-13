//
//  MyDAppsViewController.swift
//  BeamWallet
//
//  Single unified surface for:
//   - the "Install from file…" sideload row,
//   - locally installed DApps with an uninstall affordance,
//   - on-chain + bundled DApps available for install, and
//   - a top-right gear that opens the Publishers blocklist.
//

import UIKit
import MobileCoreServices
import UniformTypeIdentifiers

final class MyDAppsViewController: BaseTableViewController {

    private var installed: [BMInstalledDApp] = []
    private var available: [BMAvailableDApp] = []
    private var installedVersions: [String: String] = [:]
    private var isLoadingAvailable = false

    private let sideloadCellID = "SideloadCell"
    private let installedCellID = "MyDAppCell"
    private let storeCellID = "DAppStoreCell"

    private enum Section: Int, CaseIterable {
        case sideload = 0
        case installed
        case available
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        setGradientTopBar(mainColor: UIColor.main.peacockBlue, addedStatusView: true,
                          menu: navigationController?.viewControllers.count == 1)
        title = Localizable.shared.strings.myDApps.uppercased()

        tableView.register(SideloadCell.self, forCellReuseIdentifier: sideloadCellID)
        tableView.register(MyDAppCell.self, forCellReuseIdentifier: installedCellID)
        tableView.register(DAppStoreCell.self, forCellReuseIdentifier: storeCellID)
        tableView.separatorStyle = .none
        tableView.backgroundColor = .clear
        tableView.delegate = self
        tableView.dataSource = self

        let refresher = UIRefreshControl()
        refresher.tintColor = .white
        refresher.addTarget(self, action: #selector(refreshAvailable), for: .valueChanged)
        tableView.refreshControl = refresher

        addRightButton(title: Localizable.shared.strings.dapps_publishers,
                       target: self,
                       selector: #selector(openPublishers),
                       enabled: true)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        refreshInstalled()
        if available.isEmpty { loadAvailable() }
    }

    // MARK: - Data

    private func refreshInstalled() {
        installed = DAppManager.shared.installed()
        installedVersions = Dictionary(uniqueKeysWithValues: installed.map { ($0.guid, $0.version) })
        tableView.reloadData()
    }

    @objc private func refreshAvailable() {
        loadAvailable()
    }

    private func loadAvailable() {
        if isLoadingAvailable { return }
        isLoadingAvailable = true
        DAppStore.shared.queryAvailableDApps(filterUnwanted: true) { [weak self] list in
            guard let self = self else { return }
            self.available = list.sorted { lhs, rhs in
                let lhsBundled = lhs.bundledAsset.isEmpty ? 1 : 0
                let rhsBundled = rhs.bundledAsset.isEmpty ? 1 : 0
                if lhsBundled != rhsBundled { return lhsBundled < rhsBundled }
                let lhsHasPublisher = lhs.publisherName.isEmpty ? 1 : 0
                let rhsHasPublisher = rhs.publisherName.isEmpty ? 1 : 0
                if lhsHasPublisher != rhsHasPublisher { return lhsHasPublisher < rhsHasPublisher }
                return lhs.name.localizedCaseInsensitiveCompare(rhs.name) == .orderedAscending
            }
            self.isLoadingAvailable = false
            self.tableView.refreshControl?.endRefreshing()
            self.tableView.reloadData()
        }
    }

    private func action(for dapp: BMAvailableDApp) -> DAppStoreCell.Action {
        guard let local = installedVersions[dapp.guid] else { return .install }
        return DAppStore.isVersionOlder(local, than: dapp.version) ? .update : .installed
    }

    // MARK: - Actions

    @objc private func openPublishers() {
        navigationController?.pushViewController(PublishersViewController(), animated: true)
    }

    private func launch(_ dapp: BMInstalledDApp) {
        SVProgressHUD.show()
        DAppStore.shared.checkAndUpdate(dapp) { [weak self] _ in
            guard let self = self else { return }
            SVProgressHUD.dismiss()
            let latest = DAppManager.shared.installed().first { $0.guid == dapp.guid } ?? dapp
            guard let launchURL = DAppManager.shared.launchURL(for: latest) else { return }
            let root = URL(fileURLWithPath: latest.localPath, isDirectory: true)

            let app = BMApp()
            app.name = latest.name
            app.desc = latest.desc
            app.url = launchURL.absoluteString
            app.icon = ""
            app.api_version = "current"
            app.min_api_version = ""
            app.isSupported = true

            AppModel.sharedManager().startApp(self, app: app, installedRoot: root)
        }
    }

    private func confirmRemove(_ dapp: BMInstalledDApp) {
        let message = String(format: Localizable.shared.strings.dapps_remove_confirm, dapp.name)
        BMAlertViewController.present(
            from: self,
            title: nil,
            message: message,
            actions: [
                BMAlertViewController.Action(title: Localizable.shared.strings.dapps_uninstall, style: .destructive) { [weak self] in
                    DAppManager.shared.uninstall(guid: dapp.guid)
                    self?.refreshInstalled()
                },
                BMAlertViewController.Action(title: Localizable.shared.strings.cancel, style: .cancel)
            ]
        )
    }

    private func install(_ dapp: BMAvailableDApp) {
        SVProgressHUD.show()
        DAppStore.shared.install(dapp) { [weak self] installed, error in
            SVProgressHUD.dismiss()
            guard let self = self else { return }
            if let error = error {
                self.showError(message: String(format: Localizable.shared.strings.dapps_install_failed_msg, error))
                return
            }
            if let installed = installed {
                let toast = String(format: Localizable.shared.strings.dapps_installed_toast, installed.name)
                SVProgressHUD.showSuccess(withStatus: toast)
            }
            self.refreshInstalled()
        }
    }

    private func showError(message: String) {
        BMAlertViewController.present(
            from: self,
            title: nil,
            message: message,
            actions: [BMAlertViewController.Action(title: "OK", style: .default)]
        )
    }

    // MARK: - Sideload

    @objc private func pickDAppFile() {
        let picker: UIDocumentPickerViewController
        if #available(iOS 14.0, *) {
            let dappType = UTType("com.mw.beam.dapp") ?? UTType.zip
            picker = UIDocumentPickerViewController(forOpeningContentTypes: [dappType, UTType.zip])
        } else {
            picker = UIDocumentPickerViewController(documentTypes: [(kUTTypeZipArchive as String), "com.mw.beam.dapp"], in: .open)
        }
        picker.delegate = self
        picker.allowsMultipleSelection = false
        present(picker, animated: true)
    }

    private func installFromURL(_ url: URL) {
        let secured = url.startAccessingSecurityScopedResource()
        defer { if secured { url.stopAccessingSecurityScopedResource() } }
        guard let data = try? Data(contentsOf: url) else {
            showError(message: Localizable.shared.strings.dapps_sideload_invalid)
            return
        }
        do {
            _ = try DAppManager.shared.installFromZip(data: data,
                                                     fallbackName: Localizable.shared.strings.dapps_sideloaded_name,
                                                     fallbackIcon: "")
            refreshInstalled()
            SVProgressHUD.showSuccess(withStatus: Localizable.shared.strings.dapps_install_complete)
        } catch {
            showError(message: String(format: Localizable.shared.strings.dapps_install_failed_msg, "\(error)"))
        }
    }
}

extension MyDAppsViewController: UIDocumentPickerDelegate {
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        guard let url = urls.first else { return }
        installFromURL(url)
    }
}

// MARK: - Table layout

extension MyDAppsViewController: UITableViewDelegate {

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        guard let section = Section(rawValue: indexPath.section) else { return 0 }
        switch section {
        case .sideload: return 64
        case .installed: return 72
        case .available:
            return available.isEmpty ? 56 : 72
        }
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        guard let section = Section(rawValue: indexPath.section) else { return }
        switch section {
        case .sideload:
            pickDAppFile()
        case .installed:
            guard indexPath.row < installed.count else { return }
            launch(installed[indexPath.row])
        case .available:
            guard !available.isEmpty, indexPath.row < available.count else { return }
            let dapp = available[indexPath.row]
            if action(for: dapp) != .installed { install(dapp) }
        }
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        guard let sec = Section(rawValue: section) else { return nil }
        let title: String
        switch sec {
        case .sideload:
            return nil
        case .installed:
            guard !installed.isEmpty else { return nil }
            title = Localizable.shared.strings.myDApps
        case .available:
            title = Localizable.shared.strings.dapps_store_title
        }
        return makeHeader(title: title)
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        guard let sec = Section(rawValue: section) else { return 0 }
        switch sec {
        case .sideload: return 0
        case .installed: return installed.isEmpty ? 0 : 36
        case .available: return 36
        }
    }

    private func makeHeader(title: String) -> UIView {
        let container = UIView()
        container.backgroundColor = .clear
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = title.uppercased()
        label.font = SemiboldFont(size: 13)
        label.textColor = UIColor.white.withAlphaComponent(0.7)
        container.addSubview(label)
        NSLayoutConstraint.activate([
            label.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 16),
            label.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -8),
        ])
        return container
    }
}

extension MyDAppsViewController: UITableViewDataSource {

    func numberOfSections(in tableView: UITableView) -> Int { Section.allCases.count }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard let sec = Section(rawValue: section) else { return 0 }
        switch sec {
        case .sideload: return 1
        case .installed: return installed.count
        case .available:
            return available.isEmpty ? 1 : available.count
        }
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let sec = Section(rawValue: indexPath.section) else {
            return UITableViewCell(style: .default, reuseIdentifier: nil)
        }
        switch sec {
        case .sideload:
            return tableView.dequeueReusableCell(withIdentifier: sideloadCellID, for: indexPath)
        case .installed:
            let cell = tableView.dequeueReusableCell(withIdentifier: installedCellID, for: indexPath) as! MyDAppCell
            let dapp = installed[indexPath.row]
            cell.configure(with: dapp)
            cell.onRemoveTapped = { [weak self] in self?.confirmRemove(dapp) }
            return cell
        case .available:
            if available.isEmpty {
                let cell = UITableViewCell(style: .default, reuseIdentifier: "empty")
                cell.backgroundColor = .clear
                cell.selectionStyle = .none
                cell.textLabel?.text = isLoadingAvailable
                    ? Localizable.shared.strings.dapps_store_loading
                    : Localizable.shared.strings.dapps_store_no_dapps
                cell.textLabel?.textColor = UIColor.white.withAlphaComponent(0.6)
                cell.textLabel?.font = ItalicFont(size: 14)
                cell.textLabel?.textAlignment = .center
                return cell
            }
            let cell = tableView.dequeueReusableCell(withIdentifier: storeCellID, for: indexPath) as! DAppStoreCell
            let dapp = available[indexPath.row]
            let actionKind = action(for: dapp)
            cell.configure(with: dapp, action: actionKind)
            cell.onActionTapped = { [weak self] in
                if actionKind != .installed { self?.install(dapp) }
            }
            return cell
        }
    }
}
