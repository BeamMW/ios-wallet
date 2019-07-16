//
// TableView.swift
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
    
    func register(_ cellTypes: [Reusable.Type]) {
        for cellType in cellTypes {
            self.register(UINib(nibName: cellType.reuseIdentifier, bundle: nil), forCellReuseIdentifier: cellType.reuseIdentifier)
        }
    }
    
    func register(_ cellType: Reusable.Type) {
        self.register(UINib(nibName: cellType.reuseIdentifier, bundle: nil), forCellReuseIdentifier: cellType.reuseIdentifier)
    }
    
    func dequeueReusableCell<T>(withType type: T.Type, for indexPath: IndexPath) -> T where T: Reusable {
        return self.dequeueReusableCell(withIdentifier: T.reuseIdentifier, for: indexPath) as! T
    }
}

extension UITableView {

    func performUpdate(_ update: ()->Void, completion: (()->Void)?) {
        
        CATransaction.begin()
        CATransaction.setCompletionBlock(completion)
        
        // Table View update on row / section
        beginUpdates()
        update()
        endUpdates()
        
        CATransaction.commit()
    }
    
    public func findPath(_ row:AnyClass) -> IndexPath? {
        for cell in visibleCells {
            if cell.isKind(of: row) {
                return self.indexPath(for: cell)
            }
        }
        return nil
    }
    
    public func findCell(_ row:AnyClass) -> UITableViewCell? {
        for cell in visibleCells {
            if cell.isKind(of: row) {
                return cell
            }
        }
        return nil
    }
    
    public func reloadRow(_ row: AnyClass, animated:Bool = true) {
        
        for cell in visibleCells {
            
            if cell.isKind(of: row) {
                
                if let path = indexPath(for: cell) {
                    
                    reloadRows(at: [path], with: (animated ? .fade : .none))
                    
                    return
                }
            }
        }
        
        reloadData()
    }
    
    public func scrollToTop() {
        setContentOffset(CGPoint(x: 0, y: 0), animated: false)
    }
    
    public func addPullToRefresh(target:Any?, handler: Selector) {
        
        let refreshControl = UIRefreshControl()
        refreshControl.addTarget(target, action: handler, for: .valueChanged)
        self.refreshControl = refreshControl
    }
    
    public func stopRefreshing() {
        if let control = self.refreshControl {
            if !control.isRefreshing {
                return
            }
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            if let control = self.refreshControl {
                control.endRefreshing()
            }
        }       
    }
}

extension UICollectionView {
    
//    func register(_ cellType: Reusable.Type) {
//        self.register(cellType.self, forCellWithReuseIdentifier: cellType.reuseIdentifier)
//    }
    
    func dequeueReusableCell<T>(withType type: T.Type, for indexPath: IndexPath) -> T where T: Reusable {
        return self.dequeueReusableCell(withReuseIdentifier: T.reuseIdentifier, for: indexPath) as! T
    }
    
    func dequeueReusableSupplementaryView<T>(ofKind elementKind: String, withType type: T.Type, for indexPath: IndexPath) -> T where T: Reusable {
        return self.dequeueReusableSupplementaryView(ofKind: elementKind, withReuseIdentifier: type.reuseIdentifier, for: indexPath) as! T
    }
}

extension UITableView {
    
    func rowsHeight() -> CGFloat {
        var cellsHeight:CGFloat = 0;
        let sections = numberOfSections
        for section in 0..<sections
        {
            
            let rows = numberOfRows(inSection: section)
            
            for row in 0..<rows
            {
                let indexPath = IndexPath(item: row, section: section)
                cellsHeight += self.delegate?.tableView?(self, heightForRowAt: indexPath) ?? 0
            }
        }
        return cellsHeight;
    }
}
