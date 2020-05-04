//
// NotificationViewModel.swift
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

class NotificationViewModel: NSObject {

    public var onDataChanged : (() -> Void)?
    public var onDataDeleted : ((IndexPath?, NotificationItem) -> Void)?
    public var onDataUpdated : ((IndexPath?, NotificationItem) -> Void)?
    
    public var unreads = [NotificationItem]()
    public var reads = [NotificationItem]()

    override init() {
        super.init()
        
        buildItems()
        
        AppModel.sharedManager().addDelegate(self)
    }
    
    deinit {
        AppModel.sharedManager().removeDelegate(self)
    }
    
    private func buildItems() {
        reads.removeAll()
        unreads.removeAll()
        
        for notification in AppModel.sharedManager().notifications as! [BMNotification] {
            let item = NotificationItem(notification: notification)
            if item.name != nil {
                if item.isRead {
                    reads.append(item)
                } else {
                    unreads.append(item)
                }
            }
        }
    }
    
    public func trailingSwipeActions(indexPath:IndexPath) -> UISwipeActionsConfiguration? {
        
        let delete = UIContextualAction(style: .normal, title: nil) { (action, view, handler) in
            handler(true)
            self.deleteNotification(indexPath: indexPath)
        }
        delete.image = IconRowDelete()
        delete.backgroundColor = UIColor.main.coral
        
        var actions = [UIContextualAction]()
        actions.append(delete)
        
        let configuration = UISwipeActionsConfiguration(actions: actions.reversed())
        configuration.performsFirstActionWithFullSwipe = false
        return configuration
    }
    
    private func deleteNotification(indexPath: IndexPath) {
        let item = indexPath.section == 0 ? unreads[indexPath.row] : reads[indexPath.row]
        if indexPath.section == 0 {
            self.unreads.remove(at: indexPath.row)
        }
        else if indexPath.section == 1 {
            self.reads.remove(at: indexPath.row)
        }
        self.onDataDeleted?(indexPath, item)
    }
}

//MARK: - Delegate

extension NotificationViewModel : WalletModelDelegate {
    
    func onNotificationsChanged() {
        DispatchQueue.main.async {
            self.buildItems()
            self.onDataChanged?()
        }
    }
}
