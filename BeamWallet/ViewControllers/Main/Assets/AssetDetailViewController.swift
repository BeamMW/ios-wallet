//
// AssetDetailViewController.swift
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

class AssetDetailViewController: BaseTableViewController {
    
    private var asset:BMAsset!
    
    init(asset: BMAsset) {
        super.init(nibName: nil, bundle: nil)
        
        self.asset = asset
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError(Localizable.shared.strings.fatalInitCoderError)
    }
    
    private let transactionViewModel = TransactionViewModel()
    private let statusViewModel = StatusViewModel()
    private let assetViewModel = AssetViewModel()
        
    deinit {
        Settings.sharedManager().removeDelegate(self)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        statusViewModel.assetId = Int(asset.assetId)

        setGradientTopBar(mainColor: UIColor.main.peacockBlue, addedStatusView: true)
        
        if !asset.isBeam() {
            title = asset.unitName.uppercased()
        }
        else {
            title = Localizable.shared.strings.beam_2.uppercased()
        }
        
        transactionViewModel.assetId = Int32(asset.assetId)
        
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register([WalletStatusCell.self, WalletTransactionCell.self, BMEmptyCell.self, OnboardCell.self, AssetAvailableCell.self])
        tableView.tableHeaderView = UIView(frame: CGRect(x: 0, y: 0, width: 0, height: 10))
        tableView.keyboardDismissMode = .interactive
        tableView.addPullToRefresh(target: self, handler: #selector(refreshData(_:)))
        
        AppModel.sharedManager().isLoggedin = true
        
        Settings.sharedManager().addDelegate(self)
        
        rightButton()
        
        subscribeToUpdates()
                
        if UIApplication.shared.keyWindow?.traitCollection.forceTouchCapability == .available {
            registerForPreviewing(with: self, sourceView: tableView)
        }
    }
    
    
    private func rightButton() {        
        addRightButtons(image: [Settings.sharedManager().isHideAmounts ? IconShowBalance() : IconHideBalance(), IconAssetInfo()].reversed(), target: self, selector: [#selector(onHideAmounts), #selector(onInfo)].reversed())

    }
    
    private func subscribeToUpdates() {
        transactionViewModel.onDataChanged = { [weak self] in
            guard let strongSelf = self else { return }
            
            UIView.performWithoutAnimation {
                strongSelf.tableView.stopRefreshing()
                strongSelf.assetViewModel.sort()
                strongSelf.tableView.reloadData()
            }
        }
        
        transactionViewModel.onDataDeleted = { [weak self]
            indexPath, transaction in
            
            guard let strongSelf = self else { return }
            
            if strongSelf.transactionViewModel.transactions.count == 0  {
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
        
        transactionViewModel.onDataUpdated = { [weak self]
            indexPath, transaction in
            
            if let path = indexPath {
                self?.tableView.performUpdate({
                    self?.tableView.reloadRows(at: [path], with: .fade)
                }, completion: {
                    AppModel.sharedManager().cancelTransaction(transaction)
                })
            }
        }
        
        statusViewModel.onRatesChange = { [weak self] in
            guard let strongSelf = self else { return }
            UIView.performWithoutAnimation {
                strongSelf.tableView.reloadData()
            }
        }
        
        statusViewModel.onDataChanged = { [weak self] in
            guard let strongSelf = self else { return }
            UIView.performWithoutAnimation {
                strongSelf.asset = AssetsManager.shared().getAsset(Int32(strongSelf.asset.assetId))
                strongSelf.tableView.stopRefreshing()
                strongSelf.tableView.reloadData()
            }
        }
        
        assetViewModel.onDataChanged = { [weak self] in
            guard let strongSelf = self else { return }
            UIView.performWithoutAnimation {
                strongSelf.asset = AssetsManager.shared().getAsset(Int32(strongSelf.asset.assetId))
                strongSelf.tableView.stopRefreshing()
                strongSelf.tableView.reloadData()
            }
        }
    }
    
    @objc private func refreshData(_ sender: Any) {
        AppModel.sharedManager().getWalletStatus()
    }
    
    @objc private func onInfo() {
        let vc = AssetInfoViewController(asset: self.asset)
        pushViewController(vc: vc)
    }
    
    @objc private func onMore(_ sender: Any) {
        if transactionViewModel.transactions.count > 0 {
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

extension AssetDetailViewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        if indexPath.section == 2, transactionViewModel.transactions.count > 0 {
            return true
        }
        return false
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if indexPath.section == 2 && transactionViewModel.transactions.count == 0 {
            return 200
        }
        return UITableView.automaticDimension
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        if section == 2, transactionViewModel.transactions.count > 0 {
            return BMTableHeaderTitleView.height
        }
        return 0
    }
    
    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        return transactionViewModel.trailingSwipeActions(indexPath: indexPath)
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        if indexPath.section == 2, transactionViewModel.transactions.count > 0 {
            let vc = TransactionPageViewController(transaction: transactionViewModel.transactions[indexPath.row])
            vc.hidesBottomBarWhenPushed = true
            pushViewController(vc: vc)
        }
    }
}

extension AssetDetailViewController: UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        if section == 2, transactionViewModel.transactions.count > 0 {
            let header = BMTableHeaderTitleView(title: Localizable.shared.strings.transactions.uppercased(), handler: #selector(onMore), target: self)
            header.letterSpacing = 1.5
            header.textColor = UIColor.white
            header.textFont = BoldFont(size: 14)
            header.buttonImage = IconNextArrow()
            header.buttonFrame = header.bounds
            return header
        }
        return nil
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 3
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0:
            return 1
        case 1:
            return 1
        case 2:
            return transactionViewModel.transactions.count == 0 ? 1 : transactionViewModel.transactions.count
        default:
            return 0
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch indexPath.section {
        case 0:
            let cell = tableView.dequeueReusableCell(withType: WalletStatusCell.self, for: indexPath)
            cell.delegate = self
            return cell
        case 1:
            let cell = tableView.dequeueReusableCell(withType: AssetAvailableCell.self, for: indexPath)
            cell.setAsset(asset)
            cell.isUserInteractionEnabled = false
            return cell
        case 2:
            if transactionViewModel.transactions.count == 0 {
                let cell = tableView
                    .dequeueReusableCell(withType: BMEmptyCell.self, for: indexPath)
                    .configured(with: (text: Localizable.shared.strings.transactions_empty, image: IconWalletEmpty()))
                return cell
            }
            else {
                let cell = tableView
                    .dequeueReusableCell(withType: WalletTransactionCell.self, for: indexPath)
                    .configured(with: (row: indexPath.row, transaction: transactionViewModel.transactions[indexPath.row], additionalInfo: false))
                return cell
            }
        default:
            return UITableViewCell()
        }
    }
}

extension AssetDetailViewController: WalletStatusCellDelegate {
    func onClickReceived() {
        statusViewModel.onReceive()
    }
    
    func onClickSend() {
        statusViewModel.onSend()
    }
}


extension AssetDetailViewController: SettingsModelDelegate {
    
    func onChangeHideAmounts() {
        rightButton()
        tableView.reloadData()
    }
}

extension AssetDetailViewController: UIViewControllerPreviewingDelegate {
    
    func previewingContext(_ previewingContext: UIViewControllerPreviewing, viewControllerForLocation location: CGPoint) -> UIViewController? {
        
        if transactionViewModel.transactions.count > 0 {
            guard let indexPath = tableView.indexPathForRow(at: location) else { return nil }
            
            if indexPath.section != 1 {
                return nil
            }
            
            guard let cell = tableView.cellForRow(at: indexPath) else { return nil }
            
            let detailVC = TransactionViewController(transaction: transactionViewModel.transactions[indexPath.row], preview: true)
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
