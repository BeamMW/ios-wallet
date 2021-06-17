//
// AssetDescViewController.swift
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

class AssetDescViewController: UITableViewController {
    
    public var asset:BMAsset!
    public var items = [BMThreeLineItem]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.contentInsetAdjustmentBehavior = .never
        tableView.separatorStyle = .none
        tableView.register([BMThreeLineCell.self, AssetSiteCell.self])
        tableView.keyboardDismissMode = .interactive
    }
    
    func reloadData(asset:BMAsset, items: [BMThreeLineItem]) {
        self.asset = asset
        self.items = items
        self.tableView.reloadData()
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            return 1
        }
        return items.count
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.section == 0 && indexPath.row == 0 {
            let cell = tableView
                .dequeueReusableCell(withType: AssetSiteCell.self, for: indexPath)
            cell.setAsset(self.asset)
            return cell
        }
        else {
            let item = items[indexPath.row]
            
            let cell = tableView
                .dequeueReusableCell(withType: BMThreeLineCell.self, for: indexPath)
            cell.configure(with: item)

            return cell
        }
    }
}
