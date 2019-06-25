//
// TGBotManager.swift
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

class TGBotManager : NSObject {
    
    struct TGUser {
        public var userId = ""
        public var userName = ""
    }
    
    static let sharedManager = TGBotManager()

    private static var mainApi = "https://anywhere.beam.mw/api"
    
    private var isStartLinking = false
    private var completion : ((Bool) -> Void)?

    private var user = TGUser()

    public func isNeedLinking()->Bool {
        if user.userName.isEmpty {
            return false
        }
        return true
    }
    
    public func isValidUserFromUrl(url:URL)->Bool {
        if let params = url.queryParameters {
            if let id = params["user_id"], let name = params["username"] {
                
                user.userId = id
                user.userName = name
                
                return true
            }
        }
        
        return false
    }
    
    public func isValidUserFromJson(value:String)->Bool {
        if let json = ((try? JSONSerialization.jsonObject(with: value.data(using: .utf8)!, options: .mutableContainers) as? [String: Any]) as [String : Any]??) {
            
            if let id = json?["_id"] as? u_quad_t, let name = json?["username"] as? String {
                
                user.userId = String(id)
                user.userName = name
                
                return true
            }
        }
        
        return false;
    }
    
    //MARK: - HTTP methods
    
    public func startLinking(completion:@escaping ((Bool) -> Void)) {
        #if EXTENSION
        print("ignore")
        #else
        if user.userId.isEmpty == false && isStartLinking == false && AppModel.sharedManager().isWalletInitialized() && AppModel.sharedManager().isConnected {
            
            NotificationManager.sharedManager.isApnsEnabled { (enabled) in
                DispatchQueue.main.async {
                    if enabled {
                        SVProgressHUD.show(withStatus: Localizables.shared.strings.tg_bot_connection)
                        
                        self.completion = completion
                        
                        self.isStartLinking = true
                        
                        AppModel.sharedManager().generateNewWalletAddress { (address, error) in
                            if let result = address {
                                self.onGeneratedNewAddress(result)
                            }
                        }
                    }
                    else{
                        if let top = UIApplication.getTopMostViewController() {
                            top.confirmAlert(title: Localizables.shared.strings.tg_bot, message: Localizables.shared.strings.tg_bot_not_linked_notification, cancelTitle: Localizables.shared.strings.cancel, confirmTitle: Localizables.shared.strings.open_settings, cancelHandler: { (_) in
                            }, confirmHandler: { (_) in
                                guard let settingsUrl = URL(string: UIApplication.openSettingsURLString) else {
                                    return
                                }
                                if UIApplication.shared.canOpenURL(settingsUrl) {
                                    UIApplication.shared.open(settingsUrl, completionHandler: { (success) in
                                    })
                                }
                            })
                        }
                    }
                }
            }
        }
        #endif
    }
    
    public static func linkTGUser(user:TGUser, fcmToken:String, address:String, completion: @escaping ((Error?) -> Void)) {
        let jsonRow: [String:Any] = ["push_token":fcmToken,"user_id":UInt64(user.userId) ?? "" ,"wallet_address":address, "msgr_type":"tg", "username" : user.userName]
        
        let url = URL(string: "\(mainApi)/link_user")!
        
        sendRequest(url: url, parameters: jsonRow, method: "POST") { (error) in
            completion(error)
        }
    }
    
    public static func updateTransactionStatus(id:String, status: NotificationManager.TransactionStatus, type: NotificationManager.MessageType, completion: @escaping ((Error?) -> Void)) {
        
        let jsonRow: [String:Any] = ["id":id, type.rawValue: status.rawValue]
        
        let url = URL(string: "\(mainApi)/update_notification")!
        
        sendRequest(url: url, parameters: jsonRow, method: "PUT") { (error) in
            completion(error)
        }
    }
    
    public static func updateNotificationStatus(id:String, status: NotificationManager.MessageStatus, type: NotificationManager.MessageType, completion: @escaping ((Error?) -> Void)) {
        
        let jsonRow: [String:Any] = ["id":id, type.rawValue: status.rawValue]
        
        let url = URL(string: "\(mainApi)/update_notification")!
        
        sendRequest(url: url, parameters: jsonRow, method: "PUT") { (error) in
            completion(error)
        }
    }
    
    //MARK: - Requests

    private static func sendRequest(url:URL, parameters:[String:Any], method:String, completion: @escaping ((Error?) -> Void)) {
     
        let session = URLSession.shared
        
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: parameters, options: .prettyPrinted)
            
        } catch let error {
            print(error.localizedDescription)
        }
        
        let task = session.dataTask(with: request, completionHandler: { data, response, error in
            
            guard error == nil else {
                completion(error)
                return
            }
            
            guard let data = data else {
                completion(nil)
                return
            }
            
            do {
                if let json = try JSONSerialization.jsonObject(with: data, options: .mutableContainers) as? [String: Any] {
                    print(json)
                }
                
                completion(nil)
            } catch let error {
                print(error.localizedDescription)
                completion(error)
            }
        })
        task.resume()
    }
}

extension TGBotManager  {
    
    func onGeneratedNewAddress(_ address: BMAddress) {
        #if !EXTENSION
        DispatchQueue.main.async {
            if self.isStartLinking {
                
                self.isStartLinking = false
                
                AppModel.sharedManager().editBotAddress(address.walletId)
                
                if let token = NotificationManager.sharedManager.fcmToken() {
                    
                    NotificationManager.sharedManager.subscribeToTopic(topic: address.walletId)
                    
                    TGBotManager.linkTGUser(user: self.user, fcmToken: token, address: address.walletId) {[weak self] (error ) in 
                        
                        guard let strongSelf = self else { return }

                        DispatchQueue.main.async {
                            strongSelf.user.userId = String.empty()
                            strongSelf.completion?(error == nil ? true : false)
                            
                            SVProgressHUD.showSuccess(withStatus: (error==nil) ? Localizables.shared.strings.tg_bot_linked : Localizables.shared.strings.tg_bot_not_linked)
                            
                            SVProgressHUD.dismiss(withDelay: 2.5)
                        }
                    }
                }
            }
        }
        #endif
    }
}
