//
// TransactionPageViewController.swift
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


class TransactionPageViewController: BaseTableViewController {
    
    init(transaction: BMTransaction) {
        super.init(nibName: nil, bundle: nil)
        
        self.transaction = transaction
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError(Localizable.shared.strings.fatalInitCoderError)
    }
        
    private var transaction:BMTransaction!
    
    private var addWidth:CGFloat = 0
    private var currentIndex:Int = 0
    
    private let pagingViewController = BMPagingViewController()
    
    private var titles = [Localizable.shared.strings.general, Localizable.shared.strings.payment_proof]
    
    private var controllers: [Int : Any] = [:]
    
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
        
        if !transaction.hasPaymentProof() {
            titles.removeLast()
        }
        
        pagingViewController.dataSource = self
        pagingViewController.delegate = self
        
        addChild(pagingViewController)
        view.addSubview(pagingViewController.view)
        pagingViewController.didMove(toParent: self)
                
        setGradientTopBar(mainColor: UIColor.main.peacockBlue, addedStatusView: true)
       
        title = Localizable.shared.strings.transaction.uppercased()
        
        addRightButtons(image: [MoreIcon()], target: self, selector: [#selector(onMore)])
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        pagingViewController.view.frame = CGRect(x: 0, y: self.statusView.frame.size.height + self.statusView.frame.origin.y + 10, width: view.width, height: self.view.frame.size.height - (self.statusView.frame.size.height + self.statusView.frame.origin.y + 10))
    }
    
    @objc private func onMore(sender:UIBarButtonItem) {
        let transactionViewController = controllers[0] as! TransactionViewController
        transactionViewController.onMore(sender: sender)
    }
}

extension TransactionPageViewController: PagingViewControllerDataSource {
    
    func pagingViewController<T>(_ pagingViewController: PagingViewController<T>, viewControllerForIndex index: Int) -> UIViewController {
        
        if controllers[index] == nil {
            if index == 0 {
                let viewController = TransactionViewController(transaction: self.transaction)
                viewController.view.backgroundColor = UIColor.clear
                controllers[index] = viewController
                if titles.count == 1 {
                    viewController.tableView.tableHeaderView = UIView(frame: CGRect(x: 0, y: 0, width: 320, height: 10))
                }
                return viewController
            }
            else {
                let viewController = TransactionViewController(transaction: self.transaction, isPaymentProof: true)
                viewController.view.backgroundColor = UIColor.clear
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

extension TransactionPageViewController : PagingViewControllerDelegate {
    
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
