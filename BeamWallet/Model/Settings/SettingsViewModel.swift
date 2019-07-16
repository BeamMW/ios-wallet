//
// SettingsViewModel.swift
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

class SettingsViewModel : NSObject {
    
    public var items = [[SettingsItem]]()
    
    public var onDataChanged : (() -> Void)?

    class SettingsItem {

        public var title:String?
        public var detail:String?
        public var isSwitch:Bool?
        public var id:Int!
        public var category:BMCategory?

        init(title: String?, detail: String?, isSwitch: Bool?, id:Int) {
            self.title = title
            self.detail = detail
            self.isSwitch = isSwitch
            self.id = id
        }
        
        init(title: String?, detail: String?, isSwitch: Bool?, id:Int, category:BMCategory?) {
            self.title = title
            self.detail = detail
            self.isSwitch = isSwitch
            self.id = id
            self.category = category
        }
    }
    
    override init() {
        super.init()
        
        initItems()
        
        AppModel.sharedManager().addDelegate(self)
    }
    
    deinit {
        AppModel.sharedManager().removeDelegate(self)
    }
    
    private func initItems() {
        var node = [SettingsItem]()
        node.append(SettingsItem(title: Localizable.shared.strings.ip_port, detail: Settings.sharedManager().nodeAddress, isSwitch: nil, id: 5))
        
        var general = [SettingsItem]()
        general.append(SettingsItem(title: Localizable.shared.strings.ask_password, detail: nil, isSwitch: Settings.sharedManager().isNeedaskPasswordForSend, id: 3))
        if BiometricAuthorization.shared.canAuthenticate() {
            general.append(SettingsItem(title: BiometricAuthorization.shared.faceIDAvailable() ? Localizable.shared.strings.enable_face_id_title : Localizable.shared.strings.enable_touch_id_title, detail: nil, isSwitch: Settings.sharedManager().isEnableBiometric, id: 4))
        }
        general.append(SettingsItem(title: Localizable.shared.strings.allow_open_link, detail: nil, isSwitch: Settings.sharedManager().isAllowOpenLink, id: 9))
        general.append(SettingsItem(title: Localizable.shared.strings.language, detail: Settings.sharedManager().languageName(), isSwitch: nil, id: 13))
        general.append(SettingsItem(title: Localizable.shared.strings.show_owner_key, detail: nil, isSwitch: nil, id: 12))
        general.append(SettingsItem(title: Localizable.shared.strings.change_wallet_password, detail: nil, isSwitch: nil, id: 1))
        general.append(SettingsItem(title: Localizable.shared.strings.clear_data, detail: nil, isSwitch: nil, id: 6))

        
        var categories = [SettingsItem]()
        if AppModel.sharedManager().categories.count > 0 {
            for category in AppModel.sharedManager().categories as! [BMCategory] {
                categories.append(SettingsItem(title: category.name, detail: nil, isSwitch: nil, id: Int(category.id), category: category))
            }
        }
        categories.append(SettingsItem(title: Localizable.shared.strings.create_new_category, detail: nil, isSwitch: nil, id: 10))


        var feedback = [SettingsItem]()
        feedback.append(SettingsItem(title: Localizable.shared.strings.rate_app, detail: nil, isSwitch: nil, id: 11))
        feedback.append(SettingsItem(title: Localizable.shared.strings.report_problem, detail: nil, isSwitch: nil, id: 2))

        items.append(node)
        items.append(general)
        items.append(categories)
        
        if !NotificationManager.disableApns {
            var bots = [SettingsItem]()
            bots.append(SettingsItem(title: Localizable.shared.strings.open_tg_bot, detail: nil, isSwitch: nil, id: 8))
            bots.append(SettingsItem(title: Localizable.shared.strings.link_tg_bot, detail: nil, isSwitch: nil, id: 7))
            items.append(bots)
        }
        
        items.append(feedback)
    }
    
