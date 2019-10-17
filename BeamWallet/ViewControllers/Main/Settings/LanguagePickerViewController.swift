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

class LanguagePickerViewController: BaseTableViewController {
    
    struct Language {
        var name,code:String!
    }
    
    public var completion : ((String) -> Void)?
    
    private var languages = Settings.sharedManager().languages()
    private var selectedLanguage:String!
    private var currentLanguage:String!
    
    override var tableStyle: UITableView.Style {
        get {
            return .grouped
        }
        set {
            super.tableStyle = newValue
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = Localizable.shared.strings.language
        
        //addRightButton(title:Localizable.shared.strings.save, target: self, selector: #selector(onSave), enabled: false)
    
        for lang in languages {
            if lang.code == Settings.sharedManager().language {
                selectedLanguage = lang.code
                currentLanguage = lang.code
            }
        }
        
        tableView.delegate = self
        tableView.dataSource = self
        tableView.separatorColor = UIColor.white.withAlphaComponent(0.13)
        tableView.separatorStyle = .singleLine
        tableView.register(CategoryPickerCell.self)
    }
    
    private func onSave() {
        Settings.sharedManager().language = selectedLanguage
        
        Localizable.shared.reset()
        
        Settings.sharedManager().language = selectedLanguage

        AppModel.sharedManager().getUTXO()
        AppModel.sharedManager().getWalletStatus()
        AppModel.sharedManager().refreshAddresses()
        
        self.completion?(selectedLanguage)

        self.back()
    }
}

extension LanguagePickerViewController : UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 60
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        selectedLanguage = languages[indexPath.row].code
        
        enableRightButton(enabled: (currentLanguage == selectedLanguage) ? false : true)

        tableView.reloadData()
        
        onSave()
    }
}

extension LanguagePickerViewController : UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return languages.count
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
        
        if (languages[indexPath.row].code == selectedLanguage) {
            let arrowView = UIImageView(frame: CGRect(x: 0, y: 0, width: 13, height: 13))
            arrowView.image = Tick()?.withRenderingMode(.alwaysTemplate)
            arrowView.tintColor = UIColor.main.brightTeal
            cell.accessoryView = arrowView
        }
        else{
            cell.accessoryView = nil
        }
        
        cell.textLabel?.text = languages[indexPath.row].localName
        cell.detailTextLabel?.text = languages[indexPath.row].enName

        return cell
    }
}

