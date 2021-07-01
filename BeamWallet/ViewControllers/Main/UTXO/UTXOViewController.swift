//
// UTXOViewController.swift
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


class UTXOViewController: BaseTableViewController {
    
    private let pagingViewController = BMPagingViewController()

    private var titles = [Localizable.shared.strings.available, Localizable.shared.strings.in_progress, Localizable.shared.strings.spent, Localizable.shared.strings.unavailable]
    
    private let emptyView: BMEmptyView = UIView.fromNib()
    private let blockView: UTXOBlockView = UIView.fromNib()
    private let hideUTXOView: BMEmptyView = UIView.fromNib()

    private var _selectedIndex = 0
    public var selectedIndex:Int {
        get{
            return _selectedIndex
        }
        set{
           _selectedIndex = newValue
        }
    }
    
  
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        Settings.sharedManager().addDelegate(self)
        
        hideUTXOView.text = Localizable.shared.strings.secutiry_utxo
        hideUTXOView.image = IconUTXOSecurity()
        
        emptyView.text = Localizable.shared.strings.utxo_empty
        emptyView.image = IconUtxoEmpty()
        
        blockView.configure(with: AppModel.sharedManager().walletStatus)
        
        let pagingView = pagingViewController.view as! PagingView
        pagingView.options.menuItemSpacing = 20

        addChild(pagingViewController)
        view.addSubview(pagingViewController.view)
        pagingViewController.didMove(toParent: self)
        
        pagingViewController.dataSource = self
        pagingViewController.delegate = self

        emptyView.isHidden = true
        emptyView.backgroundColor = view.backgroundColor
        view.addSubview(emptyView)
        
        hideUTXOView.isHidden = !Settings.sharedManager().isHideAmounts
        hideUTXOView.backgroundColor = view.backgroundColor
        view.addSubview(hideUTXOView)
        
        setGradientTopBar(mainColor: UIColor.main.peacockBlue, addedStatusView: true)
        
        view.insertSubview(blockView, belowSubview: pagingViewController.view)
        
        title = Localizable.shared.strings.utxo

        rightButton()
    }
    
    deinit {
        Settings.sharedManager().removeDelegate(self)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        checkIsEmpty()
        
        AppModel.sharedManager().addDelegate(self)
        AppModel.sharedManager().getUTXO()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        AppModel.sharedManager().removeDelegate(self)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        blockView.frame = CGRect(x: 15, y: tableView.y + 15, width: UIScreen.main.bounds.width - 30, height: 82)
        
        var frame = tableView.frame
        frame.origin.y = frame.origin.y + 130
        frame.size.height = frame.size.height - 130
        
        pagingViewController.view.frame = frame
        emptyView.frame = frame
        hideUTXOView.frame = frame
    }
    
    private func checkIsEmpty() {
        var allUtxos = [BMUTXO]()
        
        if let utxos = AppModel.sharedManager().utxos {
            allUtxos.append(contentsOf: utxos as! [BMUTXO])
        }
        
        if let utxos = AppModel.sharedManager().shildedUtxos {
            allUtxos.append(contentsOf: utxos as! [BMUTXO])
        }
        
        let count = allUtxos.count

        if count == 0 {
            pagingViewController.view.alpha = 0
            emptyView.isHidden = false
        }
        else{
            pagingViewController.view.alpha = 1
            emptyView.isHidden = true
        }
    }
    
    private func rightButton() {
        addRightButton(image: Settings.sharedManager().isHideAmounts ? IconShowBalance() : IconHideBalance(), target: self, selector: #selector(onHideAmounts))
    }
    
    private func menuOffset(for scrollView: UIScrollView) -> CGFloat {
        return min(pagingViewController.options.menuHeight + blockView.h + blockView.y, max(0, scrollView.contentOffset.y))
    }
}


extension UTXOViewController: PagingViewControllerDataSource {
    
    func pagingViewController<T>(_ pagingViewController: PagingViewController<T>, viewControllerForIndex index: Int) -> UIViewController {
        
        let viewController = UTXOTableView()
        viewController.view.backgroundColor = UIColor.clear
        viewController.selectedIndex = index
        
        return viewController
    }
    
    func pagingViewController<T>(_ pagingViewController: PagingViewController<T>, pagingItemForIndex index: Int) -> T {
        return PagingIndexItem(index: index, title: titles[index].uppercased()) as! T
    }
    
    func numberOfViewControllers<T>(in: PagingViewController<T>) -> Int{
        return titles.count
    }
}

extension UTXOViewController : PagingViewControllerDelegate {
    func pagingViewController<T>(_ pagingViewController: PagingViewController<T>, didScrollToItem pagingItem: T, startingViewController: UIViewController?, destinationViewController: UIViewController, transitionSuccessful: Bool) where T : PagingItem, T : Comparable, T : Hashable {

        let index = pagingItem as! PagingIndexItem
        selectedIndex = index.index
    }
    
    func pagingViewController<T>(
        _ pagingViewController: PagingViewController<T>,
        widthForPagingItem pagingItem: T,
        isSelected: Bool) -> CGFloat? {
        
        let index = pagingItem as! PagingIndexItem
        let title = index.title
        let size = title.boundingWidth(with: pagingViewController.options.font, kern: 1.5)
        return size + 20
    }
}

extension UTXOViewController : SettingsModelDelegate {
    func onChangeHideAmounts() {
        rightButton()
        
        hideUTXOView.isHidden = !Settings.sharedManager().isHideAmounts
        tableView.isUserInteractionEnabled = !Settings.sharedManager().isHideAmounts
        tableView.reloadData()
    }
}

extension UTXOViewController : WalletModelDelegate {
    
    func onWalletStatusChange(_ status: BMWalletStatus) {
        DispatchQueue.main.async {
            self.blockView.configure(with: AppModel.sharedManager().walletStatus)
        }
    }
    
    func onReceivedUTXOs(_ utxos: [BMUTXO]) {
        DispatchQueue.main.async {
            self.checkIsEmpty()
        }
    }
}

