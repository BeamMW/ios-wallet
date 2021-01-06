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
import MobileCoreServices

class SettingsViewModel: NSObject {
    public enum SettingsType: Int {
        case main = 0
        case general = 1
        case node = 2
        case privacy = 3
        case tags = 4
        case utilites = 5
        case notifications = 6
    }
    
    enum SettingsItemType: Int {
        case general = 1
        case node = 2
        case privacy = 3
        case tags = 4
        case utilites = 5
        case rate_app = 6
        case report_problem = 7
        case remove_wallet = 8
        case allow_open_link = 9
        case lock_screen = 10
        case save_logs = 11
        case clear_data = 12
        case language = 13
        case dark_mode = 14
        case ask_password = 15
        case enable_bio = 16
        case ip_port = 17
        case show_owner_key = 18
        case show_seed = 19
        case change_password = 20
        case faucet = 21
        case payment_proof = 22
        case verification = 23
        case export = 24
        case imprt = 25
        case create_category = 26
        case open_category = 27
        case random_node = 28
        case currency = 29
        case notifications = 30
        case offline_address = 31
        case max_privacy_limit = 32
        case rescan = 33
    }
    
    class SettingsItem {
        public var title: String?
        public var detail: String?
        public var isSwitch: Bool?
        public var type: SettingsItemType!
        public var category: BMCategory?
        public var icon: UIImage?
        public var hasArrow: Bool!
        public var id: Int?
        
        init(title: String?, type: SettingsItemType, icon: UIImage?, hasArrow: Bool) {
            self.title = title
            self.type = type
            self.icon = icon
            self.hasArrow = hasArrow
        }
        
        init(title: String?, detail: String?, isSwitch: Bool?, type: SettingsItemType, hasArrow: Bool) {
            self.title = title
            self.detail = detail
            self.isSwitch = isSwitch
            self.type = type
            self.hasArrow = hasArrow
        }
        
        init(title: String?, detail: String?, isSwitch: Bool?, type: SettingsItemType, category: BMCategory?, hasArrow: Bool) {
            self.title = title
            self.detail = detail
            self.isSwitch = isSwitch
            self.type = type
            self.category = category
            self.hasArrow = hasArrow
        }
    }
    
    private var type: SettingsType!
    
    public var items = [[SettingsItem]]()
    public var onDataChanged: (() -> Void)?
    
    init(type: SettingsType) {
        super.init()
        
        self.type = type
        
        initItems()
        
        AppModel.sharedManager().addDelegate(self)
    }
    
    deinit {
        AppModel.sharedManager().removeDelegate(self)
    }
    
