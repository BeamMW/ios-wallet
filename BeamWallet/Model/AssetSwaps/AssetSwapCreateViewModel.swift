//
// AssetSwapCreateViewModel.swift
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

class AssetSwapCreateViewModel: NSObject {

    public var sendAsset: BMAsset?
    public var receiveAsset: BMAsset?
    public var sendAmountString: String = ""
    public var receiveAmountString: String = ""
    public var expirationMinutes: UInt32 = 720 // 12 hours — SBBS message TTL cap

    public var onDataChanged: (() -> Void)?

    override init() {
        super.init()
        AppModel.sharedManager().loadFullAssetsList()
    }

    public var validationError: String? {
        guard let send = sendAsset else {
            return Localizable.shared.strings.asset_swap_pick_send_asset
        }
        guard let receive = receiveAsset else {
            return Localizable.shared.strings.asset_swap_pick_receive_asset
        }
        if send.assetId == receive.assetId {
            return Localizable.shared.strings.asset_swap_same_asset_error
        }
        let sendGroth = grothFrom(sendAmountString)
        let receiveGroth = grothFrom(receiveAmountString)
        if sendGroth == 0 || receiveGroth == 0 {
            return Localizable.shared.strings.amount_zero
        }
        if sendGroth > send.available {
            return Localizable.shared.strings.asset_swap_insufficient_funds
        }
        return nil
    }

    public var canSubmit: Bool {
        return validationError == nil
    }

    public func displayRate() -> String {
        let s = grothFrom(sendAmountString)
        let r = grothFrom(receiveAmountString)
        guard s > 0, r > 0,
              let sendName = sendAsset?.unitName, sendName.count > 0,
              let receiveName = receiveAsset?.unitName, receiveName.count > 0 else {
            return "—"
        }
        let rate = Double(r) / Double(s)
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 8
        let rateString = formatter.string(from: NSNumber(value: rate)) ?? "0"
        return "1 \(sendName) = \(rateString) \(receiveName)"
    }

    public func submit() -> Bool {
        guard canSubmit, let send = sendAsset, let receive = receiveAsset else {
            return false
        }
        return AppModel.sharedManager().publishDexOrder(
            withSendAsset: UInt32(send.assetId),
            sendAmount: grothFrom(sendAmountString),
            receiveAsset: UInt32(receive.assetId),
            receiveAmount: grothFrom(receiveAmountString),
            expirationMinutes: expirationMinutes)
    }

    private func grothFrom(_ string: String) -> UInt64 {
        let normalized = string.replacingOccurrences(of: ",", with: ".")
        guard let beam = Double(normalized), beam > 0 else { return 0 }
        return UInt64(beam * 100_000_000.0)
    }
}
