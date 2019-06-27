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

    private let enableBuy = false
    
    private var topView:UIView!

    private var buyButton:UIButton!
    
    private var items = [MenuItem(name: Localizable.shared.strings.wallet, icon: IconWallet(), selected: true, type: WalletViewController.self), MenuItem(name: Localizable.shared.strings.addresses, icon: IconAddresses(), selected: false, type: AddressesViewController.self), MenuItem(name: Localizable.shared.strings.utxo, icon: IconUtxo(), selected: false, type: UTXOViewController.self), MenuItem(name: Localizable.shared.strings.settings, icon: IconSettings(), selected: false, type: SettingsViewController.self)]
    //MenuItem(name: Localizable.shared.strings.logout, icon: IconLogout(), selected: false, type: AnyClass.self)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = UIColor.main.navy
        
        Settings.sharedManager().addDelegate(self)
        
        tableView.backgroundColor = UIColor.main.navy
        tableView.delegate = self
        tableView.dataSource = self
        tableView.tableHeaderView = UIView(frame: CGRect(x: 0, y: 0, width: 0, height: 66))
        
        topView = UIView(frame: CGRect(x: 0, y: 0, width: self.view.bounds.width, height: 20))
        topView.backgroundColor = UIColor.black.withAlphaComponent(0.3)
        
        if Device.screenType == .iPhones_5 || Device.screenType == .iPhones_6 || Device.screenType == .iPhones_Plus {
            tableView.tableHeaderView = UIView(frame: CGRect(x: 0, y: 0, width: 0, height: 33))
        }
        
        addFooterView()
    }
    
    private func addFooterView() {
        if buyButton != nil {
            buyButton.removeFromSuperview()
            buyButton = nil
        }
        
        let titleParagraphStyle = NSMutableParagraphStyle()
        titleParagraphStyle.alignment = .left
        
        let imageAttachment = NSTextAttachment()
        imageAttachment.image = IconExternalLinkGray()?.maskWithColor(color: UIColor.main.steelGrey)
        let imageString = NSAttributedString(attachment: imageAttachment)
        
        let attributedString = NSMutableAttributedString(string:Localizable.shared.strings.where_buy_beam)
        attributedString.addAttributes([NSAttributedString.Key.paragraphStyle : titleParagraphStyle], range:  NSRange(location: 0, length: Localizable.shared.strings.where_buy_beam.count))
        attributedString.addAttributes([NSAttributedString.Key.foregroundColor : UIColor.main.brightTeal.withAlphaComponent(0.5)], range:  NSRange(location: 0, length:Localizable.shared.strings.where_buy_beam.count))
        attributedString.append(NSAttributedString(string: "  "))
        attributedString.append(imageString)
        
        let highlightedAttributedString = NSMutableAttributedString(attributedString: attributedString)
        highlightedAttributedString.addAttributes([NSAttributedString.Key.foregroundColor : UIColor.main.brightTeal.withAlphaComponent(0.2)], range:  NSRange(location: 0, length: Localizable.shared.strings.where_buy_beam.count))
        
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
       
        tableView.frame = self.view.bounds
        
        topView.frame = CGRect(x: 0, y: 0, width: self.view.bounds.width, height: 20)

        let offset:CGFloat = (Device.screenType == .iPhone_XR || Device.screenType == .iPhone_XSMax || Device.screenType == .iPhones_X_XS) ? 40 : 15
        buyButton.frame = CGRect(x: 0, y: self.view.bounds.size.height-50-offset, width: self.view.bounds.size.width, height: 50)
        

        for item in self.items {
            item.selected = false
        }
        
        let navigationController = sideMenuController!.rootViewController as! UINavigationController

        if navigationController.viewControllers.first is WalletViewController{
            items[0].selected = true
            self.tableView.selectRow(at: IndexPath(row: 0, section: 0), animated: false, scrollPosition: .top)
        }
        else if navigationController.viewControllers.first is AddressesViewController{
            items[1].selected = true
            self.tableView.selectRow(at: IndexPath(row: 1, section: 0), animated: false, scrollPosition: .top)
        }
        else if navigationController.viewControllers.first is UTXOViewController{
            items[2].selected = true
            self.tableView.selectRow(at: IndexPath(row: 2, section: 0), animated: false, scrollPosition: .top)
        }
        else if navigationController.viewControllers.first is SettingsViewController{
            items[3].selected = true
            self.tableView.selectRow(at: IndexPath(row: 3, section: 0), animated: false, scrollPosition: .top)
        }
    }
    
    @objc private func onBuy() {
        if enableBuy {
            for item in self.items {
                item.selected = false
            }
            
            let navigationController = sideMenuController!.rootViewController as! UINavigationController
            navigationController.setViewControllers([BuyBeamViewController()], animated: false)
            sideMenuController?.hideLeftView(animated: true, completionHandler: {
                self.tableView.reloadData()
            })
        }
        else{
            self.openUrl(url: URL(string: Settings.sharedManager().whereBuyAddress)!)
        }
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
            cell?.textLabel?.textColor = UIColor.main.steelGrey
            cell?.textLabel?.font = RegularFont(size: 17)

            let selectedBackgroundView = UIImageView(frame: CGRect(x: 0, y: 0, width: UIScreen.main.bounds.size.width, height: 60))
            selectedBackgroundView.image = MenuSelectedBackground();
            cell?.selectedBackgroundView = selectedBackgroundView
        }
        
        cell?.textLabel?.text = items[indexPath.row].name
        cell?.imageView?.image = items[indexPath.row].icon?.maskWithColor(color: UIColor.main.steelGrey)
        cell?.imageView?.highlightedImage = items[indexPath.row].icon?.maskWithColor(color: UIColor.main.brightTeal)

        
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
            
            let navigationController = sideMenuController!.rootViewController as! UINavigationController
            
            switch items[indexPath.row].name {
            case Localizable.shared.strings.wallet :
                navigationController.setViewControllers([WalletViewController()], animated: false)
            case Localizable.shared.strings.utxo :
                navigationController.setViewControllers([UTXOViewController()], animated: false)
            case Localizable.shared.strings.addresses :
                navigationController.setViewControllers([AddressesViewController()], animated: false)
            case Localizable.shared.strings.settings :
                navigationController.setViewControllers([SettingsViewController()], animated: false)
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
        
        items = [MenuItem(name: Localizable.shared.strings.wallet, icon: IconWallet(), selected: true, type: WalletViewController.self), MenuItem(name: Localizable.shared.strings.addresses, icon: IconAddresses(), selected: false, type: AddressesViewController.self), MenuItem(name: Localizable.shared.strings.utxo, icon: IconUtxo(), selected: false, type: UTXOViewController.self), MenuItem(name: Localizable.shared.strings.settings, icon: IconSettings(), selected: false, type: SettingsViewController.self)]
        
        tableView.reloadData()
    }
}

