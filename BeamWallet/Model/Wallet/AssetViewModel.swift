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
    
    public var onDataChanged : (() -> Void)?
    public var assets = [BMAsset]()
    
    override init() {
        super.init()
        
        self.assets = AssetsManager.shared().assets  as! [BMAsset]
        
        AppModel.sharedManager().addDelegate(self)
    }
    
    deinit {
        AppModel.sharedManager().removeDelegate(self)
    }
}

//MARK: - Delegate

extension AssetViewModel : WalletModelDelegate {
    
    func onAssetInfoChange() {
        DispatchQueue.main.async {
            self.assets = AssetsManager.shared().assets  as! [BMAsset]
            self.onDataChanged?()
        }
    }
}

