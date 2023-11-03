//
//  DAOConfirmViewModel.swift
//  BeamWallet
//
//  Created by Denis on 06.09.2021.
//  Copyright © 2021 Denis. All rights reserved.
//

import UIKit

struct DAOInfo: Codable {
    let comment:String?
    let fee:String?
    let feeRate:String?
    let isEnough:Bool?
    let isSpend:Bool?
    let rateUnit:String?
}

struct DAOAmount: Codable {
    let amount:String?
    let assetID:Int?
    let spend:Bool?
}

class DAOConfirmViewModel: NSObject {
    
    var info:DAOInfo?
    var amountInfos:[DAOAmount]?

    public var items = [BMMultiLineItem]()

    var isSpend:Bool {
        return info?.isSpend == true
    }
    
    var amountInfo:DAOAmount? {
        return amountInfos?.first
    }
    
    init(infoJson: String, amountJson:String) {
        super.init()
        
        do {
            if let infoData = infoJson.data(using: .utf8) {
                self.info = try JSONDecoder().decode(DAOInfo.self, from: infoData)
            }
            
            if let amountData = amountJson.data(using: .utf8) {
                let array = try JSONDecoder().decode([DAOAmount].self, from: amountData)
                self.amountInfos = array
            }
        }
        catch {
            print(error)
        }
    }
}
