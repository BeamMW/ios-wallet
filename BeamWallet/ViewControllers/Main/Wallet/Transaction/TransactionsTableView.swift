//
// TransactionsTableView.swift
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

class TransactionsTableView: UITableViewController {
    
    public var index = 0
    
    public var viewModel:TransactionViewModel!

    public var isSearching = false {
        didSet{
            viewModel.isSearch = isSearching
        }
    }
    
    public var searchingString = String.empty() {
        didSet{
            viewModel.searchString = searchingString
        }
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillShowNotification , object: nil)
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillHideNotification , object: nil)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.contentInsetAdjustmentBehavior = .never
        tableView.separatorStyle = .none
        tableView.register([BMEmptyCell.self, WalletTransactionCell.self, WalletTransactionSearchCell.self])
        tableView.keyboardDismissMode = .interactive
        
        tableView.addPullToRefresh(target: self, handler: #selector(refreshData(_:)))

        subscribeToChages()
        
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: UIResponder.keyboardWillHideNotification, object: nil)
    
        if #available(iOS 13.0, *) {
            let interaction = UIContextMenuInteraction(delegate: self)
            tableView.addInteraction(interaction)
        }
        
//        if UIApplication.shared.keyWindow?.traitCollection.forceTouchCapability == .available {
//            registerForPreviewing(with: self, sourceView: tableView)
//        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if KeyboardListener.shared.isVisible {
            tableView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: KeyboardListener.shared.keyboardHeight, right: 0)
        }
        else{
            tableView.contentInset = (Device.isXDevice ? UIEdgeInsets(top: 0, left: 0, bottom: 50, right: 0) : UIEdgeInsets.zero)
        }
        
        if viewModel.transactions.count == 0 {
            tableView.reloadData()
        }
    }
    
    
//MARK: - Updates

    @objc private func refreshData(_ sender: Any) {
          AppModel.sharedManager().getWalletStatus()
    }
    
    private func subscribeToChages() {
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
    }
    
//MARK: - TableView

    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if viewModel.transactions.count == 0 {
            var h =  tableView.h - 80
            if KeyboardListener.shared.isVisible {
                h = tableView.h - KeyboardListener.shared.keyboardHeight
            }
            if h < 100 {
                h = 150
            }
            return h
        }
        return UITableView.automaticDimension
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let count = viewModel.transactions.count
        return count == 0 ? 1 : count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        if viewModel.transactions.count == 0 {
            var text = String.empty()
            
            if AppModel.sharedManager().transactions?.count == 0 {
                text = Localizable.shared.strings.transactions_empty
            }
            else{
               text = index == 1 ? Localizable.shared.strings.transactions_empty_progress : Localizable.shared.strings.transactions_empty
            }
            
            let cell = tableView
                .dequeueReusableCell(withType: BMEmptyCell.self, for: indexPath)
                .configured(with: (text:text , image: IconWalletEmpty()))
            return cell
        }
        else {
            if(viewModel.isSearch && !viewModel.searchString.isEmpty) {
                let cell = tableView
                    .dequeueReusableCell(withType: WalletTransactionSearchCell.self, for: indexPath)
                    .configured(with: (row: indexPath.row, transaction: viewModel.transactions[indexPath.row], additionalInfo:true))
                cell.setSearch(searchString: viewModel.searchString, transaction: viewModel.transactions[indexPath.row])
                return cell
            }
            else{
                let cell = tableView
                    .dequeueReusableCell(withType: WalletTransactionCell.self, for: indexPath)
                    .configured(with: (row: indexPath.row, transaction: viewModel.transactions[indexPath.row], additionalInfo:true))
                return cell
            }
        }
    }
    
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool { 
        return viewModel.transactions.count > 0 ? true : false
    }
    
    override func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        return viewModel.trailingSwipeActions(indexPath: indexPath)
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        if  viewModel.transactions.count > 0 {
            let vc = TransactionPageViewController(transaction: viewModel.transactions[indexPath.row])
            vc.hidesBottomBarWhenPushed = true
            pushViewController(vc: vc)
        }
    }
}

//MARK: - Keyboard

extension TransactionsTableView {
    
    @objc func keyboardWillShow(_ notification: Notification) {
        if let keyboardFrame: NSValue = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue {
            let keyboardRectangle = keyboardFrame.cgRectValue
            let keyboardHeight = keyboardRectangle.height
            
            tableView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: keyboardHeight, right: 0)
        }
        
        if viewModel.transactions.count == 0 {
            tableView.reloadData()
        }
    }
    
    @objc func keyboardWillHide(notification: NSNotification) {
        tableView.contentInset = (Device.isXDevice ? UIEdgeInsets(top: 0, left: 0, bottom: 50, right: 0) : UIEdgeInsets.zero)
        
        if viewModel.transactions.count == 0 {
            tableView.reloadData()
        }
    }
}

