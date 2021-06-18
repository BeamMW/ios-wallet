//
// AssetInfoViewController.swift
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

class AssetBalanceViewController: UITableViewController {

    public var asset:BMAsset!
    public var items = [[BMThreeLineItem]]()
    public var section_1_visible = true
    public var section_0_visible = true

    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.contentInsetAdjustmentBehavior = .never
        tableView.separatorStyle = .none
        tableView.register([BMThreeLineCell.self, AssetDropDownCell.self])
        tableView.keyboardDismissMode = .interactive
        tableView.tableFooterView = UIView(frame: CGRect(x: 0, y: 0, width: 320, height: 44))
    }
    
    @objc private func onMaxPrivacyInfo() {
        if let top = UIApplication.getTopMostViewController() {
            let vc = MaxPrivacyDetailViewController()
            top.pushViewController(vc: vc)
        }
    }
    
    func reloadData(asset:BMAsset, items: [[BMThreeLineItem]]) {
        self.asset = asset
        self.items = items
        self.tableView.reloadData()
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let item = items[section]
        if section == 1 && !section_1_visible {
            return 1
        }
        else if section == 0 && !section_0_visible {
            return 1
        }
        return item.count
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return items.count
    }
    
    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return section == 1 ? 25 : 0
    }
    
    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let view = UIView()
        view.backgroundColor = UIColor.clear
        return view
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.section == 0 && indexPath.row == 0 {
            let cell = tableView
                .dequeueReusableCell(withType: AssetDropDownCell.self, for: indexPath)
            cell.setAsset(self.asset, expand: section_0_visible)
            return cell
        }
        else {
            let item = items[indexPath.section]
            
            let cell = tableView
                .dequeueReusableCell(withType: BMThreeLineCell.self, for: indexPath)
            cell.configure(with: item[indexPath.row])
            if indexPath.section == 1 {
                cell.setExpand(value: section_1_visible)
            }
            cell.accessoryButton.addTarget(self, action: #selector(onMaxPrivacyInfo), for: .touchUpInside)
            
            return cell
        }
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.section == 1 && indexPath.row == 0 {
            section_1_visible = !section_1_visible
            tableView.reloadSections(IndexSet(integer: 1), with: .fade)
        }
        else if indexPath.section == 0 && indexPath.row == 0 {
            section_0_visible = !section_0_visible
            tableView.reloadSections(IndexSet(integer: 0), with: .fade)
        }
    }
}
