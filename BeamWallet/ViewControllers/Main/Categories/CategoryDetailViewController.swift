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

class CategoryDetailViewController: BaseViewController {

    @IBOutlet private weak var tableView: UITableView!
    @IBOutlet private var headerView: UIView!

    private var category:BMCategory!
    private var addresses = [BMAddress]()

    init(category:BMCategory?) {
        super.init(nibName: nil, bundle: nil)
        
        self.category = category
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = "Category"
        
        loadAddresses()
        
        tableView.register(AddressCell.self)
        tableView.register(CategoryNameCell.self)
        tableView.register(EmptyCell.self)

        self.navigationItem.rightBarButtonItem = UIBarButtonItem(image: UIImage(named: "iconMore"), style: .plain, target: self, action: #selector(onMore))

        AppModel.sharedManager().addDelegate(self)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        if isMovingFromParent
        {
            AppModel.sharedManager().removeDelegate(self)
        }
    }
    
    private func loadAddresses() {
        addresses = AppModel.sharedManager().getAddressFrom(self.category) as! [BMAddress]
    }
    
    @objc private func onMore(sender:UIBarButtonItem) {        
        let items = [BMPopoverMenu.BMPopoverMenuItem(name: "Edit", icon: nil, action:.edit_category), BMPopoverMenu.BMPopoverMenuItem(name: "Delete", icon: nil, action:.delete_category)]
        
        BMPopoverMenu.show(menuArray: items, done: { (selectedItem) in
            if let item = selectedItem {
                switch (item.action) {
                case .edit_category:
                    let vc = CategoryEditViewController(category: self.category)
                    vc.hidesBottomBarWhenPushed = true
                    self.pushViewController(vc: vc)
                case .delete_address :
                    AppModel.sharedManager().removeDelegate(self)

                    AppModel.sharedManager().deleteCategory(self.category)
                    self.navigationController?.popViewController(animated: true)
                default:
                    return
                }
            }
        }, cancel: {
            
        })
    }
}

extension CategoryDetailViewController : UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        if section == 1 {
            return 50
        }
        
        return 0
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if indexPath.section == 0 {
            return 80
        }
        return 90
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        if indexPath.section == 1 && addresses.count > 0 {
            let vc = AddressViewController(address: addresses[indexPath.row], isContact:false)
            vc.hidesBottomBarWhenPushed = true
            pushViewController(vc: vc)
        }
    }
}

extension CategoryDetailViewController : UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 1 {
            if addresses.count == 0 {
                return 1
            }
            return addresses.count
        }
        return 1
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell =  tableView
            .dequeueReusableCell(withType: CategoryNameCell.self, for: indexPath)
            .configured(with: self.category)
        return cell
        
//        if indexPath.section == 1 {
//            if addresses.count == 0 {
//                let cell =  tableView
//                    .dequeueReusableCell(withType: EmptyCell.self, for: indexPath)
//                    .configured(with: "there are no addresses associated with this category")
//                return cell
//            }
//            else{
//                let cell =  tableView
//                    .dequeueReusableCell(withType: AddressCell.self, for: indexPath)
//                    .configured(with: (row: indexPath.row, address: addresses[indexPath.row], single:false, displayCategory:false))
//                return cell
//            }
//
//        }
//        else{
//            let cell =  tableView
//                .dequeueReusableCell(withType: CategoryNameCell.self, for: indexPath)
//                .configured(with: self.category)
//            return cell
//        }
        
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        if section == 1 {
            return headerView
        }
        
        return nil
    }
}

extension CategoryDetailViewController : WalletModelDelegate {
    
    func onWalletAddresses(_ walletAddresses: [BMAddress]) {
        DispatchQueue.main.async {
            self.loadAddresses()
            UIView.performWithoutAnimation {
                self.tableView.reloadData()
            }
        }
    }
    func onCategoriesChange() {
        DispatchQueue.main.async {
            let categories = AppModel.sharedManager().categories as! [BMCategory]
            if let category = categories.first(where: { $0.id == self.category.id }) {
                self.category = category
                self.loadAddresses()
                
                UIView.performWithoutAnimation {
                    self.tableView.reloadData()
                }
            }
        }
    }
}
