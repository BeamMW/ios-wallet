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
    
    private var info:DAOInfo?
    private var amountInfo:DAOAmount?

    public var items = [BMMultiLineItem]()

    var isSpend:Bool {
        return info?.isSpend == true
    }
    
    init(infoJson: String, amountJson:String) {
        super.init()
        
        do {
            if let infoData = infoJson.data(using: .utf8) {
                self.info = try JSONDecoder().decode(DAOInfo.self, from: infoData)
            }
            
            if let amountData = amountJson.data(using: .utf8) {
                let array = try JSONDecoder().decode([DAOAmount].self, from: amountData)
                self.amountInfo = array.first
            }
            
            self.items = buildBMMultiLineItems()
        }
        catch {
            print(error)
        }
    }
    
    private func buildBMMultiLineItems() -> [BMMultiLineItem]{
        var items = [BMMultiLineItem]()
        

        if let comment = info?.comment, !comment.isEmpty {
            items.append(BMMultiLineItem(title: Localizable.shared.strings.comment.uppercased(), detail: comment, detailFont: RegularFont(size: 16), detailColor: UIColor.white, copy: false))
        }
        
        if  let amount = amountInfo?.amount, !amount.isEmpty, let realAmount = Double(amount) {
            let amountS = String.currencyWithoutName(value: realAmount)
            let amountDetail = amountString(amount: amountS, isFee: false, assetId: amountInfo?.assetID ?? 0, color: isSpend ? UIColor.main.heliotrope : UIColor.main.brightSkyBlue)
            let amountItem = BMMultiLineItem(title: Localizable.shared.strings.amount.uppercased(), detail: amountDetail.string, detailFont: SemiboldFont(size: 16), detailColor: isSpend ? UIColor.main.heliotrope : UIColor.main.brightSkyBlue)
            amountItem.detailAttributedString = amountDetail
            items.append(amountItem)
        }
        
        if  let amount = info?.fee, !amount.isEmpty, let realAmount = Double(amount) {
            let amountS = String.currencyWithoutName(value: realAmount)
            let amountDetail = amountString(amount: amountS, isFee: true, assetId: amountInfo?.assetID ?? 0, color: UIColor.white)
            let amountItem = BMMultiLineItem(title: Localizable.shared.strings.fee.uppercased(), detail: amountDetail.string, detailFont: SemiboldFont(size: 16), detailColor: UIColor.white)
            amountItem.detailAttributedString = amountDetail
            items.append(amountItem)
        }
        
        
        return items
    }
    
    private func amountString(amount: String, isFee:Bool, assetId:Int, color: UIColor? = nil, doubleAmount:Double = 0.0) -> NSMutableAttributedString {
        var assetName = (AssetsManager.shared().getAsset(Int32(assetId))?.unitName ?? "") + " "
        if assetName == "assets" {
            assetName = "BEAM"
        }
        if assetName.count > 10 {
            assetName = assetName.prefix(10) + "..."
        }
        
        let amountString =  isFee ? ((amount + Localizable.shared.strings.beam + "\n")) : ((amount + " " + assetName + "\n"))
        var secondString = isFee ? ExchangeManager.shared().exchangeValueAsset(Double(amount) ?? 0, assetID: UInt64(0)) :
            ExchangeManager.shared().exchangeValueAsset(Double(amount) ?? 0, assetID: UInt64(assetId))
        if doubleAmount > 0.0 {
            secondString = isFee ? ExchangeManager.shared().exchangeValue(withZero: doubleAmount) :  ExchangeManager.shared().exchangeValueAsset(doubleAmount, assetID: UInt64(assetId))
        }
        let attributedString = amountString + "space\n" + secondString
        
        let attributedTitle = NSMutableAttributedString(string: attributedString)
        let rangeAmount = (attributedString as NSString).range(of: String(amountString))
        let rangeSecond = (attributedString as NSString).range(of: String(secondString))
        let spaceRange = (attributedString as NSString).range(of: String("space"))
        
        attributedTitle.addAttribute(NSAttributedString.Key.font, value: SemiboldFont(size: 16) , range: rangeAmount)
        
        if let color = color {
            attributedTitle.addAttribute(NSAttributedString.Key.foregroundColor, value: color, range: rangeAmount)
        }

        
        attributedTitle.addAttribute(NSAttributedString.Key.font, value: LightFont(size: 5), range: spaceRange)
        attributedTitle.addAttribute(NSAttributedString.Key.foregroundColor, value: UIColor.clear, range: spaceRange)
        
        attributedTitle.addAttribute(NSAttributedString.Key.font, value: RegularFont(size: 14), range: rangeSecond)
        attributedTitle.addAttribute(NSAttributedString.Key.foregroundColor, value: Settings.sharedManager().isDarkMode ? UIColor.main.steel : UIColor.main.steelGrey, range: rangeSecond)
        return attributedTitle
    }
}
