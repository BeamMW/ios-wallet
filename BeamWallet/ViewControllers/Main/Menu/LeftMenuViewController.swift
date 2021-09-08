//
// LeftMenuViewController.swift
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

class MenuItem {
    
    public var name:String!
    public var icon:UIImage?
    public var selected:Bool!
    public var type:Any!

    init(name:String!, icon:UIImage?, selected:Bool!, type:Any!) {
        self.name = name
        self.icon = icon
        self.selected = selected
        self.type = type
    }
}

class LeftMenuViewController: BaseTableViewController {
    
    private var buyButton:UIButton!
    private var logoView:UIImageView!

    private var items = [MenuItem(name: Localizable.shared.strings.wallet, icon: IconWallet(), selected: true, type: WalletViewController.self), MenuItem(name: Localizable.shared.strings.addresses, icon: IconAddresses(), selected: false, type: AddressesViewController.self), MenuItem(name: Localizable.shared.strings.notifications, icon: IconNotifications(), selected: false, type: NotificationsViewController.self), MenuItem(name: Localizable.shared.strings.dAppStore, icon: IconDappStore(), selected: false, type: DAOAppsViewController.self), MenuItem(name: Localizable.shared.strings.settings, icon: IconSettings(), selected: false, type: SettingsViewController.self)]
    //MenuItem(name: Localizable.shared.strings.logout, icon: IconLogout(), selected: false, type: AnyClass.self)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        Settings.sharedManager().addDelegate(self)
        AppModel.sharedManager().addDelegate(self)

        tableView.delegate = self
        tableView.dataSource = self
        
        var height:CGFloat = 180
        var offset:CGFloat = 20
        if Device.screenType == .iPhones_5 || Device.screenType == .iPhones_6  {
            height = 140
        }
        else if Device.isXDevice {
            height = 200
            offset = 35
        }
   
        let header = UIView(frame: CGRect(x: 0, y: 0, width: UIScreen.main.bounds.size.width, height: height))
        logoView = UIImageView(frame: CGRect(x: 0, y: height-80-offset, width: UIScreen.main.bounds.size.width, height: 80))
        logoView.image = UIImage(named: "logo")
        logoView.contentMode = .scaleAspectFit
        header.addSubview(logoView)

        tableView.tableHeaderView = header

        addBackgroundView()
        addFooterView()
        
        NotificationCenter.default.addObserver(self, selector: #selector(openWallet), name: NSNotification.Name(rawValue: "open_wallet"), object: nil)
    }
    
    @objc private func openWallet() {
        let navigationController = sideMenuController!.rootViewController as! UINavigationController
        navigationController.setViewControllers([WalletViewController()], animated: false)
    }
    
    private func addBackgroundView() {
        let colors = [UIColor.main.twilightBlue, (Settings.sharedManager().target == Mainnet && !Settings.sharedManager().isDarkMode) ? UIColor.main.gasine : UIColor.black]

        let gradient: CAGradientLayer = CAGradientLayer()
        gradient.colors = colors.map { $0.cgColor }
        gradient.frame = CGRect(x: 0.0, y: 0.0, width: UIScreen.main.bounds.size.width, height: UIScreen.main.bounds.size.height)
        
        let backgroundImage = UIImageView()
        backgroundImage.clipsToBounds = true
        backgroundImage.contentMode = .scaleToFill
        backgroundImage.frame = CGRect(x: 0.0, y: 0.0, width: UIScreen.main.bounds.size.width, height: UIScreen.main.bounds.size.height)
        backgroundImage.tag = 10
        backgroundImage.layer.addSublayer(gradient)
        tableView.backgroundView = backgroundImage
    }
    
