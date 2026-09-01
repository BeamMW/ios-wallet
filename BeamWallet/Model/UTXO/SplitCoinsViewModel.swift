//
// SplitCoinsViewModel.swift
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

import Foundation

final class SplitCoinsViewModel: NSObject {

    enum Mode {
        case split
        case consolidate
    }

    let group: AssetUTXOGroup
    let mode: Mode
    let allowedSplitCounts: [Int] = [2, 3, 5, 8, 10]

    var splitInto: Int {
        didSet {
            if splitInto != oldValue {
                recalculateFee()
                onDataChanged?()
            }
        }
    }

    private(set) var feeGroth: UInt64 = 0

    // When on, the operation is routed through a Lelantus push tx to a
    // self-generated offline address instead of splitting/consolidating in
    // the public pool — breaking input/output linkability and growing the
    // shielded anonymity set.
    var sendOffline: Bool = false {
        didSet {
            if sendOffline != oldValue {
                recalculateFee()
                onDataChanged?()
            }
        }
    }

    var onDataChanged: (() -> Void)?
    var onError: ((String) -> Void)?
    var onSubmitted: (() -> Void)?

    init(group: AssetUTXOGroup, mode: Mode = .split) {
        self.group = group
        self.mode = mode
        let suggested = SplitCoinsViewModel.suggestedSplitCount(for: group, allowed: [2, 3, 5, 8, 10])
        self.splitInto = (mode == .consolidate) ? 1 : (group.isConcentrated ? suggested : 3)
        super.init()
        feeGroth = UInt64(AppModel.sharedManager().getDefaultFeeInGroth())
    }

    // Lelantus push: applies to both modes. In split-offline the largest
    // UTXO is pushed into the shielded pool; in consolidate-offline the
    // entire available pool is pushed. Either way the on-chain result is a
    // single shielded output, so the split-into selector is meaningless.
    var isShielded: Bool { sendOffline }

    var assetId: Int32 { group.assetId }
    var largestGroth: UInt64 { group.largestUtxo?.amount ?? 0 }

    // The pool we're rebalancing: largest UTXO for split, total available for
    // consolidate (coin-selection picks the actual inputs in either case).
    private var sourceGroth: UInt64 {
        mode == .consolidate ? group.totalAvailableGroth : largestGroth
    }

    var outputAmounts: [UInt64] {
        guard sourceGroth > 0 else { return [] }

        // Shielded path is the same shape regardless of mode: a single
        // shielded output equal to the source minus the BEAM fee (or the
        // full source for non-BEAM assets, where the fee is paid separately).
        if isShielded {
            if assetId == 0 {
                guard sourceGroth > feeGroth else { return [] }
                return [sourceGroth - feeGroth]
            }
            return [sourceGroth]
        }

        switch mode {
        case .consolidate:
            guard group.utxos.count >= 2 else { return [] }
            if assetId == 0 {
                guard sourceGroth > feeGroth else { return [] }
                return [sourceGroth - feeGroth]
            }
            return [sourceGroth]

        case .split:
            guard splitInto > 0 else { return [] }
            let count = UInt64(splitInto)
            let base = sourceGroth / count
            let remainder = sourceGroth - base * count
            var arr = Array(repeating: base, count: splitInto)
            if !arr.isEmpty {
                arr[arr.count - 1] += remainder
            }
            // For BEAM (assetId == 0) the fee is paid in BEAM from the same UTXO
            // we are splitting. If we keep the slices summing to sourceGroth the
            // wallet has no headroom for the fee; coin-selection then silently
            // fails. Subtract the fee from the last slice. Caller is gated on
            // validationError, which already guards `sourceGroth > feeGroth`, so
            // the subtraction is safe; the > 0 guard is belt-and-braces.
            if assetId == 0 && !arr.isEmpty && feeGroth > 0 {
                let last = arr[arr.count - 1]
                guard last > feeGroth else { return [] }
                arr[arr.count - 1] = last - feeGroth
            }
            return arr
        }
    }

    var perOutputGroth: UInt64 { outputAmounts.first ?? 0 }

    var concentrationWarning: String? {
        guard mode == .split, !isShielded, group.isConcentrated else { return nil }
        let percent = Int((group.concentrationRatio * 100).rounded())
        let suggested = SplitCoinsViewModel.suggestedSplitCount(for: group, allowed: allowedSplitCounts)
        return Localizable.shared.strings.split_concentration_warning_format
            .replacingOccurrences(of: "(percent)", with: "\(percent)")
            .replacingOccurrences(of: "(count)", with: "\(suggested)")
    }

