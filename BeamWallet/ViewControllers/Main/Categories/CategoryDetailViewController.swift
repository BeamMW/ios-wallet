//
// CategoryDetailViewController.swift
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


class CategoryDetailViewController: BaseTableViewController {
    
    private let pagingViewController = BMPagingViewController()
    private let emptyView: BMEmptyView = UIView.fromNib()

    private let titles = [Localizable.shared.strings.addresses, Localizable.shared.strings.contacts]

    private var category:BMCategory!
    private var nameLabel:UILabel!
    
    init(category:BMCategory?) {
        super.init(nibName: nil, bundle: nil)
         
        self.category = category
    }
     
    required init?(coder aDecoder: NSCoder) {
        fatalError(Localizable.shared.strings.fatalInitCoderError)
    }
    
  
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        emptyView.text = Localizable.shared.strings.no_category_addresses.capitalizingFirstLetter()
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
        
        title = Localizable.shared.strings.category
        
        nameLabel = UILabel()
        nameLabel.font = SemiboldFont(size: 30)
        nameLabel.text = category.name
        nameLabel.textColor = UIColor.init(hexString: category.color)
        view.addSubview(nameLabel)
        
        pagingViewController.indicatorColor = UIColor.init(hexString: category.color)
        
        addRightButtons(image: [IconEdit(), IconRowDelete()], target: self, selector: [#selector(onEdit),#selector(onDelete)])
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
        
        nameLabel.frame = CGRect(x: 15, y: tableView.y + 15, width: UIScreen.main.bounds.width - 30, height: 40)
        
        var frame = tableView.frame
        frame.origin.y = frame.origin.y + 60
        frame.size.height = frame.size.height - 60
        
        pagingViewController.view.frame = frame
        emptyView.frame = frame
    }
    
    @objc private func onEdit() {
        let vc = CategoryEditViewController(category: self.category)
        vc.completion = { [weak self] obj in
            guard let strongSelf = self else { return }
            strongSelf.onCategoriesChange()
        }
        vc.hidesBottomBarWhenPushed = true
        self.pushViewController(vc: vc)
    }
    
    @objc private func onDelete() {
          self.confirmAlert(title: Localizable.shared.strings.delete_category, message:Localizable.shared.strings.delete_category_text(str:self.category.name) , cancelTitle: Localizable.shared.strings.cancel, confirmTitle: Localizable.shared.strings.delete, cancelHandler: { (_ ) in
              
          }, confirmHandler: { (_ ) in
              AppModel.sharedManager().deleteCategory(self.category)
              self.back()
          })
    }
    
    private func checkIsEmpty() {
        let count = AppModel.sharedManager().getAddressesFrom(category).count
        
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

extension CategoryDetailViewController: PagingViewControllerDelegate {
    func pagingViewController<T>(_ pagingViewController: PagingViewController<T>, didScrollToItem pagingItem: T, startingViewController: UIViewController?, destinationViewController: UIViewController, transitionSuccessful: Bool) where T : PagingItem, T : Comparable, T : Hashable {
    }
}

extension CategoryDetailViewController: PagingViewControllerDataSource {
    
    func pagingViewController<T>(_ pagingViewController: PagingViewController<T>, viewControllerForIndex index: Int) -> UIViewController {
       
        let viewController = AddressTableView()
        viewController.category = self.category
        viewController.selectedIndex = index
        viewController.view.backgroundColor = UIColor.clear

        return viewController
    }
    
    func pagingViewController<T>(_ pagingViewController: PagingViewController<T>, pagingItemForIndex index: Int) -> T {
        return PagingIndexItem(index: index, title: titles[index].uppercased()) as! T
    }
    
    func numberOfViewControllers<T>(in: PagingViewController<T>) -> Int{
        return titles.count
    }
}

extension CategoryDetailViewController : WalletModelDelegate {
    
    func onWalletAddresses(_ walletAddresses: [BMAddress]) {
        DispatchQueue.main.async { [weak self] in
            guard let strongSelf = self else { return }
            strongSelf.checkIsEmpty()
        }
    }
    
    func onContactsChange(_ contacts: [BMContact]) {
        DispatchQueue.main.async { [weak self] in
            guard let strongSelf = self else { return }
            strongSelf.checkIsEmpty()
        }
    }
    
    func onCategoriesChange() {
        DispatchQueue.main.async { [weak self] in
            guard let strongSelf = self else { return }

            if let cat = AppModel.sharedManager().findCategory(byId: String(strongSelf.category.id)) {
                strongSelf.category = cat
                
                strongSelf.nameLabel.text = strongSelf.category.name
                strongSelf.nameLabel.textColor = UIColor.init(hexString: strongSelf.category.color)
                
                strongSelf.pagingViewController.indicatorColor = UIColor.init(hexString: strongSelf.category.color)
            }
        }
    }
}