    private func addFooterView() {
        if buyButton != nil {
            buyButton.removeFromSuperview()
            buyButton = nil
        }
        
        let titleParagraphStyle = NSMutableParagraphStyle()
        titleParagraphStyle.alignment = .left
        
        let imageAttachment = NSTextAttachment()
        imageAttachment.image = IconExternalLinkGray()?.maskWithColor(color: Settings.sharedManager().isDarkMode ? UIColor.main.brightTeal.withAlphaComponent(0.5) : UIColor.main.steelGrey)
        let imageString = NSAttributedString(attachment: imageAttachment)
        
        let attributedString = NSMutableAttributedString(string:Localizable.shared.strings.where_buy_beam)
        attributedString.addAttributes([NSAttributedString.Key.paragraphStyle : titleParagraphStyle], range:  NSRange(location: 0, length: attributedString.string.unicodeScalars.count))
        attributedString.addAttributes([NSAttributedString.Key.foregroundColor : UIColor.main.brightTeal.withAlphaComponent(0.5)], range:  NSRange(location: 0, length:attributedString.string.unicodeScalars.count))
        attributedString.append(NSAttributedString(string: "  "))
        attributedString.append(imageString)
        
        let highlightedAttributedString = NSMutableAttributedString(attributedString: attributedString)
        highlightedAttributedString.addAttributes([NSAttributedString.Key.foregroundColor : UIColor.main.brightTeal.withAlphaComponent(0.2)], range:  NSRange(location: 0, length: attributedString.string.unicodeScalars.count))
        
        buyButton = UIButton(frame: CGRect(x: 0, y: UIScreen.main.bounds.size.height-50, width: UIScreen.main.bounds.size.width, height: 50))
        buyButton.setImage(IconBuyLogo(), for: .normal)
        buyButton.contentHorizontalAlignment = .left
        buyButton.imageEdgeInsets = UIEdgeInsets(top: 0, left: 15, bottom: 0, right: 0)
        buyButton.titleEdgeInsets = UIEdgeInsets(top: 0, left: 30, bottom: 0, right: 0)
        buyButton.setAttributedTitle(attributedString, for: .normal)
        buyButton.setAttributedTitle(highlightedAttributedString, for: .highlighted)
        buyButton.titleLabel?.font = RegularFont(size: 16)
        buyButton.addTarget(self, action: #selector(onBuy), for: .touchUpInside)
        view.addSubview(buyButton)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
       
        logoView.width = self.view.bounds.width
        tableView.frame = self.view.bounds
        
        let offset:CGFloat = (Device.screenType == .iPhone_XR || Device.screenType == .iPhone_XSMax || Device.screenType == .iPhones_X_XS) ? 40 : 30
        
        buyButton.frame = CGRect(x: 0, y: self.view.bounds.size.height-50-offset, width: self.view.bounds.size.width, height: 50)
        
        for item in self.items {
            item.selected = false
        }
        
        if let navigationController = sideMenuController?.rootViewController as? UINavigationController
        {
            if navigationController.viewControllers.first is WalletViewController{
                items[0].selected = true
                self.tableView.selectRow(at: IndexPath(row: 0, section: 0), animated: false, scrollPosition: .top)
            }
            else if navigationController.viewControllers.first is NotificationsViewController{
                items[2].selected = true
                self.tableView.selectRow(at: IndexPath(row: 1, section: 0), animated: false, scrollPosition: .top)
            }
            else if navigationController.viewControllers.first is AddressesViewController{
                items[1].selected = true
                self.tableView.selectRow(at: IndexPath(row: 1, section: 0), animated: false, scrollPosition: .top)
            }
            else if navigationController.viewControllers.first is SettingsViewController{
                items[4].selected = true
                self.tableView.selectRow(at: IndexPath(row: 4, section: 0), animated: false, scrollPosition: .top)
            }
            else if navigationController.viewControllers.first is DAOAppsViewController{
                items[3].selected = true
                self.tableView.selectRow(at: IndexPath(row: 3, section: 0), animated: false, scrollPosition: .top)
            }
        }
    }
    
    @objc private func onBuy() {
        self.openUrl(url: URL(string: Settings.sharedManager().whereBuyAddress)!)
    }
}

extension LeftMenuViewController: UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return items.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var cell = tableView.dequeueReusableCell(withIdentifier: "MenuCell")
        
        if(cell == nil) {
            cell = UITableViewCell(style: .default, reuseIdentifier: "MenuCell")
            cell?.backgroundColor = UIColor.clear
            cell?.contentView.backgroundColor = UIColor.clear
            cell?.textLabel?.highlightedTextColor = UIColor.main.brightTeal
            cell?.textLabel?.font = RegularFont(size: 17)
            
            let countView = UIView(frame: CGRect(x: 39, y: 13, width: 12, height: 12));
            countView.layer.cornerRadius = 6
            countView.backgroundColor = UIColor.main.green
            countView.glow()
            countView.tag = 10
            countView.isHidden = true
            
            let countLabel = UILabel(frame: countView.bounds)
            countLabel.textAlignment = .center
            countLabel.font = RegularFont(size: 10)
            countLabel.adjustsFontSizeToFitWidth = true
            countLabel.minimumScaleFactor = 0.5
            countLabel.textColor = UIColor.main.marineOriginal
            countLabel.tag = 10
            countView.addSubview(countLabel)
            
            cell?.contentView.addSubview(countView)
        }
        
        cell?.textLabel?.textColor = Settings.sharedManager().isDarkMode ? UIColor.main.steel : UIColor.main.steelGrey
        cell?.textLabel?.text = items[indexPath.row].name
        cell?.imageView?.image = items[indexPath.row].icon?.maskWithColor(color: Settings.sharedManager().isDarkMode ? UIColor.main.steel : UIColor.main.steelGrey)
        cell?.imageView?.highlightedImage = items[indexPath.row].icon?.maskWithColor(color: UIColor.main.brightTeal)

