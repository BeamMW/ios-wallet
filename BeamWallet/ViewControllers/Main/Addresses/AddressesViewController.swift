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
    
    private let viewModel = AddressViewModel(selected: .active)
    private let header = BMSegmentView.init(segments: [Localizable.shared.strings.my_active, Localizable.shared.strings.my_expired, Localizable.shared.strings.contacts])

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
        
        isGradient = true
        setGradientTopBar(mainColor: UIColor.main.peacockBlue, addedStatusView: true)
        
        title = Localizable.shared.strings.addresses
        
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register([AddressCell.self, BMEmptyCell.self])
        tableView.addPullToRefresh(target: self, handler: #selector(refreshData(_:)))
        
        NotificationCenter.default.addObserver(self, selector: #selector(didBecomeActive), name: UIApplication.didBecomeActiveNotification, object: nil)
        
        if traitCollection.forceTouchCapability == .available {
            registerForPreviewing(with: self, sourceView: tableView)
        }
        
        header.lineColor = UIColor.main.peacockBlue
        header.selectedIndex = viewModel.selectedState.rawValue
        header.delegate = self
        view.insertSubview(header, at: 0)
        
        subscribeToChages()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
                
        header.y = tableView.y - 5
        tableView.y = header.y + header.h
        tableView.h = self.view.h - tableView.y
    }
    
    private func subscribeToChages() {
        viewModel.onDataChanged = { [weak self] in
            self?.tableView.reloadData()
        }
        viewModel.onDataDeleted = { [weak self]
            indexPath, address in
            
            if let path = indexPath {
                if self?.viewModel.count ?? 0 > 0 {
                    self?.tableView.performUpdate({
                        self?.tableView.deleteRows(at: [path], with: .left)
                    }, completion: {
                        AppModel.sharedManager().prepareDelete(address, removeTransactions: address.isNeedRemoveTransactions)
                    })
                }
                else{
                    AppModel.sharedManager().prepareDelete(address, removeTransactions: address.isNeedRemoveTransactions)
                    self?.tableView.reloadData()
                }
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
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        if viewModel.count > 0 {
            let address = viewModel.selectedState == .contacts ? viewModel.contacts[indexPath.row].address : viewModel.addresses[indexPath.row]
            
            let vc = AddressViewController(address: address)
            pushViewController(vc: vc)
        }
    }
    
    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        
        if viewModel.count > 0 {
            return viewModel.trailingSwipeActions(indexPath: indexPath)
        }
        else{
            return nil
        }
    }
}

extension AddressesViewController : UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let count = viewModel.count
        return count == 0 ? 1 : count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        if viewModel.count == 0 {
            let cell = tableView
                .dequeueReusableCell(withType: BMEmptyCell.self, for: indexPath)
                .configured(with: (text: (viewModel.selectedState == .contacts ? Localizable.shared.strings.contacts_empty : Localizable.shared.strings.addresses_empty), image: IconAddressbookEmpty()))
            return cell
        }
        else {
            let address = viewModel.selectedState == .contacts ? viewModel.contacts[indexPath.row].address : viewModel.addresses[indexPath.row]
            
            let cell =  tableView
                .dequeueReusableCell(withType: AddressCell.self, for: indexPath)
                .configured(with: (row: indexPath.row, address: address, displayTransaction: false, displayCategory: true))
            
            return cell
        }
    }
}

extension AddressesViewController : UIViewControllerPreviewingDelegate {
    
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

extension AddressesViewController : BMTableHeaderTitleViewDelegate {
    func onDidSelectSegment(index: Int) {
        viewModel.selectedState = AddressViewModel.AddressesSelectedState(rawValue: index) ?? .active
    }
}
