//
// StatusViewModel.swift
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

class StatusViewModel: NSObject {

    public var onDataChanged : (() -> Void)?

    override init() {
        super.init()
        
        AppModel.sharedManager().addDelegate(self)
    }
    
    deinit {
        AppModel.sharedManager().removeDelegate(self)
    }
    
    public func onReceive() {
        let vc = ReceiveViewController()
        UIApplication.getTopMostViewController()?.pushViewController(vc: vc)
    }
    
    public func onSend() {
        let vc = SendViewController()
        vc.hidesBottomBarWhenPushed = true
        UIApplication.getTopMostViewController()?.pushViewController(vc: vc)
    }
}

extension StatusViewModel: WalletModelDelegate {
    
    func onWalletStatusChange(_ status: BMWalletStatus) {
        DispatchQueue.main.async {
            self.onDataChanged?()
        }
    }
}