    private func initItems() {
        switch type {
        case .main:
            var section_0 = [SettingsItem]()
            section_0.append(SettingsItem(title: Localizable.shared.strings.general_settings.capitalizingFirstLetter(), type: SettingsItemType.general, icon: IconSettingsGeneral(), hasArrow: true))
            section_0.append(SettingsItem(title: Localizable.shared.strings.notifications.capitalizingFirstLetter(), type: SettingsItemType.notifications, icon: IconNotifications(), hasArrow: true))
            section_0.append(SettingsItem(title: Localizable.shared.strings.node.capitalizingFirstLetter(), type: SettingsItemType.node, icon: IconNode(), hasArrow: true))
            section_0.append(SettingsItem(title: Localizable.shared.strings.privacy.capitalizingFirstLetter(), type: SettingsItemType.privacy, icon: IconSettingsPrivacy(), hasArrow: true))
            section_0.append(SettingsItem(title: Localizable.shared.strings.utilities.capitalizingFirstLetter(), type: SettingsItemType.utilites, icon: IconSettingsUtilities(), hasArrow: true))
            
            var section_1 = [SettingsItem]()
            section_1.append(SettingsItem(title: Localizable.shared.strings.categories.capitalizingFirstLetter(), type: SettingsItemType.tags, icon: IconSettingsTags(), hasArrow: true))
            
            var section_2 = [SettingsItem]()
            section_2.append(SettingsItem(title: Localizable.shared.strings.rate_app.capitalizingFirstLetter(), type: SettingsItemType.rate_app, icon: IconSettingsRate(), hasArrow: false))
            section_2.append(SettingsItem(title: Localizable.shared.strings.report_problem.capitalizingFirstLetter(), type: SettingsItemType.report_problem, icon: IconSettingsReport(), hasArrow: false))
            
            var section_3 = [SettingsItem]()
            section_3.append(SettingsItem(title: Localizable.shared.strings.clear_wallet.capitalizingFirstLetter(), type: SettingsItemType.remove_wallet, icon: IconSettingsRemove(), hasArrow: false))
            
            items.append(section_0)
            items.append(section_1)
            items.append(section_2)
            items.append(section_3)
        case .general:
            var section_0 = [SettingsItem]()
            section_0.append(SettingsItem(title: Localizable.shared.strings.allow_open_link, detail: nil, isSwitch: Settings.sharedManager().isAllowOpenLink, type: .allow_open_link, hasArrow: false))
            section_0.append(SettingsItem(title: Localizable.shared.strings.lock_screen, detail: Settings.sharedManager().currentLocedValue().shortName, isSwitch: nil, type: .lock_screen, hasArrow: true))
         //   section_0.append(SettingsItem(title: Localizable.shared.strings.save_wallet_logs, detail: Settings.sharedManager().currentLogValue().name, isSwitch: nil, type: .save_logs, hasArrow: true))
            section_0.append(SettingsItem(title: Localizable.shared.strings.show_amounts_in, detail: Settings.sharedManager().currencyName(), isSwitch: nil, type: .currency, hasArrow: true))
            section_0.append(SettingsItem(title: Localizable.shared.strings.clear_local_data, detail: nil, isSwitch: nil, type: .clear_data, hasArrow: true))
            
            var section_1 = [SettingsItem]()
            section_1.append(SettingsItem(title: Localizable.shared.strings.language, detail: Settings.sharedManager().languageName(), isSwitch: nil, type: .language, hasArrow: true))
            section_1.append(SettingsItem(title: Localizable.shared.strings.dark_mode, detail: nil, isSwitch: Settings.sharedManager().isDarkMode, type: .dark_mode, hasArrow: false))
            items.append(section_0)
            items.append(section_1)
        case .node:
            var section_0 = [SettingsItem]()
            section_0.append(SettingsItem(title: Localizable.shared.strings.random_node, detail: nil, isSwitch: Settings.sharedManager().connectToRandomNode, type: .random_node, hasArrow: false))
            section_0.append(SettingsItem(title: Localizable.shared.strings.ip_port, detail: Settings.sharedManager().nodeAddress, isSwitch: nil, type: .ip_port, hasArrow: true))
            items.append(section_0)
        case .privacy:
            var section_0 = [SettingsItem]()
            section_0.append(SettingsItem(title: Localizable.shared.strings.ask_password, detail: nil, isSwitch: Settings.sharedManager().isNeedaskPasswordForSend, type: .ask_password, hasArrow: false))
            if BiometricAuthorization.shared.canAuthenticate() {
                section_0.append(SettingsItem(title: BiometricAuthorization.shared.faceIDAvailable() ? Localizable.shared.strings.enable_face_id_title : Localizable.shared.strings.enable_touch_id_title, detail: nil, isSwitch: Settings.sharedManager().isEnableBiometric, type: .enable_bio, hasArrow: false))
            }
            section_0.append(SettingsItem(title: Localizable.shared.strings.max_privacy_lock_time, detail: Settings.sharedManager().currentMaxPrivacyLockValue().name, isSwitch: nil, type: .max_privacy_limit, hasArrow: true))

            
            if OnboardManager.shared.isSkipedSeed() == true {
                section_0.append(SettingsItem(title: Localizable.shared.strings.complete_seed_verification, detail: nil, isSwitch: nil, type: .verification, hasArrow: true))
            }
            section_0.append(SettingsItem(title: Localizable.shared.strings.show_owner_key, detail: nil, isSwitch: nil, type: .show_owner_key, hasArrow: true))
            //            if OnboardManager.shared.isSkipedSeed() == true {
            //                section_0.append(SettingsItem(title: Localizable.shared.strings.show_seed_phrase, detail: nil, isSwitch: nil, type: .show_seed, hasArrow: true))
            //            }
            section_0.append(SettingsItem(title: Localizable.shared.strings.change_password, detail: nil, isSwitch: nil, type: .change_password, hasArrow: true))
            items.append(section_0)
        case .utilites:
            var section_0 = [SettingsItem]()
            section_0.append(SettingsItem(title: Localizable.shared.strings.show_public_offline, detail: nil, isSwitch: nil, type: .offline_address, hasArrow: false))
            section_0.append(SettingsItem(title: Localizable.shared.strings.get_beam_faucet, detail: nil, isSwitch: nil, type: .faucet, hasArrow: false))
            section_0.append(SettingsItem(title: Localizable.shared.strings.rescan, detail: nil, isSwitch: nil, type: .rescan, hasArrow: false))
            section_0.append(SettingsItem(title: Localizable.shared.strings.payment_proof, detail: nil, isSwitch: nil, type: .payment_proof, hasArrow: true))
            section_0.append(SettingsItem(title: Localizable.shared.strings.export_wallet_data, detail: nil, isSwitch: nil, type: .export, hasArrow: true))
            section_0.append(SettingsItem(title: Localizable.shared.strings.import_wallet_data, detail: nil, isSwitch: nil, type: .imprt, hasArrow: true))
            items.append(section_0)
        case .tags:
            var categories = [SettingsItem]()
            if AppModel.sharedManager().categories.count > 0 {
                let sorted = AppModel.sharedManager().sortedCategories()
                
                for category in sorted as! [BMCategory] {
                    categories.append(SettingsItem(title: category.name, detail: nil, isSwitch: nil, type: .open_category, category: category, hasArrow: true))
                }
            }
            if categories.count > 0 {
                items.append(categories)
            }
            var section_1 = [SettingsItem]()
            section_1.append(SettingsItem(title: Localizable.shared.strings.create_new_category, detail: nil, isSwitch: nil, type: .create_category, hasArrow: false))
            items.append(section_1)
        default:
            break
        }
    }
    
