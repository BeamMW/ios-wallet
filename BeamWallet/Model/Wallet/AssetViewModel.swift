//
// AssetViewModel.swift
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

import UIKit

class AssetViewModel: NSObject {
    
    enum AssetFilterType: Int {
        case recent_old = 0
        case old_recent = 1
        case amount_large_small = 2
        case amount_small_large = 3
        case amount_usd_small = 4
        case amount_usd_large = 5
    }
    
    public var onDataChanged : (() -> Void)?
    public var assets = [BMAsset]()
    
    public var filtertype = AssetFilterType.recent_old {
        didSet {
            self.sort()
            self.onDataChanged?()
        }
    }
    
    override init() {
        super.init()
        
        sort()
        
        AppModel.sharedManager().addDelegate(self)
    }
    
    deinit {
        AppModel.sharedManager().removeDelegate(self)
    }
    
    public func sort() {
        self.assets = AssetsManager.shared().assets  as! [BMAsset]
        
        switch filtertype {
        case .recent_old:
            self.assets.sort { a1, a2 in
                return a1.dateUsed() > a2.dateUsed()
            }
            break
        case .old_recent:
            self.assets.sort { a1, a2 in
                return a1.dateUsed() < a2.dateUsed()
            }
            break
        case .amount_large_small:
            self.assets.sort { a1, a2 in
                return a1.realAmount > a2.realAmount
            }
            break
        case .amount_small_large:
            self.assets.sort { a1, a2 in
                return a1.realAmount < a2.realAmount
            }
        case .amount_usd_small:
            self.assets.sort { a1, a2 in
                return a1.usd() > a2.usd()
            }
        case .amount_usd_large:
            self.assets.sort { a1, a2 in
                return a1.usd() < a2.usd()
            }
        }
    }
}

//MARK: - Delegate

extension AssetViewModel : WalletModelDelegate {
    
    func onAssetInfoChange() {
        DispatchQueue.main.async {
            self.sort()
            self.onDataChanged?()
        }
    }
}