        let selectedBackgroundView = UIImageView(frame: CGRect(x: 0, y: 0, width: UIScreen.main.bounds.size.width, height: 60))
        selectedBackgroundView.image = MenuSelectedBackground();
        cell?.selectedBackgroundView = selectedBackgroundView
        
        if let countView = cell?.contentView.viewWithTag(10) {
            if let countLabel = countView.subviews[0] as? UILabel {
                if(items[indexPath.row].name == Localizable.shared.strings.notifications) {
                    if(AppModel.sharedManager().getUnreadNotificationsCount() > 0) {
                        countView.isHidden = false
                        countLabel.text = String(AppModel.sharedManager().getUnreadNotificationsCount())
                    }
                    else {
                        countView.isHidden = true
                    }
                }
                else {
                    countView.isHidden = true
                }
            }
        }
        
        return cell!
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        var lastSelected = String.empty()
        
        if !items[indexPath.row].selected {
            for item in items {
                if item.selected {
                    lastSelected = item.name
                }
                item.selected = false
            }
            items[indexPath.row].selected = true
            
            if lastSelected == Localizable.shared.strings.notifications {
                AppModel.sharedManager().readAllNotifications()
            }
            
            let navigationController = sideMenuController!.rootViewController as! UINavigationController
            
            switch items[indexPath.row].name {
            case Localizable.shared.strings.wallet :
                navigationController.setViewControllers([WalletViewController()], animated: false)
            case Localizable.shared.strings.notifications :
                navigationController.setViewControllers([NotificationsViewController()], animated: false)
            case Localizable.shared.strings.addresses :
                navigationController.setViewControllers([AddressesViewController()], animated: false)
            case Localizable.shared.strings.settings :
                navigationController.setViewControllers([SettingsViewController(type: .main)], animated: false)
            case Localizable.shared.strings.dAppStore :
                navigationController.setViewControllers([DAOAppsViewController()], animated: false)
            case Localizable.shared.strings.logout :
                self.confirmAlert(title: Localizable.shared.strings.logout, message: Localizable.shared.strings.logout_text, cancelTitle: Localizable.shared.strings.cancel, confirmTitle: Localizable.shared.strings.yes, cancelHandler: { (_ ) in
                    
                    var index = 0
                    for item in self.items {
                        if item.name == lastSelected {
                            item.selected = true
                            
                            self.tableView.selectRow(at: IndexPath(row: index, section: 0), animated: true, scrollPosition: .top)
                        }
                        else{
                            item.selected = false
                        }
                        index = index + 1
                    }
                    
                }) { (_) in
                    let app = UIApplication.shared.delegate as! AppDelegate
                    app.logout()
                }
                
                return
            default :
                break
            }
        }
        
        sideMenuController?.hideLeftView(animated: true, completionHandler: {
            
        })
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 60
    }
}

extension LeftMenuViewController : SettingsModelDelegate {
    func onChangeLanguage() {
        addFooterView()
        
        items = [MenuItem(name: Localizable.shared.strings.wallet, icon: IconWallet(), selected: false, type: WalletViewController.self), MenuItem(name: Localizable.shared.strings.addresses, icon: IconAddresses(), selected: false, type: AddressesViewController.self), MenuItem(name: Localizable.shared.strings.notifications, icon: IconNotifications(), selected: false, type: NotificationsViewController.self), MenuItem(name: Localizable.shared.strings.dAppStore, icon: IconDappStore(), selected: false, type: DAOAppsViewController.self), MenuItem(name: Localizable.shared.strings.settings, icon: IconSettings(), selected: true, type: SettingsViewController.self)]
        
        tableView.reloadData()
    }
    
    func onChangeDarkMode() {
        addBackgroundView()
        addFooterView()

        items = [MenuItem(name: Localizable.shared.strings.wallet, icon: IconWallet(), selected: false, type: WalletViewController.self), MenuItem(name: Localizable.shared.strings.addresses, icon: IconAddresses(), selected: false, type: AddressesViewController.self), MenuItem(name: Localizable.shared.strings.notifications, icon: IconNotifications(), selected: false, type: NotificationsViewController.self), MenuItem(name: Localizable.shared.strings.dAppStore, icon: IconDappStore(), selected: true, type: DAOAppsViewController.self), MenuItem(name: Localizable.shared.strings.settings, icon: IconSettings(), selected: false, type: SettingsViewController.self)]

        
        tableView.reloadData()
    }
}

extension LeftMenuViewController : WalletModelDelegate {
    func onNotificationsChanged() {
        DispatchQueue.main.async {
            self.tableView.reloadData()
            self.viewDidLayoutSubviews()
        }
    }
}
