//
// NotificationItem.swift
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

class NotificationItem {
    public var nId:String!
    public var pId:String!
    public var isRead:Bool!
    public var type:BMNotificationType!

    public var name:String?
    public var detail:NSMutableAttributedString?
    public var categories:NSMutableAttributedString?
    public var date:String?
    public var icon:UIImage?

    
    required init(notification: BMNotification) {
        nId = notification.nId
        pId = notification.pId
        isRead = notification.isRead
        type = notification.type
        date = notification.formattedDate()
        
        if(notification.type == TRANSACTION) {
            if let transaction = AppModel.sharedManager().transaction(byId: notification.pId) {
                if transaction.isIncome {
                    if transaction.isFailed() || transaction.isExpired() {
                        icon = UIImage.init(named: "iconNotifictionsFailedReceived")
                        name = Localizable.shared.strings.buy_transaction_failed_title
                        let beam = Settings.sharedManager().isHideAmounts ? String.empty() : String.currency(value: transaction.realAmount)
                        detail = Localizable.shared.strings.muttableTransaction_received_notif_body(beam: beam, address: transaction.senderAddress, failed: true)
                    }
                    else {
                        icon = UIImage.init(named: "iconNotifictionsReceived")
                        name = Localizable.shared.strings.transaction_received
                        let beam = Settings.sharedManager().isHideAmounts ? String.empty() : String.currency(value: transaction.realAmount)
                        detail = Localizable.shared.strings.muttableTransaction_received_notif_body(beam: beam, address: transaction.senderAddress, failed: false)
                    }
                }
                else {
                    if transaction.isFailed() || transaction.isExpired() {
                        icon = UIImage.init(named: "iconNotifictionsFailed")
                        name = Localizable.shared.strings.buy_transaction_failed_title
                        let beam = Settings.sharedManager().isHideAmounts ? String.empty() : String.currency(value: transaction.realAmount)
                        detail = Localizable.shared.strings.muttableTransaction_sent_notif_body(beam:beam , address: transaction.receiverAddress, failed: true)
                    }
                    else {
                        icon = UIImage.init(named: "iconNotifictionsSent")
                        name = Localizable.shared.strings.transaction_sent
                        let beam = Settings.sharedManager().isHideAmounts ? String.empty() : String.currency(value: transaction.realAmount)
                        detail = Localizable.shared.strings.muttableTransaction_sent_notif_body(beam: beam, address: transaction.receiverAddress, failed: false)
                    }
                }
            }
        }
        else if(notification.type == ADDRESS) {
            icon = UIImage.init(named: "iconNotifictionsExpired")
            name = Localizable.shared.strings.address_expired
            
            if let address = AppModel.sharedManager().findAddress(byID: notification.pId) {
                if address.categories.count > 0 {
                    categories = address.categoriesName()
                }
                
                if address.label.isEmpty {
                    let attributedText = NSMutableAttributedString(string: pId)
                    attributedText.addAttribute(NSAttributedString.Key.font, value: RegularFont(size: 14) , range: NSRange(location: 0, length: pId.count))
                    detail = attributedText
                }
                else {
                    let string = address.label + "\n" + pId
                    
                    let rangeId = (string as NSString).range(of: String(pId))
                    let rangeName = (string as NSString).range(of: String(address.label))

                    let attributedText = NSMutableAttributedString(string: string)
                    attributedText.addAttribute(NSAttributedString.Key.font, value: RegularFont(size: 14) , range: rangeId)
                    attributedText.addAttribute(NSAttributedString.Key.font, value: BoldFont(size: 14) , range: rangeName)
                    detail = attributedText
                }
            }
            else {
                let attributedText = NSMutableAttributedString(string: pId)
                attributedText.addAttribute(NSAttributedString.Key.font, value: RegularFont(size: 14) , range: NSRange(location: 0, length: pId.count))
                detail = attributedText
            }
        }
    }
    
}
