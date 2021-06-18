//
// MaxPrivacyDetailViewController.swift
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
import PopOverMenu

class MaxPrivacyDetailViewController: BaseTableViewController {
    
    private let viewModel = MaxPrivacyDetailViewModel()

    
    override func viewDidLoad() {
        super.viewDidLoad()
                
        setGradientTopBar(mainColor: UIColor.main.peacockBlue, addedStatusView: true)
        addRightButton(image: IconFilter(), target: self, selector: #selector(onFilter))

        title = Localizable.shared.strings.max_privacy
        
        tableView.register(MaxPrivacyDetailCell.self)
        tableView.separatorStyle = .none
        tableView.dataSource = self
        tableView.delegate = self
        tableView.tableHeaderView = UIView(frame: CGRect(x: 0, y: 0, width: 320, height: 10))
        
        viewModel.onDataChanged = {
            [weak self] in
            
            guard let strongSelf = self else { return }
            
            strongSelf.tableView.reloadData()
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        viewModel.filterUTXOS()
    }
    
    @objc private func onFilter() {
        
        if let view = self.view.viewWithTag(20191) {
            let selectedImage = "iconDoneBlue"
            
            var menu = [BMPopoverMenu.BMPopoverMenuItem(name: Localizable.shared.strings.time_ear_last, icon: viewModel.filterType == .time_ear ? selectedImage : nil, action: .cancel_transaction)]
            menu.append(BMPopoverMenu.BMPopoverMenuItem(name: Localizable.shared.strings.time_last_ear, icon: viewModel.filterType == .time_latest ? selectedImage : nil, action: .cancel_transaction))
            menu.append(BMPopoverMenu.BMPopoverMenuItem(name: Localizable.shared.strings.amount_large_small, icon: viewModel.filterType == .amount_large ? selectedImage : nil, action: .cancel_transaction))
            menu.append(BMPopoverMenu.BMPopoverMenuItem(name: Localizable.shared.strings.amount_small_large, icon: viewModel.filterType == .amount_small ? selectedImage : nil, action: .cancel_transaction))

            BMPopoverMenu.showForSender(sender: view, with: menu) { item in
                if item?.name == Localizable.shared.strings.time_ear_last {
                    self.viewModel.filterType = .time_ear
                }
                else if item?.name == Localizable.shared.strings.time_last_ear {
                    self.viewModel.filterType = .time_latest
                }
                else if item?.name == Localizable.shared.strings.amount_large_small {
                    self.viewModel.filterType = .amount_large
                }
                else if item?.name == Localizable.shared.strings.amount_small_large {
                    self.viewModel.filterType = .amount_small
                }
            } cancel: {
                
            }
        }
    }
}

extension MaxPrivacyDetailViewController : UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let header: MaxPrivacyDetailHeader = UIView.fromNib()
        header.backgroundColor = self.view.backgroundColor
        return header
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 40
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 60
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
}

extension MaxPrivacyDetailViewController : UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.utxos.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView
            .dequeueReusableCell(withType: MaxPrivacyDetailCell.self, for: indexPath)
        cell.configure(with: (row: indexPath.row, utxo: viewModel.utxos[indexPath.row]))
        return cell
    }
}