extension TransactionsTableView: UIViewControllerPreviewingDelegate {
    func previewingContext(_ previewingContext: UIViewControllerPreviewing, viewControllerForLocation location: CGPoint) -> UIViewController? {
        if  viewModel.transactions.count > 0 {
            guard let indexPath = tableView.indexPathForRow(at: location) else { return nil }
            
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

extension TransactionsTableView: UIContextMenuInteractionDelegate {
    
    @available(iOS 13.0, *)
    override func tableView(_ tableView: UITableView, previewForHighlightingContextMenuWithConfiguration configuration: UIContextMenuConfiguration) -> UITargetedPreview? {
        
        guard let indexPath = configuration.identifier as? IndexPath,
              let cell = tableView.cellForRow(at: indexPath)
        else
        {
            return nil
        }
        
        
        let targetedPreview = UITargetedPreview(view: cell)
        targetedPreview.parameters.backgroundColor = .clear
        
        return targetedPreview
    }
    
    @available(iOS 13.0, *)
    override func tableView(_ tableView: UITableView, previewForDismissingContextMenuWithConfiguration configuration: UIContextMenuConfiguration) -> UITargetedPreview? {
        
        guard let indexPath = configuration.identifier as? IndexPath,
              let cell = tableView.cellForRow(at: indexPath)
        else
        {
            return nil
        }
        
        let targetedPreview = UITargetedPreview(view: cell)
        targetedPreview.parameters.backgroundColor = .clear
        
        return targetedPreview
    }
    
    @available(iOS 13.0, *)
    func contextMenuInteraction(_ interaction: UIContextMenuInteraction, configurationForMenuAtLocation location: CGPoint) -> UIContextMenuConfiguration? {
        return nil
    }
    
    @available(iOS 13.0, *)
    override func tableView(_ tableView: UITableView, willPerformPreviewActionForMenuWith configuration: UIContextMenuConfiguration, animator: UIContextMenuInteractionCommitAnimating) {
        animator.addCompletion {
            if let viewController = animator.previewViewController as? TransactionPageViewController {
                viewController.isPreview = false
                self.navigationController?.pushViewController(viewController, animated: false)
                viewController.viewDidLoad()
                viewController.viewDidLayoutSubviews()
            }
        }
    }
    
    @available(iOS 13.0, *)
    override func tableView(_ tableView: UITableView, contextMenuConfigurationForRowAt indexPath: IndexPath, point: CGPoint) -> UIContextMenuConfiguration? {
        
        if  viewModel.transactions.count > 0 {
            let detailVC = TransactionPageViewController(transaction: viewModel.transactions[indexPath.row], preview: true)
            detailVC.preferredContentSize = CGSize(width: 0.0, height: 400)
            
            return UIContextMenuConfiguration(identifier: indexPath as NSCopying, previewProvider: {
                return detailVC
            }, actionProvider: { suggestedActions in
                return self.makeContextMenu(transaction: self.viewModel.transactions[indexPath.row])
            })
        }
        
        return nil
    }
    
    @available(iOS 13.0, *)
    func makeContextMenu(transaction:BMTransaction) -> UIMenu {
        var array = [UIAction]()
        let viewModel = DetailTransactionViewModel(transaction: transaction)
        
        if transaction.canSaveContact() {
            let action1 = UIAction(title: Localizable.shared.strings.save_contact_title, image: nil) { action in
                viewModel.saveContact()
            }
            array.append(action1)
        }
        
        let action1 = UIAction(title: Localizable.shared.strings.share_details, image: nil) { action in
            viewModel.share()
        }
        array.append(action1)
        
        let action2 = UIAction(title: Localizable.shared.strings.copy_details, image: nil) { action in
            viewModel.copyDetails()
        }
        array.append(action2)
        
        if !transaction.isIncome && !transaction.isDapps {
            let action3 = UIAction(title: Localizable.shared.strings.copy_details, image: nil) { action in
                viewModel.repeatTransation(transaction: viewModel.transaction!)
            }
            array.append(action3)
        }
        
        if transaction.canCancel && !transaction.isDapps {
            let action4 = UIAction(title: Localizable.shared.strings.cancel_transaction, image: nil) { action in
                viewModel.cancelTransation(indexPath: nil)
            }
            array.append(action4)
        }
        
        if transaction.canDelete {
            let action5 = UIAction(title: Localizable.shared.strings.delete_transaction, image: nil) { action in
                viewModel.deleteTransationNew(indexPath: nil)
            }
            array.append(action5)
        }
        
        if transaction.isDapps {
            let action6 = UIAction(title: Localizable.shared.strings.open_dapp, image: nil) { action in
                viewModel.openDapp()
            }
            array.append(action6)
        }
        return UIMenu(title: "", children: array)
    }
}

