//
//  BMPopoverMenu.swift
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

import UIKit

extension BMPopoverMenu {
    public static func show(menuArray: [BMPopoverMenuItem], done: @escaping (BMPopoverMenuItem?) -> Void, cancel: @escaping () -> Void) {
        if let rootVC = UIApplication.getTopMostViewController() {
            rootVC.addBlur()

            let generator = UIImpactFeedbackGenerator(style: .medium)
            generator.impactOccurred()
            
            let alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
            
            for item in menuArray {
                if item.action == .delete_transaction || item.action == .delete_address
                || item.action == .delete_address_transactions{
                    alert.addAction(UIAlertAction(title: item.name, style: .destructive, handler: { _ in
                        rootVC.removeBlur()
                        done(item)
                    }))
                }
                else {
                    alert.addAction(UIAlertAction(title: item.name, style: .default, handler: { _ in
                        rootVC.removeBlur()
                        done(item)
                    }))
                }
            }
            
            alert.addAction(UIAlertAction(title: Localizable.shared.strings.cancel, style: Settings.sharedManager().isDarkMode ? .default : .cancel, handler: { _ in
                                   rootVC.removeBlur()
                                   cancel()
                               }))
            
            
            rootVC.present(alert, animated: true)
                        
            if #available(iOS 13, *) {
                
            }
            else {
                if(Settings.sharedManager().isDarkMode) {
                    alert.setBackgroundColor(color: UIColor.black)
                }
            }
        }
    }
    
    public static func showForSender(sender: UIView, with menuArray: [BMPopoverMenuItem], done: @escaping (BMPopoverMenuItem?) -> Void, cancel: @escaping () -> Void) {
        sharedMenu.showForSender(sender: sender, or: nil, with: menuArray, done: done, cancel: cancel)
    }
    
    public static func showForSenderAssets(sender: UIView, with menuArray: [BMPopoverMenuItem], done: @escaping (BMPopoverMenuItem?) -> Void, cancel: @escaping () -> Void) {
        sharedMenu.showForSenderAssets(sender: sender, or: nil, with: menuArray, done: done, cancel: cancel)
    }
    
    public static func showForSenderFrame(senderFrame: CGRect, with menuArray: [BMPopoverMenuItem], done: @escaping (BMPopoverMenuItem?) -> Void, cancel: @escaping () -> Void) {
        sharedMenu.showForSender(sender: nil, or: senderFrame, with: menuArray, done: done, cancel: cancel)
    }
}

class BMPopoverMenu: NSObject {
    enum BMPopoverMenuItemAction: Int {
        case show_qr_code = 1
        case copy_address = 2
        case edit_address = 4
        case delete_address = 5
        case payment_proof = 6
        case export_transactions = 7
        case cancel_transaction = 8
        case delete_transaction = 9
        case edit_category = 10
        case delete_category = 11
        case delete_address_transactions = 12
        case repeat_transaction = 13
        case search = 14
        case share = 15
        case copy = 16
        case save_contact = 17
        case share_offline_token = 18
        case share_online_token = 19
        case share_pool_token = 20
        case asset = 21
        case open_dapp = 22
    }
    
    class BMPopoverMenuItem {
        var name: String
        var icon: String?
        var action: BMPopoverMenuItemAction
        var selected:Bool? = nil
        var id:Int? = nil

        init(name: String, icon: String?, action: BMPopoverMenuItemAction) {
            self.name = name
            self.icon = icon
            self.action = action
        }
        
        init(name: String, icon: String?, action: BMPopoverMenuItemAction, selected: Bool?) {
            self.name = name
            self.icon = icon
            self.action = action
            self.selected = selected
        }
    }
    
    var isAssets = false
    var sender: UIView?
    var senderFrame: CGRect?
    
    var done: ((_ selectedItem: BMPopoverMenuItem?) -> Void)!
    var cancel: (() -> Void)!
    
    fileprivate var menuItems: [BMPopoverMenuItem]!
    
    fileprivate let animationDuration: CGFloat = 0.3
    
