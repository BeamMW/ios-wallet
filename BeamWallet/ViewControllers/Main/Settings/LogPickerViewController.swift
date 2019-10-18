//
// CategoryPickerViewController.swift
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

class LogPickerViewController: BaseTableViewController {
    
    public var completion : (() -> Void)?
    
    private var values = Settings.sharedManager().logValues()
    
    override var tableStyle: UITableView.Style {
        get {
            return .grouped
        }
        set {
            super.tableStyle = newValue
        }
    }
    
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
        
        setGradientTopBar(mainColor: UIColor.main.peacockBlue, addedStatusView: true)

        title = Localizable.shared.strings.save_wallet_logs
        
        tableView.register(CategoryPickerCell.self)
        tableView.separatorColor = UIColor.white.withAlphaComponent(0.13)
        tableView.separatorStyle = .singleLine
        tableView.dataSource = self
        tableView.delegate = self
        tableView.contentInsetAdjustmentBehavior = .never
        tableView.tableHeaderView = UIView(frame: CGRect(x: 0.0, y: 0.0, width: 0.0, height: 20))
        tableView.tableHeaderView?.backgroundColor = UIColor.main.marine
        tableView.backgroundColor = UIColor.main.marine
    }

}

extension LogPickerViewController : UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 50
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        Settings.sharedManager().logDays = values[indexPath.row].days
            
        self.completion?()

        self.back()
    }
}

extension LogPickerViewController : UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return values.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = UITableViewCell(style: .subtitle, reuseIdentifier: "cell")
        cell.detailTextLabel?.font = RegularFont(size: 14)
        cell.textLabel?.font = RegularFont(size: 16)
        cell.detailTextLabel?.textColor = UIColor.main.blueyGrey
        cell.textLabel?.textColor = UIColor.white
        
        cell.backgroundColor = UIColor.main.marineThree
        
        let selectedView = UIView()
        selectedView.backgroundColor = UIColor.black.withAlphaComponent(0.2)
        cell.selectedBackgroundView = selectedView
        
        if (values[indexPath.row].days == Settings.sharedManager().logDays) {
            let arrowView = UIImageView(frame: CGRect(x: 0, y: 0, width: 13, height: 13))
            arrowView.image = Tick()?.withRenderingMode(.alwaysTemplate)
            arrowView.tintColor = UIColor.main.brightTeal
            cell.accessoryView = arrowView
        }
        else{
            cell.accessoryView = nil
        }
        
        cell.textLabel?.text = values[indexPath.row].name
        cell.detailTextLabel?.text = nil

        return cell
    }
}

