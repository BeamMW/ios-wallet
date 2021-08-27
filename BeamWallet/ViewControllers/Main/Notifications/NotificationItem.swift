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
    public var date:String?
    public var icon:UIImage?

    
    required init(notification: BMNotification) {
        nId = notification.nId
        pId = notification.pId
        isRead = notification.isRead
        type = notification.type
        date = notification.formattedDate()
        
        if(notification.type == VERSION) {
            icon = IconNotifictionsUpdate()
            name = Localizable.shared.strings.new_version_available_title(version: notification.pId)
        }
        else if(notification.type == TRANSACTION) {
            if let transaction = AppModel.sharedManager().transaction(byId: notification.pId) {
                guard let asset = transaction.asset else {
                    return
                }
                let assetValue = String.currencyShort(value: transaction.realAmount, name: asset.unitName)

                if transaction.isIncome {
                    if transaction.isFailed() || transaction.isExpired() || transaction.isCancelled() {
                        icon = UIImage.init(named: "iconNotifictionsFailedReceived")
                        name = Localizable.shared.strings.failed
                        detail = Localizable.shared.strings.muttableTransaction_received_notif_body(assetValue, address: transaction.senderAddress, failed: true)
                    }
                    else {
                        if transaction.isMaxPrivacy {
                            icon = UIImage(named: "iconNotifictionsReceivedMaxPrivacy")
                            name = Localizable.shared.strings.transaction_received
                            detail = Localizable.shared.strings.muttableTransaction_received_notif_body(assetValue, address: transaction.senderAddress, failed: false)
                        }
                        else if transaction.isShielded || transaction.isPublicOffline {
                            
                            if transaction.isPublicOffline {
                                name = Localizable.shared.strings.tr_received_public_offline
                            }
                            else {
                                name = Localizable.shared.strings.tr_received_offline
                            }
                            
                            icon = UIImage.init(named: "iconNotifictionsReceivedOffline")
                            detail = Localizable.shared.strings.muttableTransaction_received_notif_body(assetValue, address: Localizable.shared.strings.shielded_pool.lowercased(), failed: false)
                        }
                        else {
                            icon = UIImage.init(named: "iconNotifictionsReceived")
                            name = Localizable.shared.strings.transaction_received
                            detail = Localizable.shared.strings.muttableTransaction_received_notif_body(assetValue, address: transaction.senderAddress, failed: false)
                        }
                    }
                }
                else {
                    if transaction.isFailed() || transaction.isExpired() || transaction.isCancelled() {
                        if transaction.isMaxPrivacy {
                            icon = UIImage.init(named: "iconNotifictionsFailedSentMaxPrivacy")
                            name = Localizable.shared.strings.failed
                            detail = Localizable.shared.strings.muttableTransaction_sent_notif_body(assetValue , address: transaction.receiverAddress, failed: true)
                        }
                        else if transaction.isShielded || transaction.isPublicOffline {
                            icon = UIImage.init(named: "iconNotifictionsFailedSentOffline")
                            name = Localizable.shared.strings.failed
                            detail = Localizable.shared.strings.muttableTransaction_sent_notif_body(assetValue , address: "shielded pool", failed: true)
                        }
                        else {
                            icon = UIImage.init(named: "iconNotifictionsFailed")
                            name = Localizable.shared.strings.failed
                            detail = Localizable.shared.strings.muttableTransaction_sent_notif_body(assetValue, address: transaction.receiverAddress, failed: true)
                        }
                    }
                    else {
                        if transaction.isMaxPrivacy  {
                            icon = UIImage.init(named: "iconNotifictionsSentMaxPrivacy")
                            name = Localizable.shared.strings.transaction_sent
                        }
                        else if transaction.isShielded || transaction.isPublicOffline {
                            icon = UIImage.init(named: "iconNotifictionsSendedOffline")
           
                            if transaction.isPublicOffline {
                                name = Localizable.shared.strings.tr_sent_public_offline
                            }
                            else {
                                name = Localizable.shared.strings.tr_sent_offline
                            }
                        }
                        else {
                            icon = UIImage.init(named: "iconNotifictionsSent")
                            name = Localizable.shared.strings.transaction_sent
                        }
                        
                        detail = Localizable.shared.strings.muttableTransaction_sent_notif_body(assetValue, address: transaction.receiverAddress, failed: false)
                    }
                }
            }
        }
        else if(notification.type == ADDRESS) {
            icon = IconNotifictionsExpired()
            name = Localizable.shared.strings.address_expired
            
            if let address = AppModel.sharedManager().findAddress(byID: notification.pId) {
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
        }
        else {
            let attributedText = NSMutableAttributedString(string: pId)
            attributedText.addAttribute(NSAttributedString.Key.font, value: RegularFont(size: 14) , range: NSRange(location: 0, length: pId.count))
            detail = attributedText
        }
    }
    
}
