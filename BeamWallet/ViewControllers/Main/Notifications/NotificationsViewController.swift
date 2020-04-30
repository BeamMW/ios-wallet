//
// NotificationsViewController.swift
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

class NotificationsViewController: BaseTableViewController {

    deinit {
        Settings.sharedManager().removeDelegate(self)
    }
    
    private var viewModel = NotificationViewModel()
    private let emptyView: BMEmptyView = UIView.fromNib()
    private var buttonClear: BMButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setGradientTopBar(mainColor: UIColor.main.peacockBlue, addedStatusView: true)
        
        title = Localizable.shared.strings.notifications
        
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register([NotificationTableViewCell.self])
        tableView.tableHeaderView = UIView(frame: CGRect(x: 0, y: 0, width: 0, height: 10))
        tableView.keyboardDismissMode = .interactive
        tableView.addPullToRefresh(target: self, handler: #selector(refreshData(_:)))
        
        Settings.sharedManager().addDelegate(self)
        
        rightButton()
        
        buttonClear = BMButton.defaultButton(frame: CGRect(x: UIScreen.main.bounds.width - 135, y: Device.isXDevice ? 115 : 85, width: 120, height: 36), color: UIColor.main.marine)
        buttonClear.borderColor = UIColor.main.brightTeal
        buttonClear.borderWidth = 1
        buttonClear.setImage(IconCancel()?.maskWithColor(color: UIColor.main.brightTeal), for: .normal)
        buttonClear.setTitle(Localizable.shared.strings.clear_all.lowercased(), for: .normal)
        buttonClear.setTitleColor(UIColor.main.brightTeal, for: .normal)
        buttonClear.setTitleColor(UIColor.main.brightTeal.withAlphaComponent(0.5), for: .highlighted)
        buttonClear.addTarget(self, action: #selector(onClear), for: .touchUpInside)
        buttonClear.isHidden = (viewModel.unreads.count == 0 && viewModel.reads.count == 0)
        view.addSubview(buttonClear)
        
        emptyView.text = Localizable.shared.strings.no_notifications
        emptyView.image = IconNotificationsEmpty()
        emptyView.isHidden = !(viewModel.unreads.count == 0 && viewModel.reads.count == 0)
        emptyView.backgroundColor = view.backgroundColor
        view.addSubview(emptyView)
        
        subscribeToUpdates()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        emptyView.frame = tableView.frame
    }
    
    private func subscribeToUpdates() {
        viewModel.onDataChanged = { [weak self] in
            guard let strongSelf = self else { return }
            
            UIView.performWithoutAnimation {
                strongSelf.tableView.stopRefreshing()
                strongSelf.tableView.reloadData()
                strongSelf.emptyView.isHidden = !(strongSelf.viewModel.unreads.count == 0 && strongSelf.viewModel.reads.count == 0)
                strongSelf.buttonClear.isHidden = (strongSelf.viewModel.unreads.count == 0 && strongSelf.viewModel.reads.count == 0)
            }
        }
        
        viewModel.onDataDeleted = { [weak self]
            indexPath, notification in
            
            guard let strongSelf = self else { return }
            
            if strongSelf.viewModel.unreads.count == 0 && strongSelf.viewModel.reads.count == 0 {
                strongSelf.tableView.reloadData()
                AppModel.sharedManager().deleteNotification(notification.nId)
            }
            else {
                if let path = indexPath {
                    strongSelf.tableView.performUpdate({
                        strongSelf.tableView.deleteRows(at: [path], with: .left)
                    }, completion: {
                        AppModel.sharedManager().deleteNotification(notification.nId)
                    })
                }
            }
        }
    }
    
    @objc private func refreshData(_ sender: Any) {
        AppModel.sharedManager().getWalletNotifications()
    }
    
    private func rightButton() {
        addRightButton(image: Settings.sharedManager().isHideAmounts ? IconShowBalance() : IconHideBalance(), target: self, selector: #selector(onHideAmounts))
    }
    
    @objc private func onClear(_ sender: Any) {
        AppModel.sharedManager().deleteAllNotifications()
    }
}

extension NotificationsViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        if section == 1 && viewModel.reads.count > 0 {
            return BMTableHeaderTitleView.height
        }
        return 0
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        let item = indexPath.section == 0 ? viewModel.unreads[indexPath.row] : viewModel.reads[indexPath.row]
        if(item.type == TRANSACTION) {
            if let transaction = AppModel.sharedManager().transaction(byId: item.pId) {
                let vc = TransactionViewController(transaction: transaction)
                pushViewController(vc: vc)
            }
        }
        else if(item.type == ADDRESS) {
            if let address = AppModel.sharedManager().findAddress(byID: item.pId) {
                let vc = AddressViewController(address: address)
                pushViewController(vc: vc)
            }
        }
        else if(item.type == VERSION) {
            let vc = NotificationVersionViewController(version: item.pId)
            pushViewController(vc: vc)
        }
        
        if(!item.isRead) {
            AppModel.sharedManager().readNotification(item.nId)
        }
    }
    
    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        return viewModel.trailingSwipeActions(indexPath: indexPath)
    }
}

extension NotificationsViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        if section == 1 && viewModel.reads.count > 0 {
            let header = BMTableHeaderTitleView(title: Localizable.shared.strings.read.uppercased(), bold: true)
            header.letterSpacing = 1.5
            header.textFont = BoldFont(size: 14)
            header.textColor = Settings.sharedManager().isDarkMode ? UIColor.main.steel : UIColor.main.blueyGrey
            header.aligment = .center
            return header
        }
        return nil
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return section == 0 ? viewModel.unreads.count : viewModel.reads.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let item = indexPath.section == 0 ? viewModel.unreads[indexPath.row] : viewModel.reads[indexPath.row]
        let cell = tableView
            .dequeueReusableCell(withType: NotificationTableViewCell.self, for: indexPath)
            .configured(with: (row: indexPath.row, item: item))
        return cell
    }
}

extension NotificationsViewController: SettingsModelDelegate {
    func onChangeHideAmounts() {
        rightButton()
        
        viewModel.onNotificationsChanged()

        let lastContentOffset = tableView.contentOffset
        tableView.beginUpdates()
        tableView.endUpdates()
        tableView.layer.removeAllAnimations()
        tableView.setContentOffset(lastContentOffset, animated: false)
    }
}
