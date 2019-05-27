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
            navigation.offset = offset            
        }
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        if self.navigationController is BMGradientNavigationController {
            tableView.frame = CGRect(x: 0, y: BMGradientNavigationBar.height - 10 - offset, width: self.view.bounds.width, height: self.view.bounds.height - BMGradientNavigationBar.height + 10 + offset)
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
        if let navigationBar = self.navigationController?.navigationBar as? BMGradientNavigationBar, let navigation = self.navigationController as? BMGradientNavigationController {

            UIView.animate(withDuration: animated ? 0.3 : 0) {
                
                navigationBar.offset = self.offset
                navigation.offset = self.offset
                
                if  self.scrollAvailable() {
                    self.tableView.frame = CGRect(x: 0, y: BMGradientNavigationBar.height - 10 - self.offset, width: self.view.bounds.width, height: self.view.bounds.height - BMGradientNavigationBar.height + 10 + self.offset)
                    
                    if animated {
                        self.tableView.setContentOffset(CGPoint(x: 0, y: self.offset), animated: false)
                    }
                }
            }
        }
    }
    
    public func didEndScroll(scrollView:UIScrollView) {
        if let _ = self.navigationController?.navigationBar as? BMGradientNavigationBar, let _ = self.navigationController as? BMGradientNavigationController {

            if  self.scrollAvailable() {
                if offset > minOffset {
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
    }
    
    public func didScroll(scrollView:UIScrollView) {
        if let _ = self.navigationController?.navigationBar as? BMGradientNavigationBar, let _ = self.navigationController as? BMGradientNavigationController {
            
            offset = scrollView.contentOffset.y
            print(offset)
            
            if offset < minOffset {
                offset = minOffset
            }
            else if offset > maxOffset {
                offset = maxOffset
            }
            
           // if offset <= maxOffset {
                layoutWithOffset(animated: false)
          //  }
        }
    }
}
