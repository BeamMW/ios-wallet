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
    
    public var isSearching = false
    public var searchingString = String.empty()

    private var searchView:BMSearchView?
    
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
        if isSearching {
            offset = (searchView?.frame.size.height ?? 0) + (searchView?.frame.origin.y ?? 0)
        }
        else if !isGradient {
            offset = offset + 30
        }
        else if isGradient && !isAddStatusView {
            offset = offset + 30
        }
       
        let y = (!isSearching ? (navigationBarOffset - offset) : offset)
        tableView.frame = CGRect(x: 0, y:y , width: self.view.bounds.width, height: self.view.bounds.size.height - y)
    }
    
    @objc public func startSearch(){
        isSearching = true
        
        if searchView == nil {
            searchView = BMSearchView()
            searchView?.onSearchTextChanged = {
                [weak self] text in
                
                guard let strongSelf = self else { return }
                strongSelf.searchingString = text
            }
            searchView?.onCancelSearch = {
                [weak self] in
                guard let strongSelf = self else { return }
                strongSelf.stopSearch()
            }
        }
        
        view.addSubview(searchView!)
        searchView?.show()
    }
    
    @objc public func stopSearch() {
        isSearching = false
        searchView?.hide()
        
        UIView.animate(withDuration: 0.2, animations: {
            self.viewDidLayoutSubviews()
        }) { (_) in
        }
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