    var validationError: String? {
        if isShielded {
            if assetId == 0 && sourceGroth <= feeGroth {
                return Localizable.shared.strings.asset_swap_insufficient_funds
            }
            return nil
        }
        if mode == .consolidate {
            if group.utxos.count < 2 { return "" }
            if assetId == 0 && sourceGroth <= feeGroth {
                return Localizable.shared.strings.asset_swap_insufficient_funds
            }
            return nil
        }
        if sourceGroth < UInt64(splitInto) {
            return Localizable.shared.strings.split_too_small
        }
        if assetId == 0 && sourceGroth <= feeGroth {
            return Localizable.shared.strings.asset_swap_insufficient_funds
        }
        // For BEAM the fee comes off the last slice (see outputAmounts); if
        // the per-split base + remainder doesn't leave room for the fee, the
        // resulting tx would be invalid.
        if assetId == 0 && splitInto > 0 {
            let count = UInt64(splitInto)
            let base = sourceGroth / count
            let remainder = sourceGroth - base * count
            if base + remainder <= feeGroth {
                return Localizable.shared.strings.asset_swap_insufficient_funds
            }
        }
        return nil
    }

    var canSubmit: Bool {
        guard validationError == nil, sourceGroth > 0 else { return false }
        return mode == .consolidate ? group.utxos.count >= 2 : group.canSplit
    }

    func recalculateFee() {
        let realAmount = Double(sourceGroth) / 100_000_000
        let app = AppModel.sharedManager()
        let defaultFee = isShielded
            ? Double(app.getMinMaxPrivacyFeeInGroth())
            : Double(app.getDefaultFeeInGroth())
        app.calculateFee(
            realAmount,
            assetId: assetId,
            fee: defaultFee,
            isShielded: isShielded
        ) { [weak self] fee, _, _, _ in
            DispatchQueue.main.async {
                guard let self = self else { return }
                self.feeGroth = fee
                self.onDataChanged?()
            }
        }
    }

    func submit() {
        guard canSubmit else {
            onError?(validationError ?? "")
            return
        }
        if isShielded {
            submitShielded()
            return
        }
        let groths = outputAmounts.map { NSNumber(value: $0) }
        AppModel.sharedManager().splitCoins(
            assetId,
            outputGroths: groths,
            fee: Double(feeGroth)
        )
        onSubmitted?()
    }

    private func submitShielded() {
        let outGroth = perOutputGroth
        guard outGroth > 0 else {
            onError?(validationError ?? Localizable.shared.strings.error)
            return
        }
        let realAmount = Double(outGroth) / 100_000_000
        let assetIdCopy = assetId
        let feeReal = Double(feeGroth)

        // Reuse the wallet's default own address (created on demand by
        // generateToken / getDefaultAddressAlways). `_id` is the hex WalletID
        // that generateOfflineAddress expects; the public `walletId` getter
        // returns the token string and would fail FromHex parsing.
        AppModel.sharedManager().generateNewWalletAddress { [weak self] address, _ in
            DispatchQueue.main.async {
                guard let self = self,
                      let walletIdHex = address?._id, !walletIdHex.isEmpty else {
                    self?.onError?(Localizable.shared.strings.error)
                    return
                }
                AppModel.sharedManager().generateOfflineAddress(
                    walletIdHex,
                    assetId: assetIdCopy,
                    amount: realAmount,
                    offlineCount: 1
                ) { token in
                    DispatchQueue.main.async {
                        guard !token.isEmpty else {
                            self.onError?(Localizable.shared.strings.error)
                            return
                        }
                        AppModel.sharedManager().send(
                            realAmount,
                            fee: feeReal,
                            assetId: assetIdCopy,
                            to: token,
                            from: walletIdHex,
                            comment: "",
                            isOffline: true
                        )
                        self.onSubmitted?()
                    }
                }
            }
        }
    }

    private static func suggestedSplitCount(for group: AssetUTXOGroup, allowed: [Int]) -> Int {
        guard group.totalAvailableGroth > 0 else { return allowed.first ?? 2 }
        let ratio = group.concentrationRatio
        let target = max(2, Int((ratio / 0.3).rounded(.up)))
        return allowed.last(where: { $0 <= target }) ?? allowed.last ?? 5
    }
}