    fileprivate let defaultMargin: CGFloat = 15.0
    fileprivate let menuWidth: CGFloat = 270.0
    fileprivate let menuRowHeight: CGFloat = 50.0
    
    fileprivate var senderRect: CGRect = CGRect.zero
    fileprivate var popMenuOriginX: CGFloat = 0
    fileprivate var popMenuFrame: CGRect = CGRect.zero
    fileprivate var popMenuHeight: CGFloat {
        return menuRowHeight * CGFloat(menuItems.count) + 30
    }
    
    fileprivate lazy var popOverMenu: BMPopOverMenuView = {
        let menu = BMPopOverMenuView(frame: CGRect.zero)
        menu.alpha = 0
        self.backgroundView.addSubview(menu)
        return menu
    }()
    
    fileprivate static var sharedMenu: BMPopoverMenu {
        struct Static {
            static let instance: BMPopoverMenu = BMPopoverMenu()
        }
        return Static.instance
    }
    
    fileprivate lazy var backgroundView: UIView = {
        let view = UIView(frame: UIScreen.main.bounds)
        view.addGestureRecognizer(self.tapGesture)
        return view
    }()
    
    fileprivate lazy var tapGesture: UITapGestureRecognizer = {
        let gesture = UITapGestureRecognizer(target: self, action: #selector(onBackgroudViewTapped(gesture:)))
        gesture.delegate = self
        return gesture
    }()
    
    @objc fileprivate func onBackgroudViewTapped(gesture: UIGestureRecognizer) {
        doneActionWithSelectedIndex(selectedItem: nil)
    }
    
    fileprivate func doneActionWithSelectedIndex(selectedItem: BMPopoverMenuItem?) {
        UIView.animate(withDuration: TimeInterval(animationDuration),
                       animations: {
                           self.popOverMenu.alpha = 0
                           self.popOverMenu.transform = CGAffineTransform(scaleX: 0.1, y: 0.1)
        }) { isFinished in
            if isFinished {
                self.backgroundView.removeFromSuperview()
                if selectedItem == nil {
                    if self.cancel != nil {
                        self.cancel()
                    }
                }
                else {
                    if self.done != nil {
                        self.done(selectedItem)
                    }
                }
            }
        }
    }
    
    fileprivate func showForSenderAssets(sender: UIView?, or senderFrame: CGRect?, with menuItems: [BMPopoverMenuItem]!, done: @escaping (BMPopoverMenuItem?) -> Void, cancel: (() -> Void)? = nil) {
        if sender == nil, senderFrame == nil {
            return
        }
        if menuItems.count == 0 {
            return
        }
        
        self.isAssets = true
        self.sender = sender
        self.senderFrame = senderFrame
        self.menuItems = menuItems
        self.done = done
        self.cancel = cancel
        
        backgroundView.frame = CGRect(x: 0, y: 0, width: UIScreen.main.bounds.size.width, height: UIScreen.main.bounds.size.height)
        
        UIApplication.shared.keyWindow?.addSubview(backgroundView)
        
        adjustPostionForPopOverMenu()
    }
    
    fileprivate func showForSender(sender: UIView?, or senderFrame: CGRect?, with menuItems: [BMPopoverMenuItem]!, done: @escaping (BMPopoverMenuItem?) -> Void, cancel: (() -> Void)? = nil) {
        if sender == nil, senderFrame == nil {
            return
        }
        if menuItems.count == 0 {
            return
        }
        
        self.isAssets = false
        self.sender = sender
        self.senderFrame = senderFrame
        self.menuItems = menuItems
        self.done = done
        self.cancel = cancel
        
        backgroundView.frame = CGRect(x: 0, y: 0, width: UIScreen.main.bounds.size.width, height: UIScreen.main.bounds.size.height)
        
        UIApplication.shared.keyWindow?.addSubview(backgroundView)
        
        adjustPostionForPopOverMenu()
    }
    
    fileprivate func adjustPostionForPopOverMenu() {
        setupPopOverMenu()
        
        showIfNeeded()
    }
    
    fileprivate func setupPopOverMenu() {
        popOverMenu.transform = CGAffineTransform(scaleX: 1, y: 1)
        
        if let sender = self.sender {
            if let superView = sender.superview {
                senderRect = superView.convert(sender.frame, to: backgroundView)
            }
        }
        else if let frame = senderFrame {
            senderRect = frame
        }
        senderRect.origin.y = min(UIScreen.main.bounds.size.height, senderRect.origin.y)
        
        var senderXCenter: CGPoint = CGPoint(x: senderRect.origin.x + senderRect.size.width / 2, y: 0)
        let menuCenterX: CGFloat = CGFloat(menuWidth / 2)
        var menuX: CGFloat = 0
        if senderXCenter.x + menuCenterX > UIScreen.main.bounds.size.width {
            senderXCenter.x = min(senderXCenter.x - (UIScreen.main.bounds.size.width - menuWidth - defaultMargin), menuWidth)
            menuX = UIScreen.main.bounds.size.width - menuWidth - defaultMargin
        }
        else {
            senderXCenter.x = menuWidth / 2
            menuX = senderRect.origin.x + senderRect.size.width / 2 - menuWidth / 2
        }
        popMenuOriginX = menuX
        
        popMenuFrame = CGRect(x: popMenuOriginX, y: senderRect.origin.y + senderRect.size.height, width: menuWidth, height: popMenuHeight)
        
        if popMenuFrame.origin.y + popMenuFrame.size.height > UIScreen.main.bounds.size.height {
            popMenuFrame = CGRect(x: popMenuOriginX, y: senderRect.origin.y + senderRect.size.height, width: menuWidth, height: UIScreen.main.bounds.size.height - popMenuFrame.origin.y)
        }
        
        popOverMenu.show(frame: popMenuFrame, menuItems: menuItems, isAsset: self.isAssets) { selectedItem in
            self.doneActionWithSelectedIndex(selectedItem: selectedItem)
        }
    }
    
    fileprivate func showIfNeeded() {
        popOverMenu.transform = CGAffineTransform(scaleX: 0.1, y: 0.1)
        UIView.animate(withDuration: TimeInterval(animationDuration), animations: {
            self.popOverMenu.alpha = 1
            self.popOverMenu.transform = CGAffineTransform(scaleX: 1, y: 1)
        })
    }
}

extension BMPopoverMenu: UIGestureRecognizerDelegate {
    public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        let touchPoint = touch.location(in: backgroundView)
        let touchClass: String = NSStringFromClass((touch.view?.classForCoder)!) as String
        if touchClass == "UITableViewCellContentView" {
            return false
        }
        else if CGRect(x: 0, y: 0, width: menuWidth, height: menuRowHeight).contains(touchPoint) {
            doneActionWithSelectedIndex(selectedItem: nil)
            return false
        }
        return true
    }
}

