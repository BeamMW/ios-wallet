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
        self.assets = self.assets.filter({ a in
            a.shortName != nil
        })
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
    
    public func getAssetInfo(asset:BMAsset) -> [BMThreeLineItem] {
        var result = [BMThreeLineItem]()
        
        let name = BMThreeLineItem(title: Localizable.shared.strings.small_unit_unit.uppercased(), detail: asset.nthUnitName, subDetail: "", titleColor: UIColor.white, detailColor: UIColor.white, subDetailColor: UIColor.white.withAlphaComponent(0.7), titleFont: BoldFont(size: 14), detailFont: RegularFont(size: 14), subDetailFont: RegularFont(size: 14), hasArrow: false)
        result.append(name)
        
        if !asset.shortDesc.isEmpty {
            let shortDesc = BMThreeLineItem(title: Localizable.shared.strings.short_desc.uppercased(), detail: asset.shortDesc, subDetail: "", titleColor: UIColor.white, detailColor: UIColor.white, subDetailColor: UIColor.white.withAlphaComponent(0.7), titleFont: BoldFont(size: 14), detailFont: RegularFont(size: 14), subDetailFont: RegularFont(size: 14), hasArrow: false)
            result.append(shortDesc)
        }

        if !asset.longDesc.isEmpty {
            let longDesc = BMThreeLineItem(title: Localizable.shared.strings.long_desc.uppercased(), detail: asset.longDesc, subDetail: "", titleColor: UIColor.white, detailColor: UIColor.white, subDetailColor: UIColor.white.withAlphaComponent(0.7), titleFont: BoldFont(size: 14), detailFont: RegularFont(size: 14), subDetailFont: RegularFont(size: 14), hasArrow: false)
            result.append(longDesc)
        }
        
        return result
    }

    public func getAssetBalanceInfo(asset:BMAsset)-> [[BMThreeLineItem]] {
        var result = [[BMThreeLineItem]]()
        
        var section_1 = [BMThreeLineItem]()
        var section_2 = [BMThreeLineItem]()

        let available = BMThreeLineItem(title: Localizable.shared.strings.available.uppercased(), detail: asset.isBeam() ? String.currency(value: asset.realAmount) : String.currency(value: asset.realAmount, name: asset.unitName), subDetail: ExchangeManager.shared().exchangeValueAsset(asset.realAmount, assetID: asset.assetId), titleColor: UIColor.white, detailColor: UIColor.white, subDetailColor: UIColor.white.withAlphaComponent(0.7), titleFont: BoldFont(size: 14), detailFont: RegularFont(size: 14), subDetailFont: RegularFont(size: 14), hasArrow: false)
        
        let regular = BMThreeLineItem(title: Localizable.shared.strings.regular.uppercased(), detail: asset.isBeam() ? String.currency(value: asset.realAmount - asset.realShielded) : String.currency(value: asset.realAmount - asset.realShielded, name: asset.unitName), subDetail: ExchangeManager.shared().exchangeValueAsset(asset.realAmount - asset.realShielded, assetID: asset.assetId), titleColor: UIColor.white, detailColor: UIColor.white, subDetailColor: UIColor.white.withAlphaComponent(0.7), titleFont: BoldFont(size: 14), detailFont: RegularFont(size: 14), subDetailFont: RegularFont(size: 14), hasArrow: false)
        
        let shielded = BMThreeLineItem(title: Localizable.shared.strings.max_privacy.uppercased(), detail: asset.isBeam() ? String.currency(value: asset.realShielded) : String.currency(value: asset.realShielded, name: asset.unitName), subDetail: ExchangeManager.shared().exchangeValueAsset(asset.realShielded, assetID: asset.assetId), titleColor: UIColor.white, detailColor: UIColor.white, subDetailColor: UIColor.white.withAlphaComponent(0.7), titleFont: BoldFont(size: 14), detailFont: RegularFont(size: 14), subDetailFont: RegularFont(size: 14), hasArrow: false)
        
        let empty = BMThreeLineItem(title: "", detail: "", subDetail: "", titleColor: .clear, detailColor: .clear, subDetailColor: .cyan, titleFont: UIFont.systemFont(ofSize: 0), detailFont: UIFont.systemFont(ofSize: 0), subDetailFont: UIFont.systemFont(ofSize: 0), hasArrow: false)
        
        section_1.append(empty)
        section_1.append(available)
        section_1.append(regular)
        section_1.append(shielded)


        let lockedBalance = asset.realMaxPrivacy + asset.realMaturing + asset.realSending + asset.realReceiving
        let changeBalance = asset.realSending + asset.realReceiving

        let locked = BMThreeLineItem(title: Localizable.shared.strings.locked.uppercased(), detail: asset.isBeam() ? String.currency(value: lockedBalance) : String.currency(value: lockedBalance, name: asset.unitName), subDetail: ExchangeManager.shared().exchangeValueAsset(lockedBalance, assetID: asset.assetId), titleColor: UIColor.white, detailColor: UIColor.white, subDetailColor: UIColor.white.withAlphaComponent(0.7), titleFont: BoldFont(size: 14), detailFont: RegularFont(size: 14), subDetailFont: RegularFont(size: 14), hasArrow: true)
        
        let maturing = BMThreeLineItem(title: Localizable.shared.strings.maturing.uppercased(), detail: asset.isBeam() ? String.currency(value: asset.realMaturing) : String.currency(value: asset.realMaturing, name: asset.unitName), subDetail: ExchangeManager.shared().exchangeValueAsset(asset.realMaturing, assetID: asset.assetId), titleColor: UIColor.white.withAlphaComponent(0.5), detailColor: UIColor.white, subDetailColor: UIColor.white.withAlphaComponent(0.7), titleFont: BoldFont(size: 14), detailFont: RegularFont(size: 14), subDetailFont: RegularFont(size: 14), hasArrow: false)
        
        let change = BMThreeLineItem(title: Localizable.shared.strings.change.uppercased(), detail: asset.isBeam() ? String.currency(value: changeBalance) : String.currency(value: changeBalance, name: asset.unitName), subDetail: ExchangeManager.shared().exchangeValueAsset(changeBalance, assetID: asset.assetId), titleColor: UIColor.white.withAlphaComponent(0.5), detailColor: UIColor.white, subDetailColor: UIColor.white.withAlphaComponent(0.7), titleFont: BoldFont(size: 14), detailFont: RegularFont(size: 14), subDetailFont: RegularFont(size: 14), hasArrow: false)
        
        var maxPrivacy = BMThreeLineItem(title: Localizable.shared.strings.max_privacy.uppercased(), detail: asset.isBeam() ? String.currency(value: asset.realMaxPrivacy) : String.currency(value: asset.realMaxPrivacy, name: asset.unitName), subDetail: ExchangeManager.shared().exchangeValueAsset(asset.realMaxPrivacy, assetID: asset.assetId), titleColor: UIColor.white.withAlphaComponent(0.5), detailColor: UIColor.white, subDetailColor: UIColor.white.withAlphaComponent(0.7), titleFont: BoldFont(size: 14), detailFont: RegularFont(size: 14), subDetailFont: RegularFont(size: 14), hasArrow: false)
        
        if asset.realMaxPrivacy > 0 {
            maxPrivacy.accessoryName = Localizable.shared.strings.more_details.lowercased()
        }
        
        section_2.append(locked)
        section_2.append(maturing)
        section_2.append(change)
        section_2.append(maxPrivacy)

        result.append(section_1)
        result.append(section_2)

        return result
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
    
    func onWalletStatusChange(_ status: BMWalletStatus) {
        DispatchQueue.main.async {
            self.sort()
            self.onDataChanged?()
        }
    }
}

