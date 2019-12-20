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
        
        if UIApplication.shared.keyWindow?.traitCollection.forceTouchCapability == .available {
            registerForPreviewing(with: self, sourceView: tableView)
        }
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
            let vc = TransactionViewController(transaction: viewModel.transactions[indexPath.row])
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
