//
// TransactionsViewController.swift
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


class TransactionsViewController: BaseTableViewController {
    
    private var addWidth:CGFloat = 0
    private var currentIndex:Int = 0

    private let pagingViewController = BMPagingViewController()
    
    private let titles = [Localizable.shared.strings.all, Localizable.shared.strings.in_progress, Localizable.shared.strings.sent, Localizable.shared.strings.received]
   
    private let viewModels = [TransactionViewModel(state: .all), TransactionViewModel(state: .in_progress), TransactionViewModel(state: .sent), TransactionViewModel(state: .received)]

    private var searchView:BMSearchView!
    private var controllers: [Int : TransactionsTableView] = [:]

    override func viewDidLoad() {
        super.viewDidLoad()
        
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
        
        title = Localizable.shared.strings.transactions
        
        addRightButton(image: MoreIcon(), target: self, selector: #selector(onMore))
        
        searchView = BMSearchView()
        searchView.onSearchTextChanged = {
            [weak self] text in
            
            guard let strongSelf = self else { return }
           
            for model in strongSelf.viewModels {
                model.isSearch = true
                model.searchString = text
                model.search()
            }
        }
        searchView.onCancelSearch = {
            [weak self] in
            guard let strongSelf = self else { return }
           
            for model in strongSelf.viewModels {
                model.isSearch = false
                model.search()
            }
        }
        view.addSubview(searchView)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        searchView.y = tableView.y + 10
        
        pagingViewController.view.frame = CGRect(x: 0, y: searchView.y + searchView.h + 10, width: view.width, height: UIScreen.main.bounds.size.height - (searchView.y + searchView.h + 10))
    }
    
    @objc private func onMore() {
        var items = [BMPopoverMenu.BMPopoverMenuItem]()
        
        if viewModels[currentIndex].transactions.count > 0 {
            items.append(BMPopoverMenu.BMPopoverMenuItem(name: Localizable.shared.strings.export, icon: nil, action: .export_transactions))
        }
        
        items.append(BMPopoverMenu.BMPopoverMenuItem(name: Localizable.shared.strings.payment_proof, icon: nil, action: .payment_proof))

        BMPopoverMenu.show(menuArray: items, done: { (selectedItem) in
            if let item = selectedItem {
                switch (item.action) {
                case .payment_proof:
                    let vc  = PaymentProofDetailViewController(transaction: nil, paymentProof: nil)
                    self.pushViewController(vc: vc)
                    return
                case .export_transactions:
                    self.onExporToCSV()
                    return
                default:
                    return
                }
            }
        }, cancel: {
            
        })
    }
    
    @objc private func onExporToCSV() {
        AppModel.sharedManager().exportTransactions { (data, url) in
            DispatchQueue.main.async {
                let vc = UIActivityViewController(activityItems: [url], applicationActivities: nil)
                vc.excludedActivityTypes = [UIActivity.ActivityType.postToFacebook, UIActivity.ActivityType.assignToContact, UIActivity.ActivityType.copyToPasteboard, UIActivity.ActivityType.print,UIActivity.ActivityType.openInIBooks]
                self.present(vc, animated: true)
            }
        }
    }
}

extension TransactionsViewController: PagingViewControllerDataSource {
    
    func pagingViewController<T>(_ pagingViewController: PagingViewController<T>, viewControllerForIndex index: Int) -> UIViewController {
        
        if controllers[index] == nil {
            let viewController = TransactionsTableView()
            viewController.viewModel = viewModels[index]
            viewController.view.backgroundColor = UIColor.clear
            viewController.index = index

            controllers[index] = viewController
            
            return viewController
        }
        
        return controllers[index]!
    }
    
    func pagingViewController<T>(_ pagingViewController: PagingViewController<T>, pagingItemForIndex index: Int) -> T {
        return PagingIndexItem(index: index, title: titles[index].uppercased()) as! T
    }
    
    func numberOfViewControllers<T>(in: PagingViewController<T>) -> Int{
        return titles.count
    }
}

extension TransactionsViewController : PagingViewControllerDelegate {

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
