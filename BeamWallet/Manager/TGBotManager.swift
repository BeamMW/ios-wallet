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

class TGBotManager {
    
    private static var mainApi = "https://bar.beam.mw/api"
    
    public static func linkTGUser(user_id:String, fcmToken:String, address:String, completion: @escaping ((Error?) -> Void)) {
        let jsonRow: [String:Any] = ["push_token":fcmToken,"user_id":UInt64(user_id) ?? "" ,"wallet_address":address, "msgr_type":"tg"]
        
        let url = URL(string: "\(mainApi)/link_user")!
        
        sendRequest(url: url, parameters: jsonRow) { (error) in
            completion(error)
        }
    }
    
    public static func updateTransactionStatus(id:String, status: NotificationManager.TransactionStatus, type: NotificationManager.MessageType, completion: @escaping ((Error?) -> Void)) {
        
        let jsonRow: [String:Any] = ["id":id, type.rawValue: status.rawValue]
        
        let url = URL(string: "\(mainApi)/update_notification")!
        
        sendRequest(url: url, parameters: jsonRow) { (error) in
            completion(error)
        }
    }
    
    public static func updateNotificationStatus(id:String, status: NotificationManager.MessageStatus, type: NotificationManager.MessageType, completion: @escaping ((Error?) -> Void)) {
        
        let jsonRow: [String:Any] = ["id":id, type.rawValue: status.rawValue]
        
        let url = URL(string: "\(mainApi)/update_notification")!
        
        sendRequest(url: url, parameters: jsonRow) { (error) in
            completion(error)
        }
    }
    
    private static func sendRequest(url:URL, parameters:[String:Any], completion: @escaping ((Error?) -> Void)) {
     
        let session = URLSession.shared
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
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
