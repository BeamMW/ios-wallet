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
    
    private var offset:CGFloat = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView = UITableView(frame: self.view.bounds, style: .plain)
        tableView.backgroundColor = UIColor.main.marine
        tableView.separatorStyle = .none
        
        self.view.addSubview(tableView)
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
    
    public func didScroll(scrollView:UIScrollView) {
        if let navigationBar = self.navigationController?.navigationBar as? BMGradientNavigationBar, let navigation = self.navigationController as? BMGradientNavigationController {
            
            offset = scrollView.contentOffset.y

            let contentHeight = scrollView.contentSize.height + scrollView.contentInset.bottom
            
            if  contentHeight > (view.frame.size.height - 50)  {
                
            }
            else{
                offset = 0
            }
            
            print(offset)

            if offset < 0 {
                offset = 0
            }
            else if offset > 65 {
                offset = 65
            }
            
            if offset <= 65 {
                tableView.frame = CGRect(x: 0, y: BMGradientNavigationBar.height - 10 - offset, width: self.view.bounds.width, height: self.view.bounds.height - BMGradientNavigationBar.height + 10 + offset)
                
                navigationBar.offset = offset
                navigation.offset = offset
            }
        }
    }
}
