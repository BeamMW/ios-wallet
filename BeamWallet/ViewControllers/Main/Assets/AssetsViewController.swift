//
// AssetsViewController.swift
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

class AssetsViewController: BaseTableViewController {

    private let statusViewModel = StatusViewModel()
    private let assetViewModel = AssetViewModel()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setGradientTopBar(mainColor: UIColor.main.peacockBlue, addedStatusView: true)
        
        title = Localizable.shared.strings.assets

        assetViewModel.removeBeam()
        
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register([WalletStatusCell.self, AssetAvailableCell.self])
        tableView.tableHeaderView = UIView(frame: CGRect(x: 0, y: 0, width: 0, height: 10))
        tableView.keyboardDismissMode = .interactive
        tableView.addPullToRefresh(target: self, handler: #selector(refreshData(_:)))
        
        rightButton()
        
        Settings.sharedManager().addDelegate(self)
        
        subscribeToUpdates()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        Settings.sharedManager().removeDelegate(self)
    }

    private func rightButton() {
        addRightButtons(image: [Settings.sharedManager().isHideAmounts ? IconShowBalance() : IconHideBalance(), IconFilter()].reversed(), target: self, selector: [#selector(onHideAmounts), #selector(onFilter)].reversed())
    }
    
    @objc private func onFilter() {

        if let view = self.view.viewWithTag(200) {
            let selectedImage = "iconDoneBlue"
            
            var menu = [BMPopoverMenu.BMPopoverMenuItem(name: Localizable.shared.strings.usage_recent_old, icon: assetViewModel.filtertype == .recent_old ? selectedImage : nil, action: .cancel_transaction)]
            menu.append(BMPopoverMenu.BMPopoverMenuItem(name: Localizable.shared.strings.usage_old_recent, icon: assetViewModel.filtertype == .old_recent ? selectedImage : nil, action: .cancel_transaction))
            menu.append(BMPopoverMenu.BMPopoverMenuItem(name: Localizable.shared.strings.amount_large_small, icon: assetViewModel.filtertype == .amount_large_small ? selectedImage : nil, action: .cancel_transaction))
            menu.append(BMPopoverMenu.BMPopoverMenuItem(name: Localizable.shared.strings.amount_small_large, icon: assetViewModel.filtertype == .amount_small_large ? selectedImage : nil, action: .cancel_transaction))
            menu.append(BMPopoverMenu.BMPopoverMenuItem(name: Localizable.shared.strings.usd_large_small, icon: assetViewModel.filtertype == .amount_usd_small ? selectedImage : nil, action: .cancel_transaction))
            menu.append(BMPopoverMenu.BMPopoverMenuItem(name: Localizable.shared.strings.usd_small_large, icon: assetViewModel.filtertype == .amount_usd_large ? selectedImage : nil, action: .cancel_transaction))

            BMPopoverMenu.showForSender(sender: view, with: menu) { item in
                if item?.name == Localizable.shared.strings.usage_recent_old {
                    self.assetViewModel.filtertype = .recent_old
                }
                else if item?.name == Localizable.shared.strings.usage_old_recent {
                    self.assetViewModel.filtertype = .old_recent
                }
                else if item?.name == Localizable.shared.strings.amount_large_small {
                    self.assetViewModel.filtertype = .amount_large_small
                }
                else if item?.name == Localizable.shared.strings.amount_small_large {
                    self.assetViewModel.filtertype = .amount_small_large
                }
                else if item?.name == Localizable.shared.strings.usd_large_small {
                    self.assetViewModel.filtertype = .amount_usd_small
                }
                else if item?.name == Localizable.shared.strings.usd_small_large {
                    self.assetViewModel.filtertype = .amount_usd_large
                }
            } cancel: {
                
            }
        }
    }
    
    @objc private func refreshData(_ sender: Any) {
        AppModel.sharedManager().getWalletStatus()
    }
    
    private func subscribeToUpdates() {
        statusViewModel.onVerificationCompleted = { [weak self] in
            UIView.performWithoutAnimation {
                guard let strongSelf = self else { return }
                strongSelf.tableView.stopRefreshing()
                strongSelf.tableView.reloadData()
            }
        }
        
        statusViewModel.onRatesChange = { [weak self] in
            guard let strongSelf = self else { return }
            UIView.performWithoutAnimation {
                strongSelf.tableView.reloadData()
            }
        }
        
        statusViewModel.onDataChanged = { [weak self] in
            guard let strongSelf = self else { return }
            UIView.performWithoutAnimation {
                strongSelf.tableView.stopRefreshing()
                strongSelf.tableView.reloadData()
            }
        }
        
        assetViewModel.onDataChanged = { [weak self] in
            guard let strongSelf = self else { return }
            UIView.performWithoutAnimation {
                strongSelf.tableView.stopRefreshing()
                strongSelf.tableView.reloadData()
            }
        }
    }
}

extension AssetsViewController: UITableViewDataSource, UITableViewDelegate {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 1 {
            return assetViewModel.assets.count
        }
        return 1
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.section == 0 {
            let cell = tableView.dequeueReusableCell(withType: WalletStatusCell.self, for: indexPath)
            cell.delegate = self
            return cell
        }
        else {
            let cell = tableView.dequeueReusableCell(withType: AssetAvailableCell.self, for: indexPath)
            cell.setAsset(assetViewModel.assets[indexPath.row])
            return cell
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        if indexPath.section == 1 {
            let vc = AssetDetailViewController(asset: assetViewModel.assets[indexPath.row])
            pushViewController(vc: vc)
        }
    }
}

extension AssetsViewController: SettingsModelDelegate {
    
    func onChangeHideAmounts() {
        rightButton()
        
        tableView.reloadData()
    }
}

extension AssetsViewController: WalletStatusCellDelegate {
    
    func onClickReceived() {
        statusViewModel.onReceive()
    }
    
    func onClickSend() {
        statusViewModel.onSend()
    }
}