    public func title() -> String {
        switch type {
        case .main:
            return Localizable.shared.strings.settings
        case .general:
            return Localizable.shared.strings.general_settings
        case .node:
            return Localizable.shared.strings.node
        case .privacy:
            return Localizable.shared.strings.privacy
        case .utilites:
            return Localizable.shared.strings.utilities
        case .tags:
            return Localizable.shared.strings.categories
        case .notifications:
            return Localizable.shared.strings.notifications
        case .none:
            return String.empty()
        }
    }
    
    public func reload() {
        items.removeAll()
        initItems()
    }
    
    public func getItem(indexPath: IndexPath) -> SettingsItem {
        return items[indexPath.section][indexPath.row]
    }
    
    public func didSelectItem(item: SettingsItem) {
        switch item.type {
        case .general, .node, .privacy, .tags, .utilites:
            if let top = UIApplication.getTopMostViewController() {
                let vc = SettingsViewController(type: SettingsType(rawValue: item.type.rawValue)!)
                top.pushViewController(vc: vc)
            }
        case .rate_app:
            if let top = UIApplication.getTopMostViewController() as? BaseViewController {
                top.showRateDialog()
            }
        case .report_problem:
            onClickReport()
        case .remove_wallet:
            onClearWallet()
        case .clear_data:
            onClearData()
        case .lock_screen:
            onLockScreen()
        case .save_logs:
            onLogScreen()
        case .language:
            onLanguage()
        case .ip_port:
            onChangeNode()
        case .show_owner_key:
            showOwnerKey()
        case .change_password:
            onChangePassword()
        case .show_seed:
            showSeed()
        case .faucet:
            receiveFaucet()
        case .payment_proof:
            onPaymentProof()
        case .verification:
            makeSecure()
        case .export:
            onExportWallet()
        case .imprt:
            onImportWallet()
        case .create_category:
            openCategory(category: nil)
        case .open_category:
            openCategory(category: item.category)
        case .currency:
            onCurrencyScreen()
        case .notifications:
            onNotifications()
        case .offline_address:
            onOfflineAddress()
        case .max_privacy_limit:
            onLockLimit()
        case .rescan:
            onRescan()
            break
        default:
            return
        }
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
                let vc = BMDoubleAuthViewController(event: .owner)
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
    
    func onLockLimit() {
        if let top = UIApplication.getTopMostViewController() {
            let vc = BMDataPickerViewController(type: .max_privacy_lock)
            vc.completion = { [weak self]
                _ in
                self?.items.removeAll()
                self?.initItems()
                self?.onDataChanged?()
            }
            top.pushViewController(vc: vc)
        }
    }
    
    func onRescan() {
        if let top = UIApplication.getTopMostViewController() {
            top.confirmAlert(title: Localizable.shared.strings.rescan, message: Localizable.shared.strings.rescan_text, cancelTitle: Localizable.shared.strings.cancel, confirmTitle: Localizable.shared.strings.rescan, cancelHandler: { _ in
                
            }) { _ in
                AppModel.sharedManager().rescan()
            }
        }
    }
    
    func onChangeNode() {
        if let top = UIApplication.getTopMostViewController() {
            let modalViewController = UnlockPasswordPopover(event: .node)
            modalViewController.completion = { [weak self] obj in
                if obj {
                    let vc = TrustedNodeViewController(event: .change)
                    vc.completion = { [weak self]
                        obj in
                        if obj == true {
                            self?.items[0][1].detail = Settings.sharedManager().nodeAddress
                        }
                        self?.onDataChanged?()
                    }
                    top.pushViewController(vc: vc)
                }
            }
            modalViewController.modalPresentationStyle = .overFullScreen
            modalViewController.modalTransitionStyle = .crossDissolve
            top.present(modalViewController, animated: true, completion: nil)
        }
    }
    
    func onChangePassword() {
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
            top.pushViewController(vc: vc)
        }
    }
    