    public func getItem(indexPath:IndexPath) -> SettingsItem {
        return items[indexPath.section][indexPath.row]
    }
}

extension SettingsViewModel : WalletModelDelegate {
    
    func onCategoriesChange() {
        self.items.removeAll()
        self.initItems()
        self.onDataChanged?()
    }
}

extension SettingsViewModel {
    
    func showOwnerKey() {
        if let top = UIApplication.getTopMostViewController() {
            let vc = OwnerKeyUnlockViewController()
            vc.hidesBottomBarWhenPushed = true
            top.pushViewController(vc: vc)
        }
    }
    
    func openQRScanner(delegate:QRScannerViewControllerDelegate) {
        if let top = UIApplication.getTopMostViewController() {
            let vc = QRScannerViewController()
            vc.delegate = delegate
            vc.scanType = .tg_bot
            vc.hidesBottomBarWhenPushed = true
            top.pushViewController(vc: vc)
        }
    }
    
    func openCategory(category:BMCategory?) {
        if let top = UIApplication.getTopMostViewController() {
            if category == nil {
                let vc = CategoryEditViewController(category: category)
                vc.hidesBottomBarWhenPushed = true
                top.pushViewController(vc: vc)
            }
            else{
                let vc = CategoryDetailViewController(category: category!)
                vc.hidesBottomBarWhenPushed = true
                top.pushViewController(vc: vc)
            }
        }
    }
    
    func onOpenTgBot() {
        let botURL = URL.init(string: "tg://resolve?domain=anywhere_testnet_bot")
        
        if UIApplication.shared.canOpenURL(botURL!) {
            UIApplication.shared.open(botURL!, options: [:]) { (success) in }
        }
        else {
            UIApplication.shared.open(URL(string: "https://itunes.apple.com/us/app/telegram-messenger/id686449807?mt=8")!, options: [:]) { (_ ) in }
        }
    }
    
    func onClearData() {
        if let top = UIApplication.getTopMostViewController() {
            let vc = ClearDataViewController()
            vc.hidesBottomBarWhenPushed = true
            top.pushViewController(vc: vc)
        }
    }
    
    func onChangeNode(completion: @escaping ((Bool) -> Void)){
        if let top = UIApplication.getTopMostViewController() {
            let vc = EnterNodeAddressViewController()
            vc.hidesBottomBarWhenPushed = true
            vc.completion = { [weak self]
                obj in
                
                if obj == true {
                    self?.items[0][0].detail = Settings.sharedManager().nodeAddress
                }
                
                completion(obj)
            }
            top.pushViewController(vc: vc)
        }
    }
    
    func onChangePassword(controller:UIViewController) {
        if let top = UIApplication.getTopMostViewController() {
            let vc = UnlockPasswordViewController(event: .changePassword)
            vc.hidesBottomBarWhenPushed = true
            top.pushViewController(vc: vc)
        }
    }
    
    func onClickReport() {
        if let top = UIApplication.getTopMostViewController() {
            let path = AppModel.sharedManager().getZipLogs()
            let url = URL(fileURLWithPath: path)
            
            let act = ShareLogActivity()
            act.zipUrl = url
            
            let vc = UIActivityViewController(activityItems: [url], applicationActivities: [act])
            vc.setValue("beam wallet logs", forKey: "subject")

            vc.excludedActivityTypes = [UIActivity.ActivityType.postToFacebook, UIActivity.ActivityType.assignToContact, UIActivity.ActivityType.copyToPasteboard, UIActivity.ActivityType.print,UIActivity.ActivityType.openInIBooks]
            
            top.present(vc, animated: true)
        }
    }
    
    func onLanguage() {
        if let top = UIApplication.getTopMostViewController() {
            let vc = LanguagePickerViewController()
            vc.completion = {[weak self] obj in
                self?.items.removeAll()
                self?.initItems()
                self?.onDataChanged?()
            }
            vc.hidesBottomBarWhenPushed = true
            top.pushViewController(vc: vc)
        }
    }
}