//
// BaseTableViewController.swift
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

import Foundation

class BaseTableViewController: BaseViewController {
    
    var tableView: UITableView!
    var tableStyle = UITableView.Style.plain
    var contentArray:[Any]?

    private var offset:CGFloat = 0
    private var maxOffset:CGFloat = 65
    private var minOffset:CGFloat = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView = UITableView(frame: self.view.bounds, style: tableStyle)
        tableView.backgroundColor = UIColor.main.marine
        tableView.separatorStyle = .none
    
        self.view.addSubview(tableView)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: UIResponder.keyboardWillHideNotification, object: nil)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillShowNotification , object: nil)
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillHideNotification , object: nil)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        var offset:CGFloat = tableStyle == .grouped ? 0 : 0
        if !isGradient {
            offset = offset + 30
        }
        tableView.frame = CGRect(x: 0, y: navigationBarOffset - offset, width: self.view.bounds.width, height: self.view.bounds.size.height - navigationBarOffset + offset)
    }
}

extension BaseTableViewController {
    
    @objc func keyboardWillShow(_ notification: Notification) {
        if let keyboardFrame: NSValue = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue {
            let keyboardRectangle = keyboardFrame.cgRectValue
            let keyboardHeight = keyboardRectangle.height
            
            tableView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: keyboardHeight, right: 0)
        }
    }
    
    @objc func keyboardWillHide(notification: NSNotification) {
        tableView.contentInset = UIEdgeInsets.zero
    }
}


extension BaseTableViewController {
    
//    func rowActionsForAddress(indexPath: IndexPath, array: [BMAddress], afterAction:@escaping (([BMAddress]) -> Void)) -> UISwipeActionsConfiguration? {
//
//        var addresses = array
//        let address:BMAddress = addresses[indexPath.row]
//
//        let delete = UIContextualAction(style: .normal, title: nil) { (action, view, handler) in
//            handler(true)
//
//            let transactions = (AppModel.sharedManager().getTransactionsFrom(address) as! [BMTransaction])
//
//            if transactions.count > 0  {
//                self.showDeleteAddressAndTransactions(indexPath: indexPath)
//            }
//            else{
//                addresses.remove(at: indexPath.row)
//                afterAction(addresses)
//
//                self.tableView.performUpdate({
//                    self.tableView.deleteRows(at: [indexPath], with: .left)
//                }, completion: {
//                    AppModel.sharedManager().prepareDelete(address, removeTransactions: false)
//                })
//            }
//        }
//        delete.image = IconRowDelete()
//        delete.backgroundColor = UIColor.main.orangeRed
//
//        let copy = UIContextualAction(style: .normal, title: nil) { (action, view, handler) in
//            handler(true)
//
//            UIPasteboard.general.string = address.walletId
//            ShowCopied(text: LocalizableStrings.address_copied)
//        }
//        copy.image = IconRowCopy()
//        copy.backgroundColor = UIColor.main.warmBlue
//
//        let edit = UIContextualAction(style: .normal, title: nil) { (action, view, handler) in
//            handler(true)
//            let vc = EditAddressViewController(address: address)
//            self.pushViewController(vc: vc)
//        }
//        edit.image = IconRowEdit()
//        edit.backgroundColor = UIColor.main.steel
//
//        let configuration = UISwipeActionsConfiguration(actions: [delete, copy, edit])
//        configuration.performsFirstActionWithFullSwipe = false
//        return configuration
//    }
//
//
    
//    private func showDeleteAddressAndTransactions(state:AddressesViewController.AddressesSelectedState, indexPath:IndexPath, array:[Any], completion) {
//
//    }
}
