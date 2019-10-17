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

class SettingsViewModel: NSObject {
    public var items = [[SettingsItem]]()
    
    public var onDataChanged: (() -> Void)?
    
    class SettingsItem {
        public var title: String?
        public var detail: String?
        public var isSwitch: Bool?
        public var id: Int!
        public var category: BMCategory?
        
        init(title: String?, detail: String?, isSwitch: Bool?, id: Int) {
            self.title = title
            self.detail = detail
            self.isSwitch = isSwitch
            self.id = id
        }
        
        init(title: String?, detail: String?, isSwitch: Bool?, id: Int, category: BMCategory?) {
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
        node.append(SettingsItem(title: Localizable.shared.strings.random_node, detail: nil, isSwitch: Settings.sharedManager().connectToRandomNode, id: 14))
        node.append(SettingsItem(title: Localizable.shared.strings.ip_port, detail: Settings.sharedManager().nodeAddress, isSwitch: nil, id: 5))
        
        var general = [SettingsItem]()
        general.append(SettingsItem(title: Localizable.shared.strings.allow_open_link, detail: nil, isSwitch: Settings.sharedManager().isAllowOpenLink, id: 9))
        general.append(SettingsItem(title: Localizable.shared.strings.lock_screen, detail: Settings.sharedManager().currentLocedValue().shortName, isSwitch: nil, id: 15))
        general.append(SettingsItem(title: Localizable.shared.strings.save_wallet_logs, detail: Settings.sharedManager().currentLogValue().name, isSwitch: nil, id: 17))
        general.append(SettingsItem(title: Localizable.shared.strings.language, detail: Settings.sharedManager().languageName(), isSwitch: nil, id: 13))
        general.append(SettingsItem(title: Localizable.shared.strings.get_beam_faucet, detail: nil, isSwitch: nil, id: 18))
        if OnboardManager.shared.isSkipedSeed() == true {
            general.append(SettingsItem(title: Localizable.shared.strings.complete_wallet_verification, detail: nil, isSwitch: nil, id: 19))
        }
        general.append(SettingsItem(title: Localizable.shared.strings.clear_local_data, detail: nil, isSwitch: nil, id: 6))
        
        var security = [SettingsItem]()
        security.append(SettingsItem(title: Localizable.shared.strings.ask_password, detail: nil, isSwitch: Settings.sharedManager().isNeedaskPasswordForSend, id: 3))
        if BiometricAuthorization.shared.canAuthenticate() {
            security.append(SettingsItem(title: BiometricAuthorization.shared.faceIDAvailable() ? Localizable.shared.strings.enable_face_id_title : Localizable.shared.strings.enable_touch_id_title, detail: nil, isSwitch: Settings.sharedManager().isEnableBiometric, id: 4))
        }
        security.append(SettingsItem(title: Localizable.shared.strings.lock_screen, detail: Settings.sharedManager().currentLocedValue().shortName, isSwitch: nil, id: 15))
        security.append(SettingsItem(title: Localizable.shared.strings.show_owner_key, detail: nil, isSwitch: nil, id: 12))
        
        if OnboardManager.shared.getSeed() != nil {
            security.append(SettingsItem(title: Localizable.shared.strings.show_seed_phrase, detail: nil, isSwitch: nil, id: 16))
        }
        
        security.append(SettingsItem(title: Localizable.shared.strings.change_password, detail: nil, isSwitch: nil, id: 1))
        
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
        
        var clear = [SettingsItem]()
        clear.append(SettingsItem(title: Localizable.shared.strings.clear_wallet, detail: nil, isSwitch: nil, id: 20))
        
        items.append(node)
        items.append(general)
        items.append(security)
        items.append(categories)
        
        if !NotificationManager.disableApns {
            var bots = [SettingsItem]()
            bots.append(SettingsItem(title: Localizable.shared.strings.open_tg_bot, detail: nil, isSwitch: nil, id: 8))
            bots.append(SettingsItem(title: Localizable.shared.strings.link_tg_bot, detail: nil, isSwitch: nil, id: 7))
            items.append(bots)
        }
        
        items.append(feedback)
        items.append(clear)
    }
    
    public func getItem(indexPath: IndexPath) -> SettingsItem {
        return items[indexPath.section][indexPath.row]
    }
}

extension SettingsViewModel: WalletModelDelegate {
    func onCategoriesChange() {
        items.removeAll()
        initItems()
        onDataChanged?()
    }
    
    func onWalletCompleteVerefication() {
        items.removeAll()
        initItems()
        onDataChanged?()
    }
}

extension SettingsViewModel {
    func showOwnerKey() {
        if let top = UIApplication.getTopMostViewController() {
            var text: String = ""
            
            if BiometricAuthorization.shared.canAuthenticate(), Settings.sharedManager().isEnableBiometric {
                if BiometricAuthorization.shared.faceIDAvailable() {
                    text = Localizable.shared.strings.show_owner_key_auth_3
                }
                else {
                    text = Localizable.shared.strings.show_owner_key_auth_2
                }
            }
            else {
                text = Localizable.shared.strings.show_owner_key_auth_1
            }
            
            top.alert(title: Localizable.shared.strings.owner_key, message: text) { _ in
                let vc = OwnerKeyUnlockViewController()
                top.pushViewController(vc: vc)
            }
        }
    }
    
