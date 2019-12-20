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
    
//    struct FooterButton {
//        let title:String
//        let color:UIColor
//        let image:UIImage?
//        let target:Any
//        let selector:Selector
//        let borderWidth:CGFloat?
//        let borderColor:UIColor?
//    }
    
    var tableView: UITableView!
    var tableStyle = UITableView.Style.plain
    
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
        
        var offset:CGFloat =  0
       
        if !isGradient {
            offset =  30
        }
        else if isGradient && !isAddStatusView {
            offset = 30
        }
       
        let y = navigationBarOffset - offset
        tableView.frame = CGRect(x: 0, y: y , width: self.view.bounds.width, height: self.view.bounds.size.height - y)
    }
    
//    public func footerView(buttons:[FooterButton]) -> UIView {
//        let view = UIStackView(frame: CGRect(x: 0, y: 0, width: UIScreen.main.bounds.size.width, height: 104))
//        view.spacing = 20
//        view.
//
//        for item in buttons {
//            let button = BMButton.defaultButton(frame: CGRect(x: (UIScreen.main.bounds.size.width - 143) / 2, y: 40, width: 143, height: 44), color: UIColor.main.heliotrope.withAlphaComponent(0.1))
//            button.setImage(item.image, for: .normal)
//            button.setTitle(item.title.lowercased(), for: .normal)
//            button.layer.borderWidth = item.borderWidth ?? 0
//            button.layer.borderColor = item.borderColor?.cgColor ?? UIColor.clear.cgColor
//            button.layer.borderColor = UIColor.main.heliotrope.cgColor
//            button.setTitleColor(UIColor.main.heliotrope, for: .normal)
//            button.addTarget(item.target, action: item.selector, for: .touchUpInside)
//            view.addSubview(button)
//        }
//
//        return view
//    }
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

