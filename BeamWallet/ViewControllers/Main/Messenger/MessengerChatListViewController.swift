//
// MessengerChatListViewController.swift
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

class MessengerChatListViewController: BaseTableViewController {

    private let viewModel = MessengerChatListViewModel()
    private let emptyLabel = UILabel()

    override func viewDidLoad() {
        super.viewDidLoad()

        setGradientTopBar(mainColor: UIColor.main.peacockBlue, addedStatusView: true, menu: self.navigationController?.viewControllers.count == 1)

        title = Localizable.shared.strings.messenger

        addRightButton(image: IconAdd(), target: self, selector: #selector(onNewChat))

        tableView.delegate = self
        tableView.dataSource = self
        tableView.separatorStyle = .none
        tableView.tableHeaderView = UIView(frame: CGRect(x: 0, y: 0, width: 0, height: 10))
        tableView.register(MessengerChatCell.self, forCellReuseIdentifier: "MessengerChatCell")
        tableView.addPullToRefresh(target: self, handler: #selector(refresh(_:)))

        emptyLabel.text = Localizable.shared.strings.messenger_no_chats
        emptyLabel.textAlignment = .center
        emptyLabel.numberOfLines = 0
        emptyLabel.font = RegularFont(size: 16)
        emptyLabel.textColor = Settings.sharedManager().isDarkMode ? UIColor.main.steel : UIColor.main.blueyGrey
        view.addSubview(emptyLabel)

        viewModel.onDataChanged = { [weak self] in
            self?.tableView.stopRefreshing()
            self?.tableView.reloadData()
            self?.updateEmptyState()
        }

        viewModel.reload()
        updateEmptyState()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        viewModel.reload()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        emptyLabel.frame = CGRect(x: 20, y: navigationBarOffset + 80, width: view.bounds.width - 40, height: 60)
    }

    private func updateEmptyState() {
        emptyLabel.isHidden = !viewModel.chats.isEmpty
    }

    @objc private func onNewChat() {
        pushViewController(vc: MessengerNewChatViewController())
    }

    @objc private func refresh(_ sender: Any) {
        viewModel.reload()
    }
}

extension MessengerChatListViewController: UITableViewDelegate, UITableViewDataSource {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.chats.count
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return viewModel.chats[indexPath.row].hasUnread ? 80 : 70
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "MessengerChatCell", for: indexPath) as! MessengerChatCell
        cell.configure(with: viewModel.chats[indexPath.row], row: indexPath.row)
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let chat = viewModel.chats[indexPath.row]
        let vc = MessengerChatViewController(peerWalletId: chat.peerWalletId, contactName: chat.contactName)
        if let myId = chat.myWalletId, !myId.isEmpty {
            vc.setMyAddress(myId)
        }
        pushViewController(vc: vc)
    }

    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }

    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let action = UIContextualAction(style: .destructive, title: Localizable.shared.strings.delete) { [weak self] _, _, completion in
            self?.viewModel.remove(at: indexPath.row)
            completion(true)
        }
        return UISwipeActionsConfiguration(actions: [action])
    }
}
