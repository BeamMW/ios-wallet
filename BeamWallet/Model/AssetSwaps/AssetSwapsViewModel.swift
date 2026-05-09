//
// AssetSwapsViewModel.swift
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

enum AssetSwapsTab: Int {
    case open = 0
    case mine = 1
    case history = 2
}

class AssetSwapsViewModel: NSObject {

    public var onDataChanged: (() -> Void)?
    public var selectedTab: AssetSwapsTab = .open

    private var allOrders: [BMDexOrder] {
        return AppModel.sharedManager().dexOrders as? [BMDexOrder] ?? []
    }

    public var ordersForActiveTab: [BMDexOrder] {
        switch selectedTab {
        case .open:
            return allOrders.filter { !$0.isMine && $0.isActive() }
        case .mine:
            return allOrders.filter { $0.isMine && $0.isActive() }
        case .history:
            return allOrders.filter { !$0.isActive() }
                .sorted { $0.createTimestamp > $1.createTimestamp }
        }
    }

    override init() {
        super.init()
        AppModel.sharedManager().addDelegate(self)
        AppModel.sharedManager().requestDexOrders()
    }

    deinit {
        AppModel.sharedManager().removeDelegate(self)
    }

    func reload() {
        AppModel.sharedManager().requestDexOrders()
    }
}

extension AssetSwapsViewModel: WalletModelDelegate {
    func onDexOrdersChanged(_ orders: [BMDexOrder]) {
        DispatchQueue.main.async { [weak self] in
            self?.onDataChanged?()
        }
    }
}