    func onNotifications() {
        if let top = UIApplication.getTopMostViewController() {
            let vc = BMDataPickerViewController(type: .notifications)
            top.pushViewController(vc: vc)
        }
    }
    
    func onOfflineAddress() {
        let isOwn = AppModel.sharedManager().checkIsOwnNode()
        if isOwn {
            if let top = UIApplication.getTopMostViewController() {
                let vc = OfflineAddressViewController()
                top.pushViewController(vc: vc)
            }
        }
        else {
            if let top = UIApplication.getTopMostViewController() {
                top.alert(title: Localizable.shared.strings.show_public_offline, message: Localizable.shared.strings.connect_node_offline_public, handler: nil)
            }
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
    
    func onCurrencyScreen() {
        if let top = UIApplication.getTopMostViewController() {
            let vc = BMDataPickerViewController(type: .currency)
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
            let vc = BMDoubleAuthViewController(event: .seed)
            top.pushViewController(vc: vc)
        }
    }
    
    func makeSecure() {
        if let _ = OnboardManager.shared.getSeed(), let top = UIApplication.getTopMostViewController() {
            let vc = BMDoubleAuthViewController(event: .verification)
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
                    if Settings.sharedManager().isAllowOpenLink {
                        BMOverlayTimerView.show(text: Localizable.shared.strings.faucet_redirect_text, link: result)
                    }
                    else {
                        top.confirmAlert(title: Localizable.shared.strings.external_link_title, message: Localizable.shared.strings.external_link_text, cancelTitle: Localizable.shared.strings.cancel, confirmTitle: Localizable.shared.strings.open, cancelHandler: { _ in
                            
                        }) { _ in
                            BMOverlayTimerView.show(text: Localizable.shared.strings.faucet_redirect_text, link: result)
                        }
                    }
                }
            }
        }
    }
    
