//
// CryptoWolfManager.swift
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
import Moya


class CryptoWolfManager: NSObject  {
    
    typealias Rates = [String: CryptoWolfService.Rates]

    static let sharedManager = CryptoWolfManager()
    
    public let termsUrl = URL(string: "https://cryptowolf.eu/ToS.pdf")!
    
    public var availableCurrencies = CryptoWolfService.Currencies()
    public var rates = Rates()
    public var order:CryptoWolfService.OrderResponse?

    
    override init() {
        super.init()
        
        NotificationCenter.default.addObserver(self, selector: #selector(didBecomeActive), name: UIApplication.didBecomeActiveNotification, object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(didEnterBackground), name: UIApplication.didEnterBackgroundNotification, object: nil)
    }
    
    @objc private func didBecomeActive() {
        
    }
    
    @objc private func didEnterBackground() {
        
    }
 
    
    public func findCurrencies(completion:((CryptoWolfService.Currencies?,Error?) -> Void)?) {
        CryptoWolfService.sharedManager.findCurrencies {(currencies, error) in
            completion?(currencies,error)
        }
    }
    
    public func findRates(from:String, to:String, completion:((CryptoWolfService.Rates?,Error?) -> Void)?) {
        CryptoWolfService.sharedManager.findRates(from: from, to: to) { (rates, error) in
            completion?(rates,error)
        }
    }
    
    public func submitOrder(from:String, to:String, fromAddress:String, toAddress:String, amount:String, captcha:String, emailaddress:String, completion:((CryptoWolfService.OrderResponse?,Error?) -> Void)?) {
        
        CryptoWolfService.sharedManager.submitOrder(from: from, to: to, fromAddress: fromAddress, toAddress: toAddress, amount: amount, captcha: captcha, emailaddress: emailaddress) { [weak self] (response, error) in
            
            guard let strongSelf = self else { return }

            strongSelf.order = response
           
            completion?(response,error)
        }
    }
    
    
    public func refreshRates(currency:String, completion:@escaping (() -> Void)) {
        self.findRates(from: currency, to: "BEAM", completion: { [weak self] (rates, _) in
            if rates != nil {
                self?.rates[currency] = rates!
            }
            completion()
        })
    }
    
    public func loadData(completion:@escaping (() -> Void)) {
        rates.removeAll()
        
        let semaphore = DispatchSemaphore(value: 0)

        let queue = DispatchQueue.global()
        queue.async{
            self.findCurrencies(completion: {[weak self] (currencies , _ ) in
                if (currencies != nil)
                {
                    self?.availableCurrencies.removeAll()
                    self?.availableCurrencies.append(contentsOf: currencies!)
                    self?.availableCurrencies.sort()
                }
                semaphore.signal()
            })
            
            semaphore.wait()
            
            for currency in self.availableCurrencies {
                self.findRates(from: currency, to: "BEAM", completion: { [weak self] (rates, _) in
                    if rates != nil {
                        self?.rates[currency] = rates!
                    }
                    if currency == self?.availableCurrencies.last {
                        semaphore.signal()
                    }
                })
            }
            
            semaphore.wait()
            
            completion()
        }
    }
    
    public func calculateMinAmount(from:String) -> Double {
        if let rates = self.rates[from] {
            let round = Int(CryptoWolfManager.sharedManager.round(coin: from))

            var offset = Localizable.shared.strings.zero + "."
            
            for _ in 1...round - 1{
                offset = offset + Localizable.shared.strings.zero
            }
            
            offset = offset + "1"
            
            let value =  50.0 / rates[0][1]
            
            let min = value.rounded(toPlaces: round) + (Double(offset) ?? 0)
            
            return min
        }
        
        return 0
    }
    
    public func calculateReceiving(from:String, to:String, sending:Double) -> [Double] {
        if let rates = self.rates[from] {
            var result = gotovolumeptsu(amount: sending, rate: rates)
            
            let receiving = result[1] as! Double
            
            let receivingUSD = sending * receiving;
            
            let f = floorfind(coin: to)
            
            let v1 = floor(receiving * (pow(10, f)))
            let v2 = (pow(10, f))
            let v3 = v1 / v2
            
            return [v3, receivingUSD]
        }
        return []
    }
    
    private func gotovolumeptsu(amount:Double, rate:CryptoWolfService.Rates) -> [Any] {
        var indx = 0;
        var loopamount:Double = 0;
        var loopreceiving:Double = 0;
        var am = amount
        
        while(am >= rate[indx][2]) {
            if (indx > 0 ) {
                loopreceiving = ((rate[indx][2] - rate[indx - 1][2]) * rate[indx][0]) + loopreceiving;
            } else if (indx == 0) {
                loopreceiving = rate[indx][2] * rate[indx][0];
            }
            
            indx = indx + 1;
            
            if indx >= rate.count {
                indx = indx - 1;
                am = rate[indx][2];
                break
            }
        }
        
        if (indx == 0) {
            return [rate[0],amount * rate[0][0]];
        }
        
        loopamount = rate[indx-1][2] - am;
        let remaining = loopreceiving - (loopamount * rate[indx-1][0]);
        return [rate[indx],remaining];
    }
    
    private func floorfind(coin:String) -> Double {
        let round = ["BTC":8.0, "ETH":3, "LTC":3]
        
        if let value = round[coin] {
            return value
        }
        
        return 1
    }
    
    public func round(coin:String) -> Double {
        let round = ["BTC":4.0, "ETH":3, "LTC":3]
        
        if let value = round[coin] {
            return value
        }
        
        return 3
    }
    
    public func fullName(coin:String) -> String {
        let names = ["BTC":"Bitcoin", "LTC":"Litecoin", "ETH":"Ethereum"]
        
        if let value = names[coin] {
            return value
        }
        
        return String.empty()
    }
    
    public func orderQRCode(amount:String, currency:String) -> String {
        if let address = order?.address {
            if currency == "BTC" || currency == "LTC" {
                return "bitcoin:\(address)?amount=\(amount)"
            }
            else if currency == "ETH" {
                return address
            }
        }
        return String.empty()
    }
}
