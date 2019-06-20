//
// BuyBeamViewModel.swift
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

class BuyBeamViewModel: ReceiveAddressViewModel {
    
    public var onCalculationChange : (() -> Void)?

    public var minimumAmount = String.empty()
    public var amountError:String?
    
    override var amount: String?{
        didSet{
            calculateReceive()
        }
    }
    
    public var currency = String.empty() {
        didSet{
            receiveAmount = String.empty()
            loading = true
            fromAddress = String.empty()
            loadRates()
        }
    }
    
    public var receiveAmount = String.empty()

    public var fromAddress = String.empty()
    public var fromAddressError:String?
    
    private var timer:Timer?
    public var loading = false

    private func calculateReceive() {
        var receive = CryptoWolfManager.sharedManager.calculateReceiving(from: currency, to: "BEAM", sending: Double(amount!) ?? 0)
        if receive.count > 0 {
            if receive[0] > 0 {
                let v = receive[0].rounded(toPlaces: Int(CryptoWolfManager.sharedManager.round(coin: currency)))
                receiveAmount = String.currency(value: v)
            }
            else{
                receiveAmount = String.empty()
            }
        }
        else{
            receiveAmount = String.empty()
        }
        
        let min = CryptoWolfManager.sharedManager.calculateMinAmount(from: currency)
        minimumAmount = (min > 0) ? (LocalizableStrings.minAmount(str: String.currency(value: min))) : String.empty()
    }
    
    override init() {
        super.init()
        
        amount = String.empty()
        
        if let f = CryptoWolfManager.sharedManager.availableCurrencies.first {
            currency = f
            
            let min = CryptoWolfManager.sharedManager.calculateMinAmount(from: currency)
            minimumAmount = (min > 0) ? (LocalizableStrings.minAmount(str: String.currency(value: min))) : String.empty()
        }
        
        loadRates()
    }
    
    @objc private func loadRates() {
        CryptoWolfManager.sharedManager.refreshRates(currency: currency) {
            [weak self] in
            
            guard let strongSelf = self else { return }
            
            strongSelf.loading = false

            strongSelf.timer?.invalidate()
            strongSelf.timer = nil
            strongSelf.timer = Timer.scheduledTimer(timeInterval: TimeInterval(5), target: strongSelf, selector: #selector(strongSelf.loadRates), userInfo: nil, repeats: false)
            
            strongSelf.calculateReceive()
            DispatchQueue.main.async {
                strongSelf.onCalculationChange?()
            }
        }
    }
    
    deinit {
        timer?.invalidate()
        timer = nil
    }
    
    public func onChangeCurrency() {
        if let top = UIApplication.getTopMostViewController() {
            let vc = BuyBeamCurrencyPicker(currency: currency)
            vc.completion = {
                [weak self] selected in
                
                if let currency = selected {
                    self?.currency = currency
                    self?.onDataChanged?()
                }
            }
            top.pushViewController(vc: vc)
        }
    }
    
    public func onCanSend() -> Bool {
        var isValid = true
        
        let am = Double(amount!) ?? 0
        
        if amount!.isEmpty{
            isValid = false
            amountError = LocalizableStrings.amount_empty
        }
        else if am == 0 {
            isValid = false
            amountError = LocalizableStrings.amount_zero
        }
        else if am < CryptoWolfManager.sharedManager.calculateMinAmount(from: currency)
        {
            isValid = false
            amountError = LocalizableStrings.incorrect_amount
        }
        
        if fromAddress.isEmpty {
            isValid = false
            
            fromAddressError = LocalizableStrings.incorrect_address
        }
      
        return isValid
    }
}
