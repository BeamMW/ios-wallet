//
// SendTransactionViewModel.swift
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

class UnlinkTransactionViewModel: NSObject {
        
    public var amountError:String?
    public var didChangeCalculated : ((BMMultiLineItem) -> Void)?

    public var amount = String.empty() {
        didSet {
            amountError = nil
        }
    }
    
    public var fee = String(0) {
        didSet{
            if sendAll {
                amount = AppModel.sharedManager().allAmount(Double(fee) ?? 0)
            }
        }
    }
    
    public var sendAll = false {
        didSet{
            if sendAll {
                amount = AppModel.sharedManager().allAmount(Double(fee) ?? 0)
            }
        }
    }
    
    override init() {
        super.init()
        
        AppModel.sharedManager().addDelegate(self)
        
        fee = String(AppModel.sharedManager().getMinUnlinkFeeInGroth())
    }
    
    deinit {
        didChangeCalculated = nil
        AppModel.sharedManager().removeDelegate(self)
    }
    
    public func send() {
        AppModel.sharedManager().sendUnlink((Double(amount) ?? 0), fee: (Double(fee) ?? 0))
    }
    
    public func calculateChange() {
        AppModel.sharedManager().calculateChange(Double(amount) ?? 0, fee:  Double(fee) ?? 0)
    }
    
    public func checkAmountError() {
        let canSend = AppModel.sharedManager().canUnlink((Double(amount) ?? 0), fee: (Double(fee) ?? 0))
        
        if canSend != Localizable.shared.strings.incorrect_address && ((Double(amount) ?? 0)) > 0 {
            amountError = canSend
        }
        else{
            amountError = nil
        }
    }
    
    public func checkFeeError() {
        if sendAll {
            if let a = Double(amount), let f = Double(fee) {
                if a == 0 && f > 0  {
                    amount = AppModel.sharedManager().allAmount(0)
                    amountError = AppModel.sharedManager().feeError(f)
                }
                else if a == 0 {
                    amountError = Localizable.shared.strings.amount_zero
                }
            }
        }
    }
    
    public func canSend() -> Bool {
        let canSend = AppModel.sharedManager().canUnlink((Double(amount) ?? 0), fee: (Double(fee) ?? 0))
        
        let isError = (canSend != nil)
        
        if isError {
            amountError = nil

            if amount.isEmpty {
                amountError = Localizable.shared.strings.amount_empty
            }
            else if canSend != Localizable.shared.strings.incorrect_address {
                amountError = canSend
            }
        }
        
        return !isError
    }
    
    public func buildBMMultiLineItems() -> [BMMultiLineItem]{
        let totalReal = AppModel.sharedManager().realTotal(Double(amount) ?? 0, fee: Double(fee) ?? 0)
        let totalString = String.currency(value: totalReal) //+ Localizable.shared.strings.beam
        
        var items = [BMMultiLineItem]()

        let amountString = amount + "\n" //+ Localizable.shared.strings.beam + "\n"
        let amountSecondString = AppModel.sharedManager().exchangeValue(Double(amount) ?? 0)
        
        let feeString = fee + Localizable.shared.strings.groth + "\n"
        let feeSecondString = AppModel.sharedManager().exchangeValueFee(Double(fee) ?? 0)
        
        let amountTotalString = totalString + "\n"
        let amountTotalSecondString = AppModel.sharedManager().exchangeValue(Double(totalReal) )
        
        let remaining = AppModel.sharedManager().remaining(Double(amount) ?? 0, fee: Double(fee) ?? 0)
        let remainingString = String.currency(value: remaining) + "\n" //+ Localizable.shared.strings.beam + "\n"
        let remainingSecondString = AppModel.sharedManager().exchangeValue(Double(remaining))
        
        items.append(detailAttributed(title: Localizable.shared.strings.amount_to_unlink, amountString: amountString, secondString: amountSecondString, color: UIColor.main.brightTeal))
        items.append(detailAttributed(title: Localizable.shared.strings.unlinking_fee, amountString: feeString, secondString: feeSecondString, color: UIColor.main.brightTeal))
        items.append(detailAttributed(title: Localizable.shared.strings.total_utxo, amountString: amountTotalString, secondString: amountTotalSecondString, color: UIColor.white))
        items.append(detailAttributed(title: Localizable.shared.strings.remaining, amountString: remainingString, secondString: remainingSecondString, color: UIColor.white))
        items.append(BMMultiLineItem(title: Localizable.shared.strings.unlink_notice, detail: nil, detailFont: nil, detailColor: nil))
        
        return items
    }
    
    private func detailAttributed(title: String, amountString: String, secondString: String, color:UIColor) -> BMMultiLineItem {
        
        let attributedString = amountString + "space\n" + secondString

        let attributedTitle = NSMutableAttributedString(string: attributedString)
        let rangeAmount = (attributedString as NSString).range(of: String(amountString))
        let rangeSecond = (attributedString as NSString).range(of: String(secondString))
        let spaceRange = (attributedString as NSString).range(of: String("space"))
        
        attributedTitle.addAttribute(NSAttributedString.Key.font, value: SemiboldFont(size: 16) , range: rangeAmount)
        attributedTitle.addAttribute(NSAttributedString.Key.foregroundColor, value: color, range: rangeAmount)
        
        attributedTitle.addAttribute(NSAttributedString.Key.font, value: LightFont(size: 5), range: spaceRange)
        attributedTitle.addAttribute(NSAttributedString.Key.foregroundColor, value: UIColor.clear, range: spaceRange)
        
        attributedTitle.addAttribute(NSAttributedString.Key.font, value: RegularFont(size: 14), range: rangeSecond)
        attributedTitle.addAttribute(NSAttributedString.Key.foregroundColor, value: Settings.sharedManager().isDarkMode ? UIColor.main.steel : UIColor.main.steelGrey, range: rangeSecond)
        
        let amountItem = BMMultiLineItem(title: title.uppercased(), detail: attributedString, detailFont: SemiboldFont(size: 16), detailColor: color)
        amountItem.detailAttributedString = attributedTitle
        return amountItem
    }
}

extension UnlinkTransactionViewModel : WalletModelDelegate {
    
    func onChangeCalculated(_ amount: Double) {
        DispatchQueue.main.async {
            let totalString = String.currency(value: amount) //+ Localizable.shared.strings.beam
            let totalSecondString = AppModel.sharedManager().exchangeValue(Double(amount))
            let item = self.detailAttributed(title: Localizable.shared.strings.change, amountString: totalString, secondString: totalSecondString, color: UIColor.white)
            self.didChangeCalculated?(item)
        }
    }
}