private class BMPopOverMenuView: UIView {
    private var isAssets = false
    
    fileprivate var menuItems: [BMPopoverMenu.BMPopoverMenuItem]!
    fileprivate var done: ((BMPopoverMenu.BMPopoverMenuItem) -> Void)!
    
    lazy var menuTableView: UITableView = {
        let tableView = UITableView(frame: CGRect.zero, style: UITableView.Style.plain)
        tableView.delegate = self
        tableView.dataSource = self
        tableView.clipsToBounds = true
        tableView.rowHeight = 50
        tableView.separatorStyle = UITableViewCell.SeparatorStyle.none
        return tableView
    }()
    
    fileprivate func show(frame: CGRect, menuItems: [BMPopoverMenu.BMPopoverMenuItem]!, isAsset:Bool, done: @escaping ((BMPopoverMenu.BMPopoverMenuItem) -> Void)) {
        self.frame = frame

        self.isAssets = isAsset
        
        if !isAsset {
            self.backgroundColor = Settings.sharedManager().isDarkMode ? UIColor.black : UIColor(displayP3Red: 230.0/255.0, green: 233.0/255.0, blue: 236.0/255.0, alpha: 1.0)
        }
        else {
            self.backgroundColor = UIColor.main.marine
        }
        
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOffset = CGSize(width: 0.0, height: 2.0)
        layer.shadowRadius = 24.0
        layer.shadowOpacity = 0.9
        layer.cornerRadius = 12
        
        self.menuItems = menuItems
        self.done = done
        
        menuTableView.register([PopoverCell.self, PopoverAssetCell.self])
        if !isAsset {
            menuTableView.backgroundColor = UIColor.clear
            menuTableView.frame = CGRect(x: 0, y: 15, width: frame.size.width, height: frame.size.height - 15)
            menuTableView.separatorStyle = .singleLine
            menuTableView.separatorColor = Settings.sharedManager().isDarkMode ? UIColor.white.withAlphaComponent(0.1) : UIColor(displayP3Red: 226.0/255.0, green: 226.0/255.0, blue: 226.0/255.0, alpha: 1.0)
            menuTableView.tableFooterView = UIView()
        }
        else {
            menuTableView.cornerRadius = 12
            menuTableView.backgroundColor = UIColor.main.cellBackgroundColor
            menuTableView.frame = CGRect(x: 0, y: 0, width: frame.size.width, height: frame.size.height)
            menuTableView.separatorStyle = .none
            menuTableView.tableFooterView = UIView(frame: CGRect(x: 0, y: 0, width: 0, height: 15))
            menuTableView.tableHeaderView = UIView(frame: CGRect(x: 0, y: 0, width: 0, height: 15))
        }
        menuTableView.reloadData()
        
        addSubview(menuTableView)
    }
}

