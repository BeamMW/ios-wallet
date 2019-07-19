//
// WalletViewController.swift
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

class WalletViewController: BaseTableViewController {

    private var isNeedUpdatingReload = true

    private var expandAvailable = true
    private var expandProgress = true
  
    private let viewModel = TransactionViewModel()
    private let statusViewModel = StatusViewModel()

    override var isUppercasedTitle: Bool {
        get{
            return true
        }
        set{
            super.isUppercasedTitle = true
        }
    }
    
    
    override var isSearching: Bool{
        get{
            return super.isSearching
        }
        set{
            super.isSearching = newValue
            viewModel.isSearch = newValue
            if newValue {
                tableView.refreshControl?.endRefreshing()
                tableView.refreshControl = nil
                tableView.tableHeaderView = UIView(frame: CGRect(x: 0, y: 0, width: 0, height: 0))
            }
            else{
                tableView.tableHeaderView = UIView(frame: CGRect(x: 0, y: 0, width: 0, height: 10))
                tableView.addPullToRefresh(target: self, handler: #selector(refreshData(_:)))
            }
            tableView.reloadData()
        }
    }
    
    override var searchingString: String {
        get{
            return super.searchingString
        }
        set{
            super.searchingString = newValue
            viewModel.searchString = newValue
        }
    }
    
    deinit {
        Settings.sharedManager().removeDelegate(self)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        isGradient = true
        setGradientTopBar(mainColor: UIColor.main.peacockBlue, addedStatusView: true)

        title = Localizable.shared.strings.wallet
                
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register([WalletStatusCell.self, WalletAvailableCell.self, WalletProgressCell.self, WalletTransactionCell.self, BMEmptyCell.self])
        tableView.addPullToRefresh(target: self, handler: #selector(refreshData(_:)))
        tableView.tableHeaderView = UIView(frame: CGRect(x: 0, y: 0, width: 0, height: 10))
        tableView.keyboardDismissMode = .interactive
        
        AppModel.sharedManager().isLoggedin = true
        
        AppStoreReviewManager.incrementAppOpenedCount()

        NotificationManager.sharedManager.subscribeToTopics(addresses: AppModel.sharedManager().walletAddresses as? [BMAddress])
        
        Settings.sharedManager().addDelegate(self)

        expandProgress = !Settings.sharedManager().isHideAmounts
        expandAvailable = !Settings.sharedManager().isHideAmounts
        
        if TGBotManager.sharedManager.isNeedLinking() {
            TGBotManager.sharedManager.startLinking {[weak self] (_ ) in
                self?.tableView.reloadData()
            }
        }
        else{
            NotificationManager.sharedManager.displayConfirmAlert()
        }
        
        rightButton()
        
        subscribeToUpdates()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        if !NotificationManager.sharedManager.clickedTransaction.isEmpty {
            if let transaction = viewModel.transactions.first(where: { $0.id == NotificationManager.sharedManager.clickedTransaction }) {
                let vc = TransactionViewController(transaction: transaction)
                vc.hidesBottomBarWhenPushed = true
                self.pushViewController(vc: vc)
            }
            
            NotificationManager.sharedManager.clickedTransaction = ""
        }
        else if ShortcutManager.canHandle() {
            _ = ShortcutManager.handleShortcutItem()
        }
        else if AppStoreReviewManager.checkAndAskForReview(){
            showRateDialog()
        }
    }
    
    
    private func rightButton() {
        addRightButton(image: Settings.sharedManager().isHideAmounts ? IconShowBalance() : IconHideBalance(), target: self, selector: #selector(onHideAmounts))
    }
    
    private func subscribeToUpdates() {
        viewModel.onDataChanged = { [weak self] in
            guard let strongSelf = self else { return }

            UIView.performWithoutAnimation {
                strongSelf.tableView.stopRefreshing()
                strongSelf.tableView.reloadData()
            }
        }
        
        viewModel.onDataDeleted = { [weak self]
            indexPath, transaction in
            
            guard let strongSelf = self else { return }

            if strongSelf.viewModel.transactions.count == 0 {
                strongSelf.tableView.reloadData()
                AppModel.sharedManager().prepareDeleteTransaction(transaction)
            }
            else{
                if let path = indexPath {
                    strongSelf.tableView.performUpdate({
                        strongSelf.tableView.deleteRows(at: [path], with: .left)
                    }, completion: {
                        AppModel.sharedManager().prepareDeleteTransaction(transaction)
                    })
                }
            }
        }
        
        viewModel.onDataUpdated = { [weak self]
            indexPath, transaction in
            
            if let path = indexPath {
                self?.tableView.performUpdate({
                    self?.tableView.reloadRows(at: [path], with: .fade)
                }, completion: {
                    AppModel.sharedManager().cancelTransaction(transaction)
                })
            }
        }
        
        statusViewModel.onDataChanged = { [weak self] in
            
            guard let strongSelf = self else { return }

            if AppModel.sharedManager().isUpdating {
                
                if let cell = strongSelf.tableView.findCell(WalletAvailableCell.self) as? WalletAvailableCell {
                    cell.configure(with: (expand: strongSelf.expandAvailable, status: AppModel.sharedManager().walletStatus))
                }
                
                if let cell = strongSelf.tableView.findCell(WalletProgressCell.self) as? WalletProgressCell {
                    cell.configure(with: (expand: strongSelf.expandProgress, status: AppModel.sharedManager().walletStatus))
                }
                
                if strongSelf.isNeedUpdatingReload {
                    strongSelf.isNeedUpdatingReload = false
                    strongSelf.tableView.reloadData()
                }
            }
            else{
                UIView.performWithoutAnimation {
                    strongSelf.tableView.stopRefreshing()
                    strongSelf.tableView.reloadData()
                }
            }
        }
    }
    
    @objc private func refreshData(_ sender: Any) {
       AppModel.sharedManager().getWalletStatus()
    }
    
    @objc private func onMore(_ sender: Any) {
                
        var items = [BMPopoverMenu.BMPopoverMenuItem]()
        items.append(BMPopoverMenu.BMPopoverMenuItem(name: Localizable.shared.strings.payment_proof, icon: nil, action: .payment_proof))
        
        if viewModel.transactions.count > 0 {
            items.insert(BMPopoverMenu.BMPopoverMenuItem(name: Localizable.shared.strings.search, icon: nil, action: .search), at: 0)
            items.insert(BMPopoverMenu.BMPopoverMenuItem(name: Localizable.shared.strings.export, icon: nil, action: .export_transactions), at: 0)
        }
        
        BMPopoverMenu.show(menuArray: items, done: { (selectedItem) in
            if let item = selectedItem {
                switch (item.action) {
                case .payment_proof:
                    let vc  = PaymentProofDetailViewController(transaction: nil, paymentProof: nil)
                    vc.hidesBottomBarWhenPushed = true
                    self.pushViewController(vc: vc)
                    return
                case .export_transactions:
                    AppModel.sharedManager().exportTransactions(toCSV: { (csvPath) in
                        let vc = UIActivityViewController(activityItems: [csvPath], applicationActivities: nil)
                        vc.excludedActivityTypes = [UIActivity.ActivityType.postToFacebook, UIActivity.ActivityType.assignToContact, UIActivity.ActivityType.copyToPasteboard, UIActivity.ActivityType.print,UIActivity.ActivityType.openInIBooks]
                        self.present(vc, animated: true)
                    })
                    return
                case .search:
                    self.startSearch()
                default:
                    return
                }
            }
        }, cancel: {
            
        })
    }
}

extension WalletViewController : UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        if indexPath.section == 1 && viewModel.transactions.count > 0 {
            return true
        }
        
        return false
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        switch indexPath.section {
        case 0:
            if indexPath.row == 0 {
                return WalletStatusCell.height()
            }
            else if indexPath.row == 1 {
                if Settings.sharedManager().isHideAmounts || !expandAvailable {
                    return WalletAvailableCell.hideHeight()
                }
                else{
                   return AppModel.sharedManager().walletStatus?.maturing == 0 ? WalletAvailableCell.singleHeight() : WalletAvailableCell.mainHeight()
                }
            }
            else if indexPath.row == 2 {
                if Settings.sharedManager().isHideAmounts || !expandProgress {
                    return WalletProgressCell.hideHeight()
                }
                else{
                    return AppModel.sharedManager().walletStatus?.isSendingAndReceiving() ?? false ? WalletProgressCell.mainHeight() : WalletProgressCell.singleHeight()
                }
            }
            else{
                return 0
            }
        case 1:
            if (viewModel.transactions.count == 0)
            {
                return 200
            }
            else{
                return isSearching ? WalletTransactionCell.searchHeight() : WalletTransactionCell.height()
            }
        default:
            return 0
        }
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return isSearching ? 0 : (section == 1 ? BMTableHeaderTitleView.height : 0)
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    
        if indexPath.section == 1 && viewModel.transactions.count > 0 {
            let vc = TransactionViewController(transaction: viewModel.transactions[indexPath.row])
            vc.hidesBottomBarWhenPushed = true
            pushViewController(vc: vc)
        }
    }
    
    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration?
    {
        return viewModel.trailingSwipeActions(indexPath: indexPath)
    }
}

extension WalletViewController : UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        switch section {
        case 1:
            return isSearching ? nil : BMTableHeaderTitleView(title: Localizable.shared.strings.transactions, handler: #selector(onMore), target: self)
        default:
            return nil
        }
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 2;
    }
    
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if isSearching {
            switch section {
            case 1:
                return viewModel.transactions.count
            default:
                return 0
            }
        }
        else{
            switch section {
            case 0:
                return AppModel.sharedManager().walletStatus?.hasInProgressBalance() ?? false ? 3 : 2
            case 1:
                return (viewModel.transactions.count == 0) ? 1 : viewModel.transactions.count
            default:
                return 0
            }
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        switch indexPath.section {
        case 0:
            switch indexPath.row {
            case 0:
                let cell = tableView.dequeueReusableCell(withType: WalletStatusCell.self, for: indexPath)
                cell.delegate = self
                return cell
            case 1:
                let cell = tableView
                    .dequeueReusableCell(withType: WalletAvailableCell.self, for: indexPath)
                    .configured(with: (expand: expandAvailable, status: AppModel.sharedManager().walletStatus))
                cell.delegate = self
                return cell
            case 2:
                let cell =  tableView
                    .dequeueReusableCell(withType: WalletProgressCell.self, for: indexPath)
                    .configured(with: (expand: expandProgress, status: AppModel.sharedManager().walletStatus))
                cell.delegate = self
                return cell
            default:
                return UITableViewCell()
            }
        case 1:
            if viewModel.transactions.count == 0 {
                let cell = tableView
                    .dequeueReusableCell(withType: BMEmptyCell.self, for: indexPath)
                    .configured(with: (text: Localizable.shared.strings.transactions_empty, image: IconWalletEmpty()))
                return cell
            }
            else{
                let cell = tableView
                    .dequeueReusableCell(withType: WalletTransactionCell.self, for: indexPath)
                    .configured(with: (row: indexPath.row, transaction: viewModel.transactions[indexPath.row], single:false, searchString:(isSearching ? searchingString : String.empty())))
                return cell
            }
        default:
            return UITableViewCell()
        }
    }
}

extension WalletViewController : WalletStatusCellDelegate {
   
    func onClickReceived() {
        statusViewModel.onReceive()
    }
    
    func onClickSend() {
        statusViewModel.onSend()
    }
}

extension WalletViewController : WalletAvailableCellDelegate {
    
    func onExpandAvailable() {
        if !Settings.sharedManager().isHideAmounts {
            expandAvailable = !expandAvailable
            
            UIView.performWithoutAnimation {
                self.tableView.reloadRow(WalletAvailableCell.self)
            }
        }
    }
}

extension WalletViewController : WalletProgressCellDelegate {
    
    func onExpandProgress() {
        if !Settings.sharedManager().isHideAmounts {
            expandProgress = !expandProgress
            
            UIView.performWithoutAnimation {
                self.tableView.reloadRow(WalletProgressCell.self)
            }
        }
    }
}

extension WalletViewController : SettingsModelDelegate {
    
    func onChangeHideAmounts() {
        rightButton()
        
        expandProgress = !Settings.sharedManager().isHideAmounts
        expandAvailable = !Settings.sharedManager().isHideAmounts
        
        tableView.reloadData()
    }
}
