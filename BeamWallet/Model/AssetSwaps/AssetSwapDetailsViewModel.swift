//
// AssetSwapDetailsViewModel.swift
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

    public func cancel() {
        AppModel.sharedManager().cancelDexOrder(withID: order.orderID)
    }

    public func accept() -> Bool {
        return AppModel.sharedManager().acceptDexOrder(order)
    }
}
