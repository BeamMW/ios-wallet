//
// CryptoWolfAPI.swift
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

enum CryptoWolfAPI {
    case pairs
    case rates(from:String, to: String)
    case order(from:String, to:String, fromAddress:String, toAddress:String, amount:Double, captcha:String, emailaddress:String)
}

extension CryptoWolfAPI: TargetType {
    
    var sampleData: Data {
        return Data()
    }
    
    var headers: [String : String]? {
        return nil
    }
    
    var baseURL: URL {
        return URL(string: "https://external.cryptowolf.eu/wallet")!
    }
    
    var path: String {
        switch self {
        case .pairs:
            return "get-pairs.php"
        case .rates:
            return "get-rates.php"
        case .order:
            return "mail.php"
        }
    }
    
    var method: Moya.Method {
        switch self {
        case .pairs, .rates:
            return .get
        case .order:
            return .post
        }
    }
    
    var task: Task {
        switch self {
        case .pairs:
            return Task.requestPlain
        case let .rates(from, to):
            return .requestParameters(parameters: ["from":from,"to":to], encoding: URLEncoding.queryString)
        case let .order(from, to, fromAddress, toAddress, amount, captcha, emailaddress):
            return .requestParameters(parameters: ["from":from,"to":to, "amount":amount, "refundid":fromAddress, "receivingid":toAddress, "captcha":captcha, "emailaddress":emailaddress], encoding: URLEncoding.httpBody)
        }
    }
}