extension BMPopOverMenuView: UITableViewDataSource {
  
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return menuItems.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if self.isAssets {
            let id = menuItems[indexPath.row].id ?? 0
            let asset = AssetsManager.shared().getAsset(Int32(id))
            
            let cell = tableView.dequeueReusableCell(withType: PopoverAssetCell.self, for: indexPath)
            cell.backgroundColor = UIColor.clear
            
            cell.selectedBackgroundView = UIView()
            cell.selectedBackgroundView?.backgroundColor = UIColor.white.withAlphaComponent(0.1)
            
            cell.label.text = menuItems[indexPath.row].name
            
            if let asset = asset {
                let id = "(\(asset.assetId))"
                let fullString = menuItems[indexPath.row].name + " " + id
                
                let attributedString = NSMutableAttributedString(string: fullString)
                let range = (fullString as NSString).range(of: id)
                attributedString.addAttribute(.foregroundColor, value: UIColor.white.withAlphaComponent(0.5), range: range)
               
                cell.label.attributedText = attributedString
                cell.iconView.setAsset(asset)
            }
            
            if menuItems[indexPath.row].selected == true {
                cell.label.font = BoldFont(size: 16)
                cell.label.textColor = UIColor.main.brightTeal
            }
            else {
                cell.label.font = RegularFont(size: 16)
                cell.label.textColor = UIColor.white
            }
            
            return cell
        }
        else {
            let cell = tableView.dequeueReusableCell(withType: PopoverCell.self, for: indexPath)
            
            if let image = self.menuItems[indexPath.row].icon {
                cell.iconView.image = UIImage(named: image)?.withRenderingMode(.alwaysTemplate)
                cell.iconView.tintColor = Settings.sharedManager().isDarkMode ? UIColor.white : UIColor.main.marineOriginal
            }
            else {
                cell.iconView.image = nil
            }
            
            cell.backgroundColor = UIColor.clear
            
            cell.selectedBackgroundView = UIView()
            cell.selectedBackgroundView?.backgroundColor = Settings.sharedManager().isDarkMode ? UIColor.main.marine.withAlphaComponent(0.7) : UIColor.white.withAlphaComponent(0.5)
            
            cell.label.textColor = Settings.sharedManager().isDarkMode ? UIColor.white : UIColor.main.marineOriginal
            cell.label.text = menuItems[indexPath.row].name
            
            return cell
        }
    }
}

extension BMPopOverMenuView: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        if done != nil {
            done(menuItems[indexPath.row])
        }
    }
}
