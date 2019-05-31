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
        
        if let navigationBar = self.navigationController?.navigationBar as? BMGradientNavigationBar, let navigation = self.navigationController as? BMGradientNavigationController {
            
            navigationBar.offset = offset
            navigation.offset = offset < minOffset ? minOffset : offset
        }
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        if isNavigationGradient {
            let offset:CGFloat = tableView.style == .grouped ? 70 : 50
            tableView.frame = CGRect(x: 0, y: BMGradientNavigationBar.height - offset, width: self.view.bounds.width, height: self.view.bounds.size.height - (BMGradientNavigationBar.height - offset))
        }
        else{
            tableView.frame = self.view.bounds
        }
    }
    
    private func scrollAvailable() -> Bool {
        let contentHeight = self.tableView.contentSize.height + self.tableView.contentInset.bottom
        return contentHeight > (self.view.frame.size.height - 50)
    }
    
    private func layoutWithOffset(animated:Bool) {
        print(offset)
        
        if let navigationBar = self.navigationController?.navigationBar as? BMGradientNavigationBar, let navigation = self.navigationController as? BMGradientNavigationController {

            if animated {
                UIView.animate(withDuration: 0.3) {
                    
                    navigationBar.offset = self.offset
                    navigation.offset = self.offset < self.minOffset ? self.minOffset : self.offset
                    
                    if  self.scrollAvailable() {
                        self.tableView.setContentOffset(CGPoint(x: 0, y: self.offset - 88), animated: false)
                    }
                }
            }
            else{
                navigationBar.offset = self.offset
                navigation.offset = self.offset < self.minOffset ? self.minOffset : self.offset
            }
        }
    }
    
    public func didEndScroll(scrollView:UIScrollView) {
        if isNavigationGradient {

            if offset > minOffset && self.scrollAvailable() {
                let progress = (offset/maxOffset)
                if progress > 0.1 && progress < 1 {
                    offset = maxOffset
                    
                    layoutWithOffset(animated: true)
                }
                else if progress <= 0.1 {
                    offset = minOffset
                    
                    layoutWithOffset(animated: true)
                }
            }
        }
    }
    
    public func didScroll(scrollView:UIScrollView) {
        if isNavigationGradient {
            
            offset = scrollView.contentOffset.y + 88
            
            if offset > maxOffset {
                offset = maxOffset
            }
            
            layoutWithOffset(animated: false)
        }
    }
}
