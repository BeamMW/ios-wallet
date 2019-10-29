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
    
    private let maximumTransactionsCount = 5
        

    
    deinit {
        Settings.sharedManager().removeDelegate(self)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
                
        setGradientTopBar(mainColor: UIColor.main.peacockBlue, addedStatusView: true)
        
        title = Localizable.shared.strings.wallet
        
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register([WalletStatusCell.self, WalletAvailableCell.self, WalletProgressCell.self, WalletTransactionCell.self, BMEmptyCell.self, OnboardCell.self])
        tableView.tableHeaderView = UIView(frame: CGRect(x: 0, y: 0, width: 0, height: 10))
        tableView.keyboardDismissMode = .interactive
        tableView.addPullToRefresh(target: self, handler: #selector(refreshData(_:)))

        
        AppModel.sharedManager().isLoggedin = true
        
        AppStoreReviewManager.incrementAppOpenedCount()
        
        NotificationManager.sharedManager.subscribeToTopics(addresses: AppModel.sharedManager().walletAddresses as? [BMAddress])
        
        Settings.sharedManager().addDelegate(self)
        
        expandProgress = !Settings.sharedManager().isHideAmounts
        expandAvailable = !Settings.sharedManager().isHideAmounts
        
        if TGBotManager.sharedManager.isNeedLinking() {
            TGBotManager.sharedManager.startLinking { [weak self] _ in
                self?.tableView.reloadData()
            }
        }
        else {
            NotificationManager.sharedManager.displayConfirmAlert()
        }
        
        rightButton()
        
        subscribeToUpdates()
        
        AppModel.sharedManager().fixCategories()
        
        if UIApplication.shared.keyWindow?.traitCollection.forceTouchCapability == .available {
            registerForPreviewing(with: self, sourceView: tableView)
        }        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        if !NotificationManager.sharedManager.clickedTransaction.isEmpty {
            if let transaction = viewModel.transactions.first(where: { $0.id == NotificationManager.sharedManager.clickedTransaction }) {
                let vc = TransactionViewController(transaction: transaction)
                vc.hidesBottomBarWhenPushed = true
                pushViewController(vc: vc)
            }
            
            NotificationManager.sharedManager.clickedTransaction = ""
        }
        else if ShortcutManager.canHandle() {
            _ = ShortcutManager.handleShortcutItem()
        }
        else if AppStoreReviewManager.checkAndAskForReview() {
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
            else {
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
            
            if strongSelf.statusViewModel.selectedState == .maturing, !strongSelf.statusViewModel.isAvaiableMautring() {
                strongSelf.isNeedUpdatingReload = true
                strongSelf.statusViewModel.selectedState = .available
            }
            
            if AppModel.sharedManager().isUpdating {
                if let cell = strongSelf.tableView.findCell(WalletAvailableCell.self) as? WalletAvailableCell {
                    cell.configure(with: (expand: strongSelf.expandAvailable, status: AppModel.sharedManager().walletStatus, selectedState: strongSelf.statusViewModel.selectedState, avaiableMaturing: strongSelf.statusViewModel.isAvaiableMautring()))
                }
                
                if let cell = strongSelf.tableView.findCell(WalletProgressCell.self) as? WalletProgressCell {
                    cell.configure(with: (expand: strongSelf.expandProgress, status: AppModel.sharedManager().walletStatus))
                }
                
                if strongSelf.isNeedUpdatingReload {
                    strongSelf.isNeedUpdatingReload = false
                    strongSelf.tableView.reloadData()
                }
            }
            else {
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
        if viewModel.transactions.count > 0 {
            let vc = TransactionsViewController()
            pushViewController(vc: vc)
        }
        else {
            var items = [BMPopoverMenu.BMPopoverMenuItem]()
            items.append(BMPopoverMenu.BMPopoverMenuItem(name: Localizable.shared.strings.payment_proof, icon: nil, action: .payment_proof))
            
            BMPopoverMenu.show(menuArray: items, done: { selectedItem in
                if let item = selectedItem {
                    switch item.action {
                    case .payment_proof:
                        let vc = PaymentProofDetailViewController(transaction: nil, paymentProof: nil)
                        vc.hidesBottomBarWhenPushed = true
                        self.pushViewController(vc: vc)
                        return
                    default:
                        return
                    }
                }
            }, cancel: {})
        }
    }
}

extension WalletViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        if indexPath.section == 1, viewModel.transactions.count > 0 {
            return true
        }
        
        return false
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        switch indexPath.section {
        case 0:
            let cell = statusViewModel.getCells()[indexPath.row]
            
            if cell == .buttons {
                return UITableView.automaticDimension
            }
            else if cell == .available {
                if Settings.sharedManager().isHideAmounts || !expandAvailable {
                    return WalletAvailableCell.hideHeight()
                }
                else {
                    return statusViewModel.isAvaiableMautring() ? WalletAvailableCell.maturingHeight() : WalletAvailableCell.singleHeight()
                }
            }
            else if cell == .progress {
                if Settings.sharedManager().isHideAmounts || !expandProgress {
                    return WalletProgressCell.hideHeight()
                }
                else {
                    return AppModel.sharedManager().walletStatus?.isSendingAndReceiving() ?? false ? WalletProgressCell.mainHeight() : WalletProgressCell.singleHeight()
                }
            }
            else {
                return UITableView.automaticDimension
            }
        case 1:
            if viewModel.transactions.count == 0 {
                return 200
            }
            else {
                return UITableView.automaticDimension
            }
        default:
            return 0
        }
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        if  viewModel.transactions.count == 0 && section == 1 {
            return 0
        }
        return (section == 1 ? BMTableHeaderTitleView.height : 0)
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        if indexPath.section == 1, viewModel.transactions.count > 0 {
            let vc = TransactionViewController(transaction: viewModel.transactions[indexPath.row])
            vc.hidesBottomBarWhenPushed = true
            pushViewController(vc: vc)
        }
    }
    
    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        return viewModel.trailingSwipeActions(indexPath: indexPath)
    }
}

