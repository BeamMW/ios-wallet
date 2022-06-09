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
import SafariServices

class MenuCell: UITableViewCell {
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        self.textLabel?.x = 60
    }
}

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
    
    private var logoView:UIImageView!
    
    //    private var sections_0 = [
    //        MenuItem(name: Localizable.shared.strings.wallet, icon: IconWallet(), selected:               true, type: WalletViewController.self),
    //        MenuItem(name: Localizable.shared.strings.beamx_dao, icon: IconBeamXDAO(), selected: false, type: DAOViewController.self),
    //        MenuItem(name: Localizable.shared.strings.beam_faucet, icon: IconBeamFaucet(), selected: false, type: DAOViewController.self),
    //        MenuItem(name: Localizable.shared.strings.beam_gallery, icon: IconBeamGallery(), selected: false, type: DAOViewController.self)]
    
    private var sections_0 = [
        MenuItem(name: Localizable.shared.strings.wallet, icon: IconWallet(), selected:               true, type: WalletViewController.self),
        MenuItem(name: Localizable.shared.strings.dAppStore, icon: IconDappStore(), selected: false, type: DAOViewController.self),
        MenuItem(name: Localizable.shared.strings.beamx_dao, icon: IconBeamXDAO(), selected: false, type: DAOViewController.self),
        MenuItem(name: Localizable.shared.strings.beamx_dao_dao_voting, icon: IconBeamXDAOVoting(), selected: false, type: DAOViewController.self)]
    
    private var sections_1 = [
        MenuItem(name: Localizable.shared.strings.addresses, icon: IconAddresses(), selected: false, type: AddressesViewController.self),
        MenuItem(name: Localizable.shared.strings.notifications, icon: IconNotifications(), selected: false, type: NotificationsViewController.self),
        MenuItem(name: Localizable.shared.strings.documentation, icon: IconHelp(), selected: false, type: SettingsViewController.self),
        MenuItem(name: Localizable.shared.strings.settings, icon: IconSettings(), selected: false, type: SettingsViewController.self)
    ]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        Settings.sharedManager().addDelegate(self)
        AppModel.sharedManager().addDelegate(self)
        
        tableView.delegate = self
        tableView.dataSource = self
        
        var height:CGFloat = 180
        var offset:CGFloat = 20
        if Device.screenType == .iPhones_5 || Device.screenType == .iPhones_6  {
            height = 150
        }
        else if Device.isXDevice {
            height = 200
            offset = 35
        }
        
        let header = UIView(frame: CGRect(x: 0, y: 0, width: UIScreen.main.bounds.size.width, height: height))
        logoView = UIImageView(frame: CGRect(x: 0, y: height-110-offset, width: 110, height: 110))
        logoView.image = UIImage(named: "logoNew")
        header.addSubview(logoView)
        
        tableView.tableHeaderView = header
        
        addBackgroundView()
        
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
    
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        logoView.x = (self.view.bounds.width - 110)/2
        tableView.frame = self.view.bounds
        
        tableView.reloadData()
    }
}