    func openQRScanner(delegate: QRScannerViewControllerDelegate) {
        if let top = UIApplication.getTopMostViewController() {
            let vc = QRScannerViewController()
            vc.delegate = delegate
            vc.scanType = .tg_bot
            top.pushViewController(vc: vc)
        }
    }
    
    func openCategory(category: BMCategory?) {
        if let top = UIApplication.getTopMostViewController() {
            if category == nil {
                let vc = CategoryEditViewController(category: category)
                top.pushViewController(vc: vc)
            }
            else {
                let vc = CategoryDetailViewController(category: category!)
                top.pushViewController(vc: vc)
            }
        }
    }
    
    func onOpenTgBot() {
        let botURL = URL(string: "tg://resolve?domain=anywhere_testnet_bot")
        
        if UIApplication.shared.canOpenURL(botURL!) {
            UIApplication.shared.open(botURL!, options: [:]) { _ in }
        }
        else {
            UIApplication.shared.open(URL(string: "https://itunes.apple.com/us/app/telegram-messenger/id686449807?mt=8")!, options: [:]) { _ in }
        }
    }
    
    func onClearData() {
        if let top = UIApplication.getTopMostViewController() {
            let vc = BMDataPickerViewController(type: .clear)
            top.pushViewController(vc: vc)
        }
    }
    
    func onChangeNode(completion: @escaping ((Bool) -> Void)) {
        if let top = UIApplication.getTopMostViewController() {
            let modalViewController = UnlockPasswordPopover(event: .node)
            modalViewController.completion = { [weak self] obj in
                let vc = EnterNodeAddressViewController()
                vc.completion = { [weak self]
                    obj in
                    
                    if obj == true {
                        self?.items[0][1].detail = Settings.sharedManager().nodeAddress
                    }
                    
                    completion(obj)
                }
                top.pushViewController(vc: vc)
            }
            modalViewController.modalPresentationStyle = .overFullScreen
            modalViewController.modalTransitionStyle = .crossDissolve
            top.present(modalViewController, animated: true, completion: nil)
        }
    }
    
    func onChangePassword(controller: UIViewController) {
        if let top = UIApplication.getTopMostViewController() {
            let vc = UnlockPasswordViewController(event: .changePassword)
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
            
            vc.excludedActivityTypes = [UIActivity.ActivityType.postToFacebook, UIActivity.ActivityType.assignToContact, UIActivity.ActivityType.copyToPasteboard, UIActivity.ActivityType.print, UIActivity.ActivityType.openInIBooks]
            
            top.present(vc, animated: true)
        }
    }
    
    func onLanguage() {
        if let top = UIApplication.getTopMostViewController() {
            let vc = BMDataPickerViewController(type: .language)
            vc.completion = { [weak self] _ in
                self?.items.removeAll()
                self?.initItems()
                self?.onDataChanged?()
            }
            top.pushViewController(vc: vc)
        }
    }
    
    func onLockScreen() {
        if let top = UIApplication.getTopMostViewController() {
            let vc = BMDataPickerViewController(type: .lock)
            vc.completion = { [weak self] _ in
                self?.items.removeAll()
                self?.initItems()
                self?.onDataChanged?()
            }
            top.pushViewController(vc: vc)
        }
    }
    
    func onLogScreen() {
        if let top = UIApplication.getTopMostViewController() {
            let vc = BMDataPickerViewController(type: .log)
            vc.completion = { [weak self] _ in
                self?.items.removeAll()
                self?.initItems()
                self?.onDataChanged?()
            }
            top.pushViewController(vc: vc)
        }
    }
    
    func showSeed() {
        if let _ = OnboardManager.shared.getSeed(), let top = UIApplication.getTopMostViewController() {
            let vc = UnlockPasswordViewController(event: .seedPhrase)
            top.pushViewController(vc: vc)
        }
    }
    
    func makeSecure() {
        if let _ = OnboardManager.shared.getSeed(), let top = UIApplication.getTopMostViewController() {
            let vc = UnlockPasswordViewController(event: .seedPhrase)
            top.pushViewController(vc: vc)
        }
    }
    
    func receiveFaucet() {
        if let top = UIApplication.getTopMostViewController() {
            OnboardManager.shared.receiveFaucet { link, error in
                if let reason = error?.localizedDescription {
                    top.alert(message: reason)
                }
                else if let result = link {
                    top.openUrl(url: result)
                }
            }
        }
    }
    
    func onClearWallet() {
        if let top = UIApplication.getTopMostViewController() {
            top.confirmAlert(title: Localizable.shared.strings.clear_wallet, message: Localizable.shared.strings.clear_wallet_text, cancelTitle: Localizable.shared.strings.cancel, confirmTitle: Localizable.shared.strings.clear_wallet, cancelHandler: { (_ ) in
                
            }) { (_ ) in
                let modalViewController = UnlockPasswordPopover(event: .settings)
                modalViewController.completion = { obj in
                    let app = UIApplication.shared.delegate as! AppDelegate
                    app.logout()
                }
                modalViewController.modalPresentationStyle = .overFullScreen
                modalViewController.modalTransitionStyle = .crossDissolve
                top.present(modalViewController, animated: true, completion: nil)
            }
        }
    }
}
