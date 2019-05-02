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

protocol SettingsActions {
    func onClickReport(controller:UIViewController)
    func onChangePassword(controller:UIViewController)
    func onChangeNode(controller:UIViewController, completion: @escaping ((Bool) -> Void))
    func onClearData(controller:UIViewController)
    func onSwitch(controller:UIViewController, indexPath:IndexPath)
    func onOpenTgBot()
    
}
extension SettingsViewModel: SettingsActions {
    
    func onOpenTgBot() {
        let botURL = URL.init(string: "tg://resolve?domain=anywhere_testnet_bot")

        if UIApplication.shared.canOpenURL(botURL!) {
            UIApplication.shared.open(botURL!, options: [:]) { (success) in
                print(success)
            }
        }
        else {
            UIApplication.shared.open(URL(string: "https://itunes.apple.com/us/app/telegram-messenger/id686449807?mt=8")!, options: [:]) { (_ ) in

            }
        }
    }

    
    func onSwitch(controller:UIViewController, indexPath:IndexPath) {
        
    }
    
    func onClearData(controller:UIViewController) {
        
        let vc = ClearDataViewController()
        vc.hidesBottomBarWhenPushed = true
        controller.pushViewController(vc: vc)
    }
    
    func onChangeNode(controller:UIViewController, completion: @escaping ((Bool) -> Void)){
        
        let vc = EnterNodeAddressViewController()
        vc.hidesBottomBarWhenPushed = true
        vc.completion = {
            obj in
            
            if obj == true {
                self.items[0][0].detail = Settings.sharedManager().nodeAddress
            }
            
            completion(obj)
        }
        controller.pushViewController(vc: vc)
    }
    
    func onChangePassword(controller:UIViewController) {
        
        let vc = UnlockPasswordViewController(event: .changePassword)
        vc.hidesBottomBarWhenPushed = true
        controller.pushViewController(vc: vc)
    }
    
    func onClickReport(controller:UIViewController) {
        
        let path = AppModel.sharedManager().getZipLogs()
        let url = URL(fileURLWithPath: path)
        
        let act = ShareLogActivity()
        act.zipUrl = url
        
        let vc = UIActivityViewController(activityItems: [url], applicationActivities: [act])
        
        if (Settings.sharedManager().target == Testnet) {
            vc.setValue("beam wallet testnet logs", forKey: "subject")
        }
        else{
            vc.setValue("beam wallet logs", forKey: "subject")
        }
        
        vc.excludedActivityTypes = [UIActivity.ActivityType.postToFacebook, UIActivity.ActivityType.assignToContact, UIActivity.ActivityType.copyToPasteboard, UIActivity.ActivityType.print,UIActivity.ActivityType.openInIBooks]
        
        controller.present(vc, animated: true)
    }
}

class SettingsViewModel {
    
    public var items = [[SettingsItem]]()

    class SettingsItem {
        enum Position {
            case one
            case midle
        }
        
        public var title:String?
        public var detail:String?
        public var isSwitch:Bool?
        public var id:Int!
        public var position:Position!
        
        init(title: String?, detail: String?, isSwitch: Bool?, id:Int, position:Position) {
            self.title = title
            self.detail = detail
            self.isSwitch = isSwitch
            self.id = id
            self.position = position
        }
    }
    
    init() {
        initItems()
    }
    
    private func initItems() {
        var first = [SettingsItem]()
        first.append(SettingsItem(title: "ip:port:", detail: Settings.sharedManager().nodeAddress, isSwitch: nil, id: 5, position: .one))
        
        var second = [SettingsItem]()
        second.append(SettingsItem(title: "Ask for password on every Send", detail: nil, isSwitch: Settings.sharedManager().isNeedaskPasswordForSend, id: 3, position: .midle))
        if BiometricAuthorization.shared.canAuthenticate() {
            second.append(SettingsItem(title: BiometricAuthorization.shared.faceIDAvailable() ? "Enable Face ID" : "Enable Touch ID", detail: nil, isSwitch: Settings.sharedManager().isEnableBiometric, id: 4, position: .midle))
        }
        second.append(SettingsItem(title: "Change wallet password", detail: nil, isSwitch: nil, id: 1, position: .one))
        
        var three = [SettingsItem]()
        three.append(SettingsItem(title: "Clear data", detail: nil, isSwitch: nil, id: 6, position: .midle))
        three.append(SettingsItem(title: "Report a problem", detail: nil, isSwitch: nil, id: 2, position: .one))
        
        items.append(first)
        items.append(second)
        items.append(three)
        
        if !NotificationManager.disableApns {
            var four = [SettingsItem]()
            four.append(SettingsItem(title: "Open telegram bot", detail: nil, isSwitch: nil, id: 8, position: .midle))
            four.append(SettingsItem(title: "Linking telegram bot", detail: nil, isSwitch: nil, id: 7, position: .one))
            items.append(four)
        }
    }
    
    public func getItem(indexPath:IndexPath) -> SettingsItem {
        return items[indexPath.section][indexPath.row]
    }
}
