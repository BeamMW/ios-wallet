//
// AddressTableView.swift
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

class AddressTableView: UITableViewController {
    
    public var viewModel = AddressViewModel(selected: .active)

    public var selectedIndex = 0 {
        didSet{
            viewModel.selectedState = AddressViewModel.AddressesSelectedState(rawValue: selectedIndex) ?? .active
            tableView.tag = selectedIndex
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.separatorStyle = .none
        tableView.register([BMEmptyCell.self, BMAddressCell.self])
   
        if UIApplication.shared.keyWindow?.traitCollection.forceTouchCapability == .available {
            registerForPreviewing(with: self, sourceView: tableView)
        }
            
        subscribeToChages()
    }
    
    private func subscribeToChages() {
        viewModel.onDataChanged = { [weak self] in
            guard let strongSelf = self else { return }
            
            strongSelf.tableView.reloadData()
        }
        viewModel.onDataDeleted = { [weak self]
            indexPath, address in
            
            guard let strongSelf = self else { return }
            
            if let path = indexPath {
                if strongSelf.viewModel.count > 0 {
                    strongSelf.tableView.performUpdate({
                        strongSelf.tableView.deleteRows(at: [path], with: .left)
                    }, completion: {
                        AppModel.sharedManager().prepareDelete(address, removeTransactions: address.isNeedRemoveTransactions)
                    })
                }
                else{
                    AppModel.sharedManager().prepareDelete(address, removeTransactions: address.isNeedRemoveTransactions)
                    
                    strongSelf.tableView.reloadData()
                }
            }
        }
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if viewModel.count == 0 {
            return tableView.h - 80
        }
        return UITableView.automaticDimension
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let count = viewModel.count
        return count == 0 ? 1 : count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
  
        if viewModel.count == 0 {
            let cell = tableView
                .dequeueReusableCell(withType: BMEmptyCell.self, for: indexPath)
                .configured(with: (text: (selectedIndex == 2 ? Localizable.shared.strings.contacts_empty : Localizable.shared.strings.addresses_empty), image: IconAddressbookEmpty()))
            return cell
        }
        else {
            let address = viewModel.selectedState == .contacts ? viewModel.contacts[indexPath.row].address : viewModel.addresses[indexPath.row]

            let cell =  tableView
                .dequeueReusableCell(withType: BMAddressCell.self, for: indexPath)
                .configured(with: (row: indexPath.row, address: address, displayTransaction: false, displayCategory: true))
            return cell
        }
    }
    
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        if viewModel.count > 0 {
            return true
        }
        else{
            return false
        }
    }
    
    override func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        
        if viewModel.count > 0 {
            return viewModel.trailingSwipeActions(indexPath: indexPath)
        }
        else{
            return nil
        }
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)

        if viewModel.count > 0 {
            let address = viewModel.selectedState == .contacts ? viewModel.contacts[indexPath.row].address : viewModel.addresses[indexPath.row]
            
            let vc = AddressViewController(address: address)
            pushViewController(vc: vc)
        }
    }
}

extension AddressTableView : UIViewControllerPreviewingDelegate {
    
    func previewingContext(_ previewingContext: UIViewControllerPreviewing, viewControllerForLocation location: CGPoint) -> UIViewController? {
                
        if viewModel.selectedState != .contacts && viewModel.count > 0 {
            
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