    func onClearWallet() {
        if let top = UIApplication.getTopMostViewController() {
            if AppModel.sharedManager().hasActiveTransactions() {
                top.alert(title: Localizable.shared.strings.clear_wallet, message: Localizable.shared.strings.clear_wallet_transactions_text, handler: nil)
            }
            else {
                top.confirmAlert(title: Localizable.shared.strings.clear_wallet, message: Localizable.shared.strings.clear_wallet_text, cancelTitle: Localizable.shared.strings.cancel, confirmTitle: Localizable.shared.strings.remove_wallet, cancelHandler: { _ in
                    
                }) { _ in
                    let modalViewController = UnlockPasswordPopover(event: .clear_wallet, allowBiometric: false)
                    modalViewController.completion = { obj in
                        if obj {
                            let app = UIApplication.shared.delegate as! AppDelegate
                            app.logout()
                        }
                    }
                    modalViewController.modalPresentationStyle = .overFullScreen
                    modalViewController.modalTransitionStyle = .crossDissolve
                    top.present(modalViewController, animated: true, completion: nil)
                }
            }
        }
    }
    
    func onPaymentProof() {
        if let top = UIApplication.getTopMostViewController() {
            let vc = PaymentProofDetailViewController(transaction: nil, paymentProof: nil)
            top.pushViewController(vc: vc)
        }
    }
    
    func onExportWallet() {
        if let top = UIApplication.getTopMostViewController() {
            let vc = BMDataPickerViewController(type: .export_data)
            top.pushViewController(vc: vc)
        }
    }
    
    func onImportWallet() {
        if let top = UIApplication.getTopMostViewController() {
            top.alert(title: Localizable.shared.strings.import_data_title, message: Localizable.shared.strings.import_data_text_2) { _ in
                let types = ["com.giena.Interface.document.dat"]
                let importMenu = UIDocumentPickerViewController(documentTypes: types as [String], in: .import)
                importMenu.delegate = self
                importMenu.modalPresentationStyle = .formSheet
                importMenu.view.tintColor = UIColor.main.marine
                top.present(importMenu, animated: true, completion: {
                    importMenu.view.tintColor = UIColor.main.marine
                })
            }
        }
    }
}

extension SettingsViewModel: UIDocumentPickerDelegate, UINavigationControllerDelegate {
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        if let topVC = UIApplication.getTopMostViewController() {
            topVC.confirmAlert(title: Localizable.shared.strings.import_data_title, message: Localizable.shared.strings.import_data_text, cancelTitle: Localizable.shared.strings.cancel, confirmTitle: Localizable.shared.strings.imprt, cancelHandler: { _ in
                
            }) { _ in
                if let url = urls.first {
                    do {
                        let data = try String(contentsOf: url)
                        let result = AppModel.sharedManager().importData(data)
                        if !result {
                            topVC.alert(title: Localizable.shared.strings.incorrect_file_title, message: Localizable.shared.strings.incorrect_file_text, handler: nil)
                        }
                        else {
                            self.items.removeAll()
                            self.initItems()
                            self.onDataChanged?()
                        }
                    }
                    catch {
                        topVC.alert(title: Localizable.shared.strings.incorrect_file_title, message: Localizable.shared.strings.incorrect_file_text, handler: nil)
                    }
                }
            }
        }
    }
    
    func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
        controller.dismiss(animated: true, completion: nil)
    }
}