extension WalletViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        switch section {
        case 1:
            if viewModel.transactions.count == 0 {
                return nil
            }
            let header = BMTableHeaderTitleView(title: Localizable.shared.strings.transactions.uppercased(), handler: #selector(onMore), target: self)
            header.letterSpacing = 1.5
            header.textColor = UIColor.white
            header.textFont = BoldFont(size: 14)
            header.buttonImage = IconNextArrow()
            header.buttonFrame = header.bounds
            return header
        default:
            return nil
        }
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0:
            return statusViewModel.getCells().count
        case 1:
            return (viewModel.transactions.count == 0) ? 1 : ((viewModel.transactions.count > maximumTransactionsCount) ? maximumTransactionsCount : viewModel.transactions.count)
        default:
            return 0
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch indexPath.section {
        case 0:
            let cell = statusViewModel.getCells()[indexPath.row]
            
            switch cell {
            case .buttons:
                let cell = tableView.dequeueReusableCell(withType: WalletStatusCell.self, for: indexPath)
                cell.delegate = self
                return cell
            case .available:
                let cell = tableView
                    .dequeueReusableCell(withType: WalletAvailableCell.self, for: indexPath)
                    .configured(with: (expand: expandAvailable, status: AppModel.sharedManager().walletStatus, selectedState: statusViewModel.selectedState, avaiableMaturing: statusViewModel.isAvaiableMautring()))
                cell.delegate = self
                return cell
            case .progress:
                let cell = tableView
                    .dequeueReusableCell(withType: WalletProgressCell.self, for: indexPath)
                    .configured(with: (expand: expandProgress, status: AppModel.sharedManager().walletStatus))
                cell.delegate = self
                return cell
            case .verefication:
                let cell = tableView.dequeueReusableCell(withType: OnboardCell.self, for: indexPath)
                cell.delegate = self
                cell.setIsSecure(secure: true)
                return cell
            case .faucet:
                let cell = tableView.dequeueReusableCell(withType: OnboardCell.self, for: indexPath)
                cell.delegate = self
                cell.setIsSecure(secure: false)
                return cell
            }
        case 1:
            if viewModel.transactions.count == 0 {
                let cell = tableView
                    .dequeueReusableCell(withType: BMEmptyCell.self, for: indexPath)
                    .configured(with: (text: Localizable.shared.strings.transactions_empty, image: IconWalletEmpty()))
                return cell
            }
            else {
                let cell = tableView
                    .dequeueReusableCell(withType: WalletTransactionCell.self, for: indexPath)
                    .configured(with: (row: indexPath.row, transaction: viewModel.transactions[indexPath.row], additionalInfo: false))
                return cell
            }
        default:
            return UITableViewCell()
        }
    }
}

