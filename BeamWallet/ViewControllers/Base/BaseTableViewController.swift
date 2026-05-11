//
// BaseTableViewController.swift
// BeamWallet
//
// Copyright 2026 Beam Development
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

    /// Snapshot of `tableView.alwaysBounceVertical` taken before the keyboard
    /// shows; restored on hide so subclasses that opt into bouncing aren't
    /// silently flipped off whenever a field unfocuses.
    private var savedAlwaysBounce: Bool?

    /// View pinned above the bottom safe area, outside the table. The table is
    /// sized to fit the area above it, so content placed here never causes the
    /// table to scroll. Subclasses set this from viewDidLoad. Toggle visibility
    /// with `isHidden`; setting to nil removes it entirely.
    var bottomAccessoryView: UIView? {
        didSet {
            oldValue?.removeFromSuperview()
            if let v = bottomAccessoryView { view.addSubview(v) }
            view.setNeedsLayout()
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView = UITableView(frame: self.view.bounds, style: tableStyle)
        tableView.backgroundColor = UIColor.main.marine
        tableView.separatorStyle = .none
        tableView.alwaysBounceVertical = false

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

        var offset: CGFloat = 0

        if !isGradient {
            offset = 30
        }
        else if isGradient && !isAddStatusView {
            offset = 30
        }

        let y = navigationBarOffset - offset
        let bottomSafe = view.safeAreaInsets.bottom
        var bottomReserved: CGFloat = bottomSafe
        if let acc = bottomAccessoryView, !acc.isHidden {
            let h = acc.frame.height
            acc.frame = CGRect(x: 0, y: view.bounds.height - bottomSafe - h,
                               width: view.bounds.width, height: h)
            bottomReserved = h + bottomSafe
        }
        tableView.frame = CGRect(x: 0, y: y, width: view.bounds.width,
                                 height: view.bounds.height - y - bottomReserved)
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
            if savedAlwaysBounce == nil {
                savedAlwaysBounce = tableView.alwaysBounceVertical
            }
            tableView.alwaysBounceVertical = true

            let lift = keyboardHeight - view.safeAreaInsets.bottom
            if lift > 0 {
                bottomAccessoryView?.transform = CGAffineTransform(translationX: 0, y: -lift)
            }
        }
    }

    @objc func keyboardWillHide(notification: NSNotification) {
        tableView.contentInset = UIEdgeInsets.zero
        tableView.alwaysBounceVertical = savedAlwaysBounce ?? false
        savedAlwaysBounce = nil
        bottomAccessoryView?.transform = .identity
    }
}

