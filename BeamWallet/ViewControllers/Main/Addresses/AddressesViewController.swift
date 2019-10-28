//
// AddressesViewController.swift
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
import Parchment

class AddressesViewController: BaseTableViewController {
    
    private let pagingViewController = BMPagingViewController()
    private let emptyView: BMEmptyView = UIView.fromNib()

    private let titles = [Localizable.shared.strings.my_active, Localizable.shared.strings.my_expired, Localizable.shared.strings.contacts]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        emptyView.text = Localizable.shared.strings.addresses_empty
        emptyView.image = IconAddressbookEmpty()
        
        pagingViewController.options.menuItemSize = PagingMenuItemSize.fixed(width: UIScreen.main.bounds.width/3, height: 50)
        
        addChild(pagingViewController)
        view.addSubview(pagingViewController.view)
        pagingViewController.didMove(toParent: self)
        
        pagingViewController.dataSource = self
        pagingViewController.delegate = self

        emptyView.isHidden = true
        emptyView.backgroundColor = UIColor.clear
        view.addSubview(emptyView)
        
        setGradientTopBar(mainColor: UIColor.main.peacockBlue, addedStatusView: true)
        
        title = Localizable.shared.strings.addresses
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        checkIsEmpty()
        
        AppModel.sharedManager().addDelegate(self)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        AppModel.sharedManager().removeDelegate(self)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        pagingViewController.view.frame = tableView.frame
        emptyView.frame = tableView.frame
    }
    
    private func checkIsEmpty() {
        let count = AppModel.sharedManager().walletAddresses?.count ?? 0 + AppModel.sharedManager().contacts.count
        
        if count == 0 {
            pagingViewController.view.alpha = 0
            emptyView.isHidden = false
        }
        else{
            pagingViewController.view.alpha = 1
            emptyView.isHidden = true
        }
    }
    
    @objc private func onAddContact() {
        let vc = SaveContactViewController(address: nil)
        pushViewController(vc: vc)
    }
}

extension AddressesViewController: PagingViewControllerDelegate {
    func pagingViewController<T>(_ pagingViewController: PagingViewController<T>, didScrollToItem pagingItem: T, startingViewController: UIViewController?, destinationViewController: UIViewController, transitionSuccessful: Bool) where T : PagingItem, T : Comparable, T : Hashable {
        
        let index = (pagingItem as! PagingIndexItem).index
        
        if index == 2 {
            addRightButton(image: IconAdd(), target: self, selector: #selector(onAddContact))
        }
        else{
            removeRightButton()
        }
    }
}

extension AddressesViewController: PagingViewControllerDataSource {
    
    func pagingViewController<T>(_ pagingViewController: PagingViewController<T>, viewControllerForIndex index: Int) -> UIViewController {
       
        let viewController = AddressTableView()
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

extension AddressesViewController : WalletModelDelegate {
    
    func onWalletAddresses(_ walletAddresses: [BMAddress]) {
        DispatchQueue.main.async {
            self.checkIsEmpty()
        }
    }
    
    func onContactsChange(_ contacts: [BMContact]) {
        DispatchQueue.main.async {
            self.checkIsEmpty()
        }
    }
}
