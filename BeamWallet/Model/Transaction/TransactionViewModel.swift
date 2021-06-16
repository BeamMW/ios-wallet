//
// TransactionViewModel.swift
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

class TransactionViewModel: NSObject {
    enum TransactionSelectedState: Int {
        case all = 0
        case sent = 1
        case received = 2
        case in_progress = 3
    }
    
    
    public var onDataChanged : (() -> Void)?
    public var onDataDeleted : ((IndexPath?, BMTransaction) -> Void)?
    public var onDataUpdated : ((IndexPath?, BMTransaction) -> Void)?

    public var transactions = [BMTransaction]()
    public var address:BMAddress?
    public var transaction:BMTransaction?
    
    public var isSegment = false
    public var isSearch = false {
        didSet{
            if !isSearch {
                searchString = String.empty()
            }
        }
    }
    
    public var assetId:Int32? = nil {
        didSet {
            if let id = assetId {
                self.transactions = self.transactions.filter { tr in
                    return tr.assetId == id
                }
            }
        }
    }
    
    public var selectedState: TransactionSelectedState = .all
    public var searchString = String.empty()

    init(transaction:BMTransaction) {
        super.init()
        
        self.transaction = transaction

        AppModel.sharedManager().addDelegate(self)
    }
    
    init(address:BMAddress) {
        super.init()
        
        self.address = address
        
        self.transactions = (AppModel.sharedManager().getTransactionsFrom(self.address!) as! [BMTransaction])
        
        AppModel.sharedManager().addDelegate(self)
    }
    
    init(state:TransactionSelectedState) {
        super.init()
        
        self.isSegment = true
        self.selectedState = state
        
        self.search()
        
        AppModel.sharedManager().addDelegate(self)
    }
    
    override init() {
        super.init()
        
        if let transactions = AppModel.sharedManager().transactions {
            self.transactions = transactions as! [BMTransaction]
        }
        
        AppModel.sharedManager().addDelegate(self)
    }
    
    deinit {
        AppModel.sharedManager().removeDelegate(self)
    }
    
//MARK: - Actions

    public func cancelTransation(indexPath:IndexPath?) {
        let transaction:BMTransaction = (indexPath == nil ? self.transaction! : transactions[indexPath!.row])

        if let top = UIApplication.getTopMostViewController() {
            top.confirmAlert(title: Localizable.shared.strings.cancel_transaction, message: Localizable.shared.strings.cancel_transaction_text, cancelTitle: Localizable.shared.strings.no, confirmTitle: Localizable.shared.strings.yes, cancelHandler: { (_) in
                
            }, confirmHandler: { (_) in
                transaction.status = Localizable.shared.strings.cancelled.lowercased()
                self.onDataUpdated?(indexPath,transaction)
            })
        }
    }
    
    public func deleteTransation(indexPath:IndexPath?) {
        let transaction:BMTransaction = (indexPath == nil ? self.transaction! : transactions[indexPath!.row])

        if let top = UIApplication.getTopMostViewController() {
            top.confirmAlert(title: Localizable.shared.strings.delete_transaction_title, message: Localizable.shared.strings.delete_transaction_text, cancelTitle: Localizable.shared.strings.cancel, confirmTitle: Localizable.shared.strings.delete, cancelHandler: { (_ ) in
                
            }, confirmHandler: { (_ ) in
                if indexPath?.row != nil {
                    self.transactions.remove(at: indexPath!.row)
                }
                self.onDataDeleted?(indexPath,transaction)
            })
        }
    }
    
    public func repeatTransation(transaction:BMTransaction) {
        if let top = UIApplication.getTopMostViewController() {
            let vc = SendViewController()
            vc.transaction = transaction
            top.pushViewController(vc: vc)
        }
    }
    
