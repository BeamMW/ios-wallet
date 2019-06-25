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

    public var onDataChanged : (() -> Void)?
    public var onDataDeleted : ((IndexPath?, BMTransaction) -> Void)?
    public var onDataUpdated : ((IndexPath?, BMTransaction) -> Void)?

    public var transactions = [BMTransaction]()

    public var address:BMAddress?

    public var transaction:BMTransaction?
    
    public var isSearch = false {
        didSet{
            if !isSearch {
                searchString = String.empty()
                transactions.removeAll()
                transactions.append(contentsOf: (AppModel.sharedManager().transactions as! [BMTransaction]))
                onDataChanged?()
            }
            else{
                search()
                onDataChanged?()
            }
        }
    }
    
    public var searchString = String.empty() {
        didSet{
            search()
            onDataChanged?()
        }
    }

    init(transaction:BMTransaction) {
        super.init()
        
        AppModel.sharedManager().addDelegate(self)
        
        self.transaction = transaction
    }
    
    init(address:BMAddress) {
        super.init()
        
        self.address = address
        
        self.transactions = (AppModel.sharedManager().getTransactionsFrom(self.address!) as! [BMTransaction])
        
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
    
    public func cancelTransation(indexPath:IndexPath?) {
        let transaction:BMTransaction = (indexPath == nil ? self.transaction! : transactions[indexPath!.row])

        if let top = UIApplication.getTopMostViewController() {
            top.confirmAlert(title: Localizables.shared.strings.cancel_transaction, message: Localizables.shared.strings.cancel_transaction_text, cancelTitle: Localizables.shared.strings.no, confirmTitle: Localizables.shared.strings.yes, cancelHandler: { (_) in
                
            }, confirmHandler: { (_) in
                transaction.status = Localizables.shared.strings.cancelled.lowercased()
                self.onDataUpdated?(indexPath,transaction)
            })
        }
    }
    
    public func deleteTransation(indexPath:IndexPath?) {
        let transaction:BMTransaction = (indexPath == nil ? self.transaction! : transactions[indexPath!.row])

        if let top = UIApplication.getTopMostViewController() {
            top.confirmAlert(title: Localizables.shared.strings.delete_transaction_title, message: Localizables.shared.strings.delete_transaction_text, cancelTitle: Localizables.shared.strings.cancel, confirmTitle: Localizables.shared.strings.delete, cancelHandler: { (_ ) in
                
            }, confirmHandler: { (_ ) in
                if indexPath?.row != nil {
                    self.transactions.remove(at: indexPath!.row)
                }
                self.onDataDeleted?(indexPath,transaction)
            })
        }
    }
    
    public func onRepeat(transaction:BMTransaction) {
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
        cancel.backgroundColor = UIColor.main.steel
        
        let rep = UIContextualAction(style: .normal, title: nil) { (action, view, handler) in
            handler(true)
           self.onRepeat(transaction: transaction)
        }
        rep.image = IconRowRepeat()
        rep.backgroundColor = UIColor.main.brightBlue
        
        let delete = UIContextualAction(style: .normal, title: nil) { (action, view, handler) in
            handler(true)
            self.deleteTransation(indexPath: indexPath)
        }
        delete.image = IconRowDelete()
        delete.backgroundColor = UIColor.main.orangeRed
        
        var actions = [UIContextualAction]()
        
        if transaction.canCancel {
            actions.append(cancel)
        }
        
        if !transaction.isIncome {
            actions.append(rep)
        }
        
        if transaction.canDelete {
            actions.append(delete)
        }
        
        let configuration = UISwipeActionsConfiguration(actions: actions.reversed())
        configuration.performsFirstActionWithFullSwipe = false
        return configuration
    }
    
    private func search() {
        transactions.removeAll()

        if !searchString.isEmpty {
            let all = AppModel.sharedManager().transactions as! [BMTransaction]
            
            for tr in all {
                let receiverName = AppModel.sharedManager().findAddress(byID: tr.receiverAddress)?.label
                let senderName = AppModel.sharedManager().findAddress(byID: tr.senderAddress)?.label

                tr.senderContactName = senderName == nil ? String.empty() : senderName!
                tr.receiverContactName = receiverName == nil ? String.empty() : receiverName!
            }
            
            let filterdObjects = all.filter {
                $0.receiverAddress.lowercased().starts(with: searchString.lowercased()) ||
                    $0.senderAddress.lowercased().starts(with: searchString.lowercased()) ||
                    $0.id.lowercased().starts(with: searchString.lowercased()) ||
                    $0.comment.lowercased().contains(searchString.lowercased()) ||
                    $0.senderContactName.lowercased().contains(searchString.lowercased()) ||
                    $0.receiverContactName.lowercased().contains(searchString.lowercased())
            }
            
            transactions.append(contentsOf: filterdObjects)
        }
    }
}

extension TransactionViewModel : WalletModelDelegate {
    func onReceivedTransactions(_ transactions: [BMTransaction]) {
        DispatchQueue.main.async {
            if self.isSearch {
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
                else{
                    self.transactions = transactions
                }
            }
     
            self.onDataChanged?()
        }
    }
}
