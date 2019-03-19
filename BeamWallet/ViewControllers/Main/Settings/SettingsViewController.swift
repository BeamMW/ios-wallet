//
//  WalletViewController.swift
//  BeamWallet
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

class SettingsViewController: BaseViewController {
    
    private var rowHeight = [CGFloat(130.0),CGFloat(130.0),CGFloat(150.0)]

    @IBOutlet private weak var talbeView: UITableView!
    @IBOutlet private weak var versionLabel:UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.navigationItem.title = "Settings"
        
        talbeView.register(ShareLogCell.self)
        
        versionLabel.text = version()
    }
    
    func version() -> String {
        let dictionary = Bundle.main.infoDictionary!
        let version = dictionary["CFBundleShortVersionString"] as! String
        let build = dictionary["CFBundleVersion"] as! String
        return "Version \(version).\(build)"
    }
}

extension SettingsViewController : UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if indexPath.section == 0 && indexPath.row == 0 {
            return rowHeight[0]
        }
        else if indexPath.section == 0 && indexPath.row == 1 {
            return rowHeight[1]
        }
        else if indexPath.section == 0 && indexPath.row == 2 {
            return rowHeight[2]
        }
        else if indexPath.section == 1 {
            return 86
        }
        return 0
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
}

extension SettingsViewController : UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        if indexPath.section == 0 && indexPath.row == 0 {
            let cell = tableView
                .dequeueReusableCell(withType: ShareLogCell.self, for: indexPath)
            cell.delegate = self
            
            return cell
        }
 
        return UITableViewCell()
    }
}

extension SettingsViewController : ShareLogCellDelegate {
    func onClickReport() {
        let path = AppModel.sharedManager().getZipLogs()
        let url = URL(fileURLWithPath: path)
        
        let act = ShareLogActivity()
        act.zipUrl = url
        
        let vc = UIActivityViewController(activityItems: [url], applicationActivities: [act])
        if (AppDelegate.CurrentTarget == .Test) {
            vc.setValue("beam wallet testnet logs", forKey: "subject")
        }
        else{
            vc.setValue("beam wallet logs", forKey: "subject")
        }
        
        vc.excludedActivityTypes = [UIActivity.ActivityType.postToFacebook, UIActivity.ActivityType.assignToContact, UIActivity.ActivityType.copyToPasteboard, UIActivity.ActivityType.print,UIActivity.ActivityType.openInIBooks]
        
        present(vc, animated: true)
    }
}
