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

    let group: AssetUTXOGroup
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

    var onDataChanged: (() -> Void)?
    var onError: ((String) -> Void)?
    var onSubmitted: (() -> Void)?

    init(group: AssetUTXOGroup) {
        self.group = group
        let suggested = SplitCoinsViewModel.suggestedSplitCount(for: group, allowed: [2, 3, 5, 8, 10])
        self.splitInto = group.isConcentrated ? suggested : 3
        super.init()
        feeGroth = UInt64(AppModel.sharedManager().getDefaultFeeInGroth())
    }

    var assetId: Int32 { group.assetId }
    var largestGroth: UInt64 { group.largestUtxo?.amount ?? 0 }

    var outputAmounts: [UInt64] {
        guard splitInto > 0, largestGroth > 0 else { return [] }
        let count = UInt64(splitInto)
        let base = largestGroth / count
        let remainder = largestGroth - base * count
        var arr = Array(repeating: base, count: splitInto)
        if !arr.isEmpty {
            arr[arr.count - 1] += remainder
        }
        // For BEAM (assetId == 0) the fee is paid in BEAM from the same UTXO
        // we are splitting. If we keep the slices summing to largestGroth the
        // wallet has no headroom for the fee; coin-selection then silently
        // fails. Subtract the fee from the last slice. Caller is gated on
        // validationError, which already guards `largestGroth > feeGroth`, so
        // the subtraction is safe; the > 0 guard is belt-and-braces.
        if assetId == 0 && !arr.isEmpty && feeGroth > 0 {
            let last = arr[arr.count - 1]
            guard last > feeGroth else { return [] }
            arr[arr.count - 1] = last - feeGroth
        }
        return arr
    }

    var perOutputGroth: UInt64 { outputAmounts.first ?? 0 }

    var concentrationWarning: String? {
        guard group.isConcentrated else { return nil }
        let percent = Int((group.concentrationRatio * 100).rounded())
        let suggested = SplitCoinsViewModel.suggestedSplitCount(for: group, allowed: allowedSplitCounts)
        return Localizable.shared.strings.split_concentration_warning_format
            .replacingOccurrences(of: "(percent)", with: "\(percent)")
            .replacingOccurrences(of: "(count)", with: "\(suggested)")
    }

    var validationError: String? {
        if largestGroth < UInt64(splitInto) {
            return Localizable.shared.strings.split_too_small
        }
        if assetId == 0 && largestGroth <= feeGroth {
            return Localizable.shared.strings.asset_swap_insufficient_funds
        }
        // For BEAM the fee comes off the last slice (see outputAmounts); if
        // the per-split base + remainder doesn't leave room for the fee, the
        // resulting tx would be invalid.
        if assetId == 0 && splitInto > 0 {
            let count = UInt64(splitInto)
            let base = largestGroth / count
            let remainder = largestGroth - base * count
            if base + remainder <= feeGroth {
                return Localizable.shared.strings.asset_swap_insufficient_funds
            }
        }
        return nil
    }

    var canSubmit: Bool {
        validationError == nil && largestGroth > 0 && group.canSplit
    }

    func recalculateFee() {
        let realAmount = Double(largestGroth) / 100_000_000
        let defaultFee = Double(AppModel.sharedManager().getDefaultFeeInGroth())
        AppModel.sharedManager().calculateFee(
            realAmount,
            assetId: assetId,
            fee: defaultFee,
            isShielded: false
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
        let groths = outputAmounts.map { NSNumber(value: $0) }
        AppModel.sharedManager().splitCoins(
            assetId,
            outputGroths: groths,
            fee: Double(feeGroth)
        )
        onSubmitted?()
    }

    private static func suggestedSplitCount(for group: AssetUTXOGroup, allowed: [Int]) -> Int {
        guard group.totalAvailableGroth > 0 else { return allowed.first ?? 2 }
        let ratio = group.concentrationRatio
        let target = max(2, Int((ratio / 0.3).rounded(.up)))
        return allowed.last(where: { $0 <= target }) ?? allowed.last ?? 5
    }
}
