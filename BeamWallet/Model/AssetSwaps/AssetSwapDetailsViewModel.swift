//
// AssetSwapDetailsViewModel.swift
// BeamWallet
//
// Copyright 2026 Beam Development
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

class AssetSwapDetailsViewModel: NSObject {

    public let order: BMDexOrder

    init(order: BMDexOrder) {
        self.order = order
        super.init()
    }

    public var canCancel: Bool {
        return order.isMine && order.isActive()
    }

    public var canAccept: Bool {
        return !order.isMine && order.isActive()
    }

    public var sendAsset: BMAsset? {
        return AssetsManager.shared().getAsset(Int32(order.sendAssetId))
    }

    public var receiveAsset: BMAsset? {
        return AssetsManager.shared().getAsset(Int32(order.receiveAssetId))
    }

    public var statusColor: UIColor {
        if order.isExpired() {
            return UIColor.main.red
        }
        if order.isCompleted || order.isCanceled {
            return UIColor.main.steelGrey
        }
        return UIColor.main.brightTeal
    }

    public var isExpiringSoon: Bool {
        guard order.isActive() else { return false }
        let now = UInt64(Date().timeIntervalSince1970)
        guard order.expireTimestamp > now else { return false }
        return order.expireTimestamp - now < 3600
    }

    public var validationError: String? {
        guard canAccept else { return nil }
        guard let sendAsset = AssetsManager.shared().getAsset(Int32(order.sendAssetId)) else {
            return Localizable.shared.strings.asset_swap_insufficient_funds
        }
        if sendAsset.available < order.sendAmount {
            return Localizable.shared.strings.asset_swap_insufficient_funds
        }
        return nil
    }

    public func cancel() {
        AppModel.sharedManager().cancelDexOrder(withID: order.orderID)
    }

    public func accept() -> Bool {
        return AppModel.sharedManager().acceptDexOrder(order)
    }
}