extension LeftMenuViewController: UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let view = UIView()
        view.backgroundColor = .clear
        return view
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        if section == 1 {
            let height_0 = CGFloat(sections_0.count * 60)
            let height_1 = CGFloat(sections_1.count * 60)
            let header = tableView.tableHeaderView?.frame.size.height ?? 0
            var mainHeight = UIScreen.main.bounds.size.height - height_0 - height_1 - header
            if Device.isXDevice {
                mainHeight = mainHeight - 70
            }
            else {
                mainHeight = mainHeight - 20
            }
            return mainHeight
        }
        
        return 0
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            return sections_0.count
        }
        return sections_1.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var cell = tableView.dequeueReusableCell(withIdentifier: "MenuCell")
        
        if(cell == nil) {
            cell = MenuCell(style: .default, reuseIdentifier: "MenuCell")
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
        
        let item = indexPath.section == 0 ? sections_0[indexPath.row] : sections_1[indexPath.row]
        
        cell?.textLabel?.textColor = Settings.sharedManager().isDarkMode ? UIColor.main.steel : UIColor.main.steelGrey
        cell?.textLabel?.text = item.name
        cell?.imageView?.image = item.icon?.maskWithColor(color: Settings.sharedManager().isDarkMode ? UIColor.main.steel : UIColor.main.steelGrey)
        cell?.imageView?.highlightedImage = item.icon?.maskWithColor(color: UIColor.main.brightTeal)
        
        
        let selectedBackgroundView = UIImageView(frame: CGRect(x: 0, y: 0, width: UIScreen.main.bounds.size.width, height: 60))
        selectedBackgroundView.image = MenuSelectedBackground();
        selectedBackgroundView.tag = 12
        
        let selectedBackgroundView1 = UIImageView(frame: CGRect(x: 0, y: 0, width: UIScreen.main.bounds.size.width, height: 60))
        selectedBackgroundView1.image = MenuSelectedBackground();
        
        
        cell?.contentView.viewWithTag(12)?.removeFromSuperview()
        
        if item.selected {
            cell?.imageView?.isHighlighted = true
            cell?.textLabel?.isHighlighted = true
            cell?.contentView.addSubview(selectedBackgroundView)
        }
        
        cell?.selectedBackgroundView = selectedBackgroundView1
        
        
        if let countView = cell?.contentView.viewWithTag(10) {
            if let countLabel = countView.subviews[0] as? UILabel {
                if(item.name == Localizable.shared.strings.notifications) {
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
        tableView.deselectRow(at: indexPath, animated: true)
        
        let item = indexPath.section == 0 ? sections_0[indexPath.row] : sections_1[indexPath.row]
        
        if item.name == Localizable.shared.strings.documentation {
            let url = URL(string: Settings.sharedManager().documentationAddress)
            if let url = url, let top = UIApplication.getTopMostViewController() {
                top.openUrl(url: url, additionalInfo: nil, infoDelay: 0)
            }
        }
        else {
            if !item.selected {
                AppModel.sharedManager().stopDAO()
                
                for _item in self.sections_0 {
                    _item.selected = false
                }
                
                for _item in self.sections_1 {
                    _item.selected = false
                }
                
                if indexPath.section == 0 {
                    sections_0[indexPath.row].selected = true
                }
                else if indexPath.section == 1 {
                    sections_1[indexPath.row].selected = true
                }
                
                if item.name == Localizable.shared.strings.notifications {
                    AppModel.sharedManager().readAllNotifications()
                }
                
                let navigationController = sideMenuController!.rootViewController as! UINavigationController
                
                switch item.name {
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
                case Localizable.shared.strings.beam_faucet :
                    AppModel.sharedManager().startBeamXDaoApp(navigationController, app: AppModel.sharedManager().daoFaucetApp())
                case Localizable.shared.strings.beam_gallery :
                    AppModel.sharedManager().startBeamXDaoApp(navigationController, app: AppModel.sharedManager().daoGalleryApp())
                case Localizable.shared.strings.beamx_dao:
                    AppModel.sharedManager().startBeamXDaoApp(navigationController, app: AppModel.sharedManager().daoBeamXApp())
                case Localizable.shared.strings.beamx_dao_dao_voting:
                    AppModel.sharedManager().startBeamXDaoApp(navigationController, app: AppModel.sharedManager().votingApp())
                default :
                    break
                }
            }
        }
        
        sideMenuController?.hideLeftView(animated: true, completionHandler: {
            
        })
        
        tableView.reloadData()
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 60
    }
    
}

extension LeftMenuViewController : SettingsModelDelegate {
    
    func onChangeLanguage() {
        onChangeDarkMode()
    }
    
    func onChangeDarkMode() {
        addBackgroundView()
        
        sections_0 = [MenuItem(name: Localizable.shared.strings.wallet, icon: IconWallet(), selected: true, type: WalletViewController.self),
                      MenuItem(name: Localizable.shared.strings.dAppStore, icon: IconDappStore(), selected: false, type: DAOViewController.self),
                      MenuItem(name: Localizable.shared.strings.beamx_dao, icon: IconBeamXDAO(), selected: false, type: DAOViewController.self),
                      MenuItem(name: Localizable.shared.strings.beamx_dao_dao_voting, icon: IconBeamXDAOVoting(), selected: false, type: DAOViewController.self)]
        
        sections_1 = [
            MenuItem(name: Localizable.shared.strings.addresses, icon: IconAddresses(), selected: false, type: AddressesViewController.self),
            MenuItem(name: Localizable.shared.strings.notifications, icon: IconNotifications(), selected: false, type: NotificationsViewController.self),
            MenuItem(name: Localizable.shared.strings.documentation, icon: IconHelp(), selected: false, type: SettingsViewController.self),
            MenuItem(name: Localizable.shared.strings.settings, icon: IconSettings(), selected: true, type: SettingsViewController.self)
        ]
        
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


