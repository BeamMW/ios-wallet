//
// AppStoreReviewManager.swift
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

struct AppStoreReviewManager {
    
    static let maxTransactionsCount = Int.max
    static let maxOpenedCount = Int.max

    static private let APP_OPENED_COUNT = "APP_OPENED_COUNT"
    static private let APP_FEEDBACK_OPENED = "APP_FEEDBACK_OPENED"
    static private let APP_TRANSACTIONS_COUNT = "APP_TRANSACTIONS_COUNT"

    static func incrementAppTransactions() {
        guard var transactionsCount = UserDefaults.standard.value(forKey: AppStoreReviewManager.APP_TRANSACTIONS_COUNT) as? Int else {
            UserDefaults.standard.set(1, forKey: AppStoreReviewManager.APP_TRANSACTIONS_COUNT)
            return
        }
        transactionsCount += 1
        UserDefaults.standard.set(transactionsCount, forKey: AppStoreReviewManager.APP_TRANSACTIONS_COUNT)
        UserDefaults.standard.synchronize()
    }
    
    static func incrementAppOpenedCount() {
        guard var appOpenCount = UserDefaults.standard.value(forKey: AppStoreReviewManager.APP_OPENED_COUNT) as? Int else {
            UserDefaults.standard.set(1, forKey: AppStoreReviewManager.APP_OPENED_COUNT)
            return
        }
        appOpenCount += 1
        UserDefaults.standard.set(appOpenCount, forKey: AppStoreReviewManager.APP_OPENED_COUNT)
        UserDefaults.standard.synchronize()
    }
    
    static func checkAndAskForReview() -> Bool {
        if UserDefaults.standard.bool(forKey: AppStoreReviewManager.APP_FEEDBACK_OPENED) {
            return false
        }
        
        guard let appOpenCount = UserDefaults.standard.value(forKey: AppStoreReviewManager.APP_OPENED_COUNT) as? Int else {
            UserDefaults.standard.set(1, forKey: AppStoreReviewManager.APP_OPENED_COUNT)
            return false
        }
        
        if  let transactionsCount = UserDefaults.standard.value(forKey: AppStoreReviewManager.APP_TRANSACTIONS_COUNT) as? Int {
            if transactionsCount == maxTransactionsCount {
                return true
            }
        }
        
        switch appOpenCount {
        case maxTransactionsCount:
            return true
        case _ where appOpenCount%maxTransactionsCount == 0 :
            return true
        default:
            print("App run count is : \(appOpenCount)")
            return false
        }
    }
    
    static func openAppStoreRatingPage() {
        UserDefaults.standard.set(true, forKey: AppStoreReviewManager.APP_FEEDBACK_OPENED)
        UserDefaults.standard.synchronize()
        
        let url = URL(string: "itms-apps://itunes.apple.com/app/id1459842353?action=write-review")
        
        UIApplication.shared.open(url!, options: [:], completionHandler: nil)
    }
    
    static func resetRating() {
        UserDefaults.standard.set(Int(0), forKey: AppStoreReviewManager.APP_OPENED_COUNT)
        UserDefaults.standard.set(Int(0), forKey: AppStoreReviewManager.APP_TRANSACTIONS_COUNT)
        UserDefaults.standard.synchronize()
    }
}
