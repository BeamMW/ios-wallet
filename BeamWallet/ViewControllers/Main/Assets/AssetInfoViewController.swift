//
// AssetInfoViewController.swift
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


class AssetInfoViewController: BaseTableViewController {
    
    init(asset: BMAsset) {
        super.init(nibName: nil, bundle: nil)
        
        self.asset = asset
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError(Localizable.shared.strings.fatalInitCoderError)
    }
    
    private let statusViewModel = StatusViewModel()
    private let assetViewModel = AssetViewModel()
    
    private var asset:BMAsset!

    private var addWidth:CGFloat = 0
    private var currentIndex:Int = 0
    
    private let pagingViewController = BMPagingViewController()
    
    private let titles = [Localizable.shared.strings.balance, Localizable.shared.strings.asset_info]
    
    private var controllers: [Int : Any] = [:]
        
    override func viewDidLoad() {
        super.viewDidLoad()
        
        statusViewModel.assetId = Int(asset.assetId)
        
        var allSize:CGFloat = 0
        for title in titles {
            let size = title.boundingWidth(with: pagingViewController.options.font, kern: 1.5)
            allSize = allSize + (size + 20)
        }
        
        if allSize < UIScreen.main.bounds.width {
            if Device.screenType == .iPhones_6 {
                addWidth = 10
            }
            else{
                addWidth = ((UIScreen.main.bounds.width - allSize)/4) - (8)
                if addWidth < 0 {
                    addWidth = 10
                }
            }
        }
        
        addChild(pagingViewController)
        view.addSubview(pagingViewController.view)
        pagingViewController.didMove(toParent: self)
        
        pagingViewController.dataSource = self
        pagingViewController.delegate = self
        
        setGradientTopBar(mainColor: UIColor.main.peacockBlue, addedStatusView: true)
        if !asset.isBeam() {
            title = asset.unitName.uppercased()
        }
        else {
            title = Localizable.shared.strings.beam_2.uppercased()
        }
        
        
        subscribeToUpdates()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
                
        pagingViewController.view.frame = CGRect(x: 0, y: self.statusView.frame.size.height + self.statusView.frame.origin.y + 10, width: view.width, height: self.view.frame.size.height - (self.statusView.frame.size.height + self.statusView.frame.origin.y + 10))
    }
    
    private func subscribeToUpdates() {
        statusViewModel.onRatesChange = { [weak self] in
            guard let strongSelf = self else { return }
            UIView.performWithoutAnimation {
                strongSelf.reloadData()
            }
        }
        
        statusViewModel.onDataChanged = { [weak self] in
            guard let strongSelf = self else { return }
            UIView.performWithoutAnimation {
                strongSelf.asset = AssetsManager.shared().getAsset(Int32(strongSelf.asset.assetId))
                strongSelf.reloadData()
            }
        }
        
        assetViewModel.onDataChanged = { [weak self] in
            guard let strongSelf = self else { return }
            UIView.performWithoutAnimation {
                strongSelf.asset = AssetsManager.shared().getAsset(Int32(strongSelf.asset.assetId))
                strongSelf.reloadData()
            }
        }
    }
    
    private func reloadData() {
        for vc in controllers.keys {
            if let controller = controllers[vc] as? AssetBalanceViewController {
                controller.reloadData(asset:self.asset, items: self.assetViewModel.getAssetBalanceInfo(asset: self.asset))
            }
        }
    }
}

extension AssetInfoViewController: PagingViewControllerDataSource {
    
    func pagingViewController<T>(_ pagingViewController: PagingViewController<T>, viewControllerForIndex index: Int) -> UIViewController {
        
        if controllers[index] == nil {
            if index == 0 {
                let viewController = AssetBalanceViewController()
                viewController.asset = self.asset
                viewController.view.backgroundColor = UIColor.clear
                viewController.reloadData(asset:self.asset, items: self.assetViewModel.getAssetBalanceInfo(asset: self.asset))
                
                controllers[index] = viewController
                
                return viewController
            }
            else {
                let viewController = AssetDescViewController()
                viewController.asset = self.asset
                viewController.view.backgroundColor = UIColor.clear
                viewController.reloadData(asset:self.asset, items: self.assetViewModel.getAssetInfo(asset: self.asset))
                
                controllers[index] = viewController
                
                return viewController
            }
        }
        
        return controllers[index]! as! UIViewController
    }
    
    func pagingViewController<T>(_ pagingViewController: PagingViewController<T>, pagingItemForIndex index: Int) -> T {
        return PagingIndexItem(index: index, title: titles[index].uppercased()) as! T
    }
    
    func numberOfViewControllers<T>(in: PagingViewController<T>) -> Int{
        return titles.count
    }
}

extension AssetInfoViewController : PagingViewControllerDelegate {
    
    func pagingViewController<T>(
        _ pagingViewController: PagingViewController<T>,
        widthForPagingItem pagingItem: T,
        isSelected: Bool) -> CGFloat? {
        
        let index = pagingItem as! PagingIndexItem
        let title = index.title
        let size = title.boundingWidth(with: pagingViewController.options.font, kern: 1.5)
        return (size + 20 + addWidth)
    }
    
    func pagingViewController<T>(_ pagingViewController: PagingViewController<T>, didScrollToItem pagingItem: T, startingViewController: UIViewController?, destinationViewController: UIViewController, transitionSuccessful: Bool) where T : PagingItem, T : Comparable, T : Hashable {
        
        let index = pagingItem as! PagingIndexItem
        currentIndex = index.index
    }
}
