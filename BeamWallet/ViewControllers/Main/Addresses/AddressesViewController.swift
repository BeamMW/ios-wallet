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

class AddressesViewController: BaseTableViewController {
    
    private let headerView: AddressesSegmentView = UIView.fromNib()
    private let viewModel = AddressViewModel(selected: .active)
    
    override var isUppercasedTitle: Bool {
        get{
            return true
        }
        set{
            super.isUppercasedTitle = true
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = Localizables.shared.strings.addresses
        
        headerView.delegate = self
        
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(AddressCell.self)
        tableView.addPullToRefresh(target: self, handler: #selector(refreshData(_:)))
        
        NotificationCenter.default.addObserver(self, selector: #selector(didBecomeActive), name: UIApplication.didBecomeActiveNotification, object: nil)
        
        if traitCollection.forceTouchCapability == .available {
            registerForPreviewing(with: self, sourceView: tableView)
        }
        
        subscribeToChages()
        onAddMenuIcon()
    }
    
    private func subscribeToChages() {
        viewModel.onDataChanged = { [weak self] in
            self?.tableView.reloadData()
        }
        viewModel.onDataDeleted = { [weak self]
            indexPath, address in
            
            if let path = indexPath {
                self?.tableView.performUpdate({
                    self?.tableView.deleteRows(at: [path], with: .left)
                }, completion: {
                    AppModel.sharedManager().prepareDelete(address, removeTransactions: address.isNeedRemoveTransactions)
                })
            }
        }
    }
    
    @objc private func didBecomeActive() {
        viewModel.filterAddresses()
    }
    
    @objc private func refreshData(_ sender: Any) {
        tableView.stopRefreshing()
    }
}

extension AddressesViewController : UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return section == 0 ? AddressesSegmentView.height : 0
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return AddressCell.height()
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        let address = viewModel.selectedState == .contacts ? viewModel.contacts[indexPath.row].address : viewModel.addresses[indexPath.row]
        
        let vc = AddressViewController(address: address)
        vc.hidesBottomBarWhenPushed = true
        pushViewController(vc: vc)
    }
    
    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration?
    {
       return viewModel.trailingSwipeActions(indexPath: indexPath)
    }
}

extension AddressesViewController : UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let count = viewModel.selectedState == .contacts ? viewModel.contacts.count : viewModel.addresses.count
        return count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let address = viewModel.selectedState == .contacts ? viewModel.contacts[indexPath.row].address : viewModel.addresses[indexPath.row]
        
        let cell =  tableView
            .dequeueReusableCell(withType: AddressCell.self, for: indexPath)
            .configured(with: (row: indexPath.row, address: address, single:false, displayCategory: true))
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        return section == 0 ? headerView : nil
    }
}

extension AddressesViewController : UIViewControllerPreviewingDelegate {
    
    func previewingContext(_ previewingContext: UIViewControllerPreviewing, viewControllerForLocation location: CGPoint) -> UIViewController? {
        
        if viewModel.selectedState != .contacts {

            guard let indexPath = tableView.indexPathForRow(at: location) else { return nil }
            
            guard let cell = tableView.cellForRow(at: indexPath) else { return nil }
            
            let detailVC = PreviewQRViewController(address: viewModel.addresses[indexPath.row])
            detailVC.preferredContentSize = CGSize(width: 0.0, height: 340)
            
            previewingContext.sourceRect = cell.frame
            
            return detailVC
        }
        else{
            return nil
        }
    }
    
    func previewingContext(_ previewingContext: UIViewControllerPreviewing, commit viewControllerToCommit: UIViewController) {
        
        show(viewControllerToCommit, sender: self)
        
        (viewControllerToCommit as! PreviewQRViewController).didShow()
    }
}

extension AddressesViewController : AddressesSegmentViewDelegate {
    func onFilterClicked(index: Int) {
        viewModel.selectedState = AddressViewModel.AddressesSelectedState(rawValue: index) ?? .active
    }
}
