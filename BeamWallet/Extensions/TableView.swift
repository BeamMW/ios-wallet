//
//  TableView.swift
//  BeamWallet
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
import UIKit

protocol Reusable {
    
    static var reuseIdentifier: String { get }
}

extension Reusable {
    
    static var reuseIdentifier: String {
        return String(describing: self)
    }
}

extension UITableViewCell: Reusable { }
extension UICollectionReusableView: Reusable { }

extension UITableView {
    
    func register(_ cellType: Reusable.Type) {
        self.register(UINib(nibName: cellType.reuseIdentifier, bundle: nil), forCellReuseIdentifier: cellType.reuseIdentifier)
    }
    
    func dequeueReusableCell<T>(withType type: T.Type, for indexPath: IndexPath) -> T where T: Reusable {
        return self.dequeueReusableCell(withIdentifier: T.reuseIdentifier, for: indexPath) as! T
    }
}

extension UITableView {

    public func addPullToRefresh(target:Any?, handler: Selector) {
        
        let refreshControl = UIRefreshControl()
        refreshControl.addTarget(target, action: handler, for: .valueChanged)
        self.refreshControl = refreshControl
    }
    
    public func stopRefreshing() {
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            if let control = self.refreshControl {
                control.endRefreshing()
            }
        }       
    }
}