extension WalletViewController: WalletStatusCellDelegate {
    func onClickReceived() {
        statusViewModel.onReceive()
    }
    
    func onClickSend() {
        statusViewModel.onSend()
    }
}

extension WalletViewController: WalletAvailableCellDelegate {
    func onExpandAvailable() {
        if !Settings.sharedManager().isHideAmounts {
            expandAvailable = !expandAvailable
            tableView.reloadRow(WalletAvailableCell.self)
        }
    }
    
    func onDidChangeSelectedState(state: StatusViewModel.SelectedState) {
        statusViewModel.selectedState = state
    }
}

extension WalletViewController: WalletProgressCellDelegate {
    func onExpandProgress() {
        if !Settings.sharedManager().isHideAmounts {
            expandProgress = !expandProgress
            tableView.reloadRow(WalletProgressCell.self)
        }
    }
}

extension WalletViewController: SettingsModelDelegate {
    func onChangeHideAmounts() {
        rightButton()
        
        expandProgress = !Settings.sharedManager().isHideAmounts
        expandAvailable = !Settings.sharedManager().isHideAmounts
        
        tableView.reloadData()
    }
}

extension WalletViewController: UIViewControllerPreviewingDelegate {
    func previewingContext(_ previewingContext: UIViewControllerPreviewing, viewControllerForLocation location: CGPoint) -> UIViewController? {
        if viewModel.transactions.count > 0 {
            guard let indexPath = tableView.indexPathForRow(at: location) else { return nil }
            
            if indexPath.section != 1 {
                return nil
            }
            
            guard let cell = tableView.cellForRow(at: indexPath) else { return nil }
            
            let detailVC = TransactionViewController(transaction: viewModel.transactions[indexPath.row], preview: true)
            detailVC.preferredContentSize = CGSize(width: 0.0, height: 400)
            
            previewingContext.sourceRect = cell.frame
            
            return detailVC
        }
        else {
            return nil
        }
    }
    
    func previewingContext(_ previewingContext: UIViewControllerPreviewing, commit viewControllerToCommit: UIViewController) {
        show(viewControllerToCommit, sender: self)
        
        (viewControllerToCommit as! TransactionViewController).didShow()
    }
}

extension WalletViewController: OnboardCellDelegate {
    func onClickMakeSecure(cell:UITableViewCell) {
        let vc = UnlockPasswordViewController(event: .seedPhrase)
        pushViewController(vc: vc)
    }
    
    func onClickCloseFaucet(cell:UITableViewCell) {
        if let indexPath = tableView.indexPath(for: cell) {
            let cell = statusViewModel.getCells()[indexPath.row]
            
            if cell == .faucet {
                OnboardManager.shared.isCloseFaucet = true
                tableView.deleteRows(at: [indexPath], with: .fade)
            }
            else if cell == .verefication {
                OnboardManager.shared.isCloseSecure = true
                tableView.deleteRows(at: [indexPath], with: .fade)
            }
        }
    }
    
    func onClickReceiveFaucet(cell:UITableViewCell) {
        OnboardManager.shared.receiveFaucet { [weak self] url, error in
            guard let strongSelf = self else { return }
            if let reason = error?.localizedDescription {
                strongSelf.alert(message: reason)
            }
            else if let result = url {
                strongSelf.openUrl(url: result)
            }
        }
    }
}
