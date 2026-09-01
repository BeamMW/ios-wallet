//
// AssetUTXOGroup.swift
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

struct AssetUTXOGroup {
    let asset: BMAsset
    let utxos: [BMUTXO]
    let largestUtxo: BMUTXO?
    let totalAvailableGroth: UInt64

    var assetId: Int32 { Int32(asset.assetId) }

    var concentrationRatio: Double {
        guard totalAvailableGroth > 0, let largest = largestUtxo else { return 0 }
        return Double(largest.amount) / Double(totalAvailableGroth)
    }

    var isConcentrated: Bool { concentrationRatio > 0.7 }

    var canSplit: Bool { (largestUtxo?.amount ?? 0) >= 2 }

    static func make(asset: BMAsset, utxos: [BMUTXO]) -> AssetUTXOGroup {
        let sorted = utxos.sorted { $0.amount > $1.amount }
        let total = sorted.reduce(UInt64(0)) { $0 + $1.amount }
        return AssetUTXOGroup(
            asset: asset,
            utxos: sorted,
            largestUtxo: sorted.first,
            totalAvailableGroth: total
        )
    }
}