    public func trailingSwipeActions(indexPath:IndexPath) -> UISwipeActionsConfiguration? {
        let transaction = transactions[indexPath.row]
        
        let cancel = UIContextualAction(style: .normal, title: nil) { (action, view, handler) in
            handler(true)
            self.cancelTransation(indexPath: indexPath)
        }
        cancel.image = IconRowCancel()
        cancel.backgroundColor = UIColor.main.cerulean
        
        var rep:UIContextualAction? = nil
        
        if !transaction.isShielded {
            rep = UIContextualAction(style: .normal, title: nil) { (action, view, handler) in
                handler(true)
                self.repeatTransation(transaction: transaction)
            }
            rep!.image = IconRowRepeat()
            rep!.backgroundColor = UIColor.main.deepSeaBlue
        }
        
        let delete = UIContextualAction(style: .normal, title: nil) { (action, view, handler) in
            handler(true)
            self.deleteTransation(indexPath: indexPath)
        }
        delete.image = IconRowDelete()
        delete.backgroundColor = UIColor.main.coral
        
        var actions = [UIContextualAction]()
        
        if transaction.canCancel {
            actions.append(cancel)
        }
        
        if !transaction.isIncome && rep != nil {
            actions.append(rep!)
        }
        
        if transaction.canDelete {
            actions.append(delete)
        }
        
        let configuration = UISwipeActionsConfiguration(actions: actions.reversed())
        configuration.performsFirstActionWithFullSwipe = false
        return configuration
    }
}

//MARK: - Delegate

extension TransactionViewModel : WalletModelDelegate {
    
    func onReceivedTransactions(_ transactions: [BMTransaction]) {
        DispatchQueue.main.async {
            if self.isSegment {
                self.search()
            }
            else{
                if self.address != nil {
                    self.transactions = (AppModel.sharedManager().getTransactionsFrom(self.address!) as! [BMTransaction])
                }
                else if self.transaction != nil {
                    if let transaction = transactions.first(where: { $0.id == self.transaction?.id }) {
                        self.transaction = transaction
                    }
                }
                else if let id = self.assetId {
                    self.transactions = transactions.filter { tr in
                        return tr.assetId == id
                    }
                }
                else{
                    self.transactions = transactions
                }
                self.onDataChanged?()
            }
        }
    }
    
    public func search() {
        DispatchQueue.global(qos: .background).async { [weak self] in
            guard let strongSelf = self else { return }
            
            var allTransactions = [BMTransaction]()
            if let transactions = AppModel.sharedManager().transactions as? [BMTransaction] {
                allTransactions.append(contentsOf: transactions)
            }
            
            switch strongSelf.selectedState {
            case .all:
                break
            case .sent:
                allTransactions = allTransactions.filter { $0.isIncome == false}
            case .received:
                allTransactions = allTransactions.filter { $0.isIncome == true}
            case .in_progress:
                allTransactions = allTransactions.filter { $0.enumStatus == BMTransactionStatusPending || $0.enumStatus == BMTransactionStatusInProgress || $0.enumStatus == BMTransactionStatusRegistering}
            }
            
            if let id = strongSelf.assetId {
                allTransactions = allTransactions.filter { tr in
                    return tr.assetId == id
                }
            }
            
            if !strongSelf.searchString.isEmpty {
                for tr in allTransactions {
                    let receiverName = AppModel.sharedManager().findAddress(byID: tr.receiverAddress)?.label
                    let senderName = AppModel.sharedManager().findAddress(byID: tr.senderAddress)?.label
                    
                    tr.senderContactName = senderName == nil ? String.empty() : senderName!
                    tr.receiverContactName = receiverName == nil ? String.empty() : receiverName!
                }
                
                let filterdObjects = allTransactions.filter {
                    $0.receiverAddress.lowercased().starts(with: strongSelf.searchString.lowercased()) ||
                        $0.senderAddress.lowercased().starts(with: strongSelf.searchString.lowercased()) ||
                        $0.id.lowercased().starts(with: strongSelf.searchString.lowercased()) ||
                        $0.kernelId.lowercased().starts(with: strongSelf.searchString.lowercased()) ||
                        $0.comment.lowercased().starts(with:strongSelf.searchString.lowercased()) || $0.senderContactName.lowercased().starts(with:strongSelf.searchString.lowercased()) || $0.receiverContactName.lowercased().starts(with:strongSelf.searchString.lowercased())
                }
                
                strongSelf.transactions.removeAll()
                strongSelf.transactions.append(contentsOf: filterdObjects)
            }
            else{
                strongSelf.transactions.removeAll()
                strongSelf.transactions.append(contentsOf: allTransactions)
            }
            
            DispatchQueue.main.async {
                strongSelf.onDataChanged?()
            }
        }
    }
}
