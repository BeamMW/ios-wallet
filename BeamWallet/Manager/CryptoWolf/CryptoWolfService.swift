//
// CryptoWolfService.swift
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

class CryptoWolfService: NSObject  {
    
    typealias Pairs = [String: [String]]
    typealias Currencies = [String]
    typealias Rates = [[Double]]
    
    struct OrderResponse: Codable {
        let status, address, error: String?
    }
    
    struct TransactionInfo: Codable {
        let code:Int?
        let dtxid, rtxid: String?
    }

    static let sharedManager = CryptoWolfService()

    public func findCurrencies(completion:@escaping ((Currencies?,Error?) -> Void)) {
        
        let provider = MoyaProvider<CryptoWolfAPI>()
        provider.request(.pairs) { [weak self] result in
            guard self != nil else { return }
            
            switch result {
            case .success(let response):
                var result = Currencies()
                
                if let currencies = try? JSONDecoder().decode(Pairs.self, from: response.data) {
                    for currency in currencies.keys {
                        if let subCurrencies = currencies[currency]
                        {
                            for subCurrency in subCurrencies {
                                if subCurrency == "BEAM" {
                                    result.append(currency)
                                }
                            }
                        }
                    }
                }
                
                completion(result,nil)
            case .failure (let error):
                completion(nil,error)
            }
        }
    }
    
    public func findRates(from:String, to:String, completion:@escaping ((Rates?,Error?) -> Void)) {
        
        let provider = MoyaProvider<CryptoWolfAPI>()
        provider.request(.rates(from: from, to: to)) { [weak self] result in
            guard self != nil else { return }
            
            switch result {
            case .success(let response):
                if let rates = try? JSONDecoder().decode(Rates.self, from: response.data) {
                    completion(rates,nil)
                }
                else{
                    completion(nil,nil)
                }
            case .failure (let error):
                completion(nil,error)
            }
        }
    }
    
    public func submitOrder(from:String, to:String, fromAddress:String, toAddress:String, amount:String, captcha:String, emailaddress:String, completion:@escaping ((OrderResponse?,Error?) -> Void)) {
     
        let provider = MoyaProvider<CryptoWolfAPI>()
        provider.request(.order(from: from, to: to, fromAddress: fromAddress, toAddress: toAddress, amount: amount, captcha: captcha, emailaddress: emailaddress)) { [weak self] result in
            guard self != nil else { return }
            
            switch result {
            case .success(let response):
                print(String(data: response.data, encoding: .utf8) as Any)
                if let resp = try? JSONDecoder().decode(OrderResponse.self, from: response.data) {
                    completion(resp,nil)
                }
                else{
                    completion(nil,nil)
                }
            case .failure (let error):
                print(error)
                completion(nil,error)
            }
        }
    }
    
    public func getTransactionInfo(address:String, currency:String, completion:@escaping ((TransactionInfo?,Error?) -> Void)) {
        
        let provider = MoyaProvider<CryptoWolfAPI>()
        provider.request(.transactionInfo(address: address, currency:currency)) { [weak self] result in
            guard self != nil else { return }
            
            switch result {
            case .success(let response):
                print(String(data: response.data, encoding: .utf8))
                
                if let info = try? JSONDecoder().decode(TransactionInfo.self, from: response.data) {
                    completion(info,nil)
                }
                else{
                    completion(nil,nil)
                }
            case .failure (let error):
                completion(nil,error)
            }
        }
    }
}
