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
    
    private var languages = [Language]()
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
        
        
        title = Localizables.shared.strings.language
        
        addRightButton(title:Localizables.shared.strings.save, target: self, selector: #selector(onSave), enabled: false)
        
        languages.append(Language(name: "English", code: "en"))
        languages.append(Language(name: "Русский", code: "ru"))
        languages.append(Language(name: "中文", code: "zh-Hans"))

        for lang in languages {
            if lang.code == Settings.sharedManager().language {
                selectedLanguage = lang.code
                currentLanguage = lang.code
            }
        }
        
        tableView.delegate = self
        tableView.dataSource = self
        tableView.separatorColor = UIColor.white.withAlphaComponent(0.1)
        tableView.separatorStyle = .singleLine
        tableView.register(CategoryPickerCell.self)
    }
    
    @objc private func onSave(sender:UIBarButtonItem) {
        Settings.sharedManager().language = selectedLanguage
        
        Localizables.shared.reset()
        
        Settings.sharedManager().language = selectedLanguage

        AppModel.sharedManager().getUTXO()
        AppModel.sharedManager().getWalletStatus()
        
        self.completion?(selectedLanguage)

        self.back()
    }
}

extension LanguagePickerViewController : UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 50
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        selectedLanguage = languages[indexPath.row].code
        
        enableRightButton(enabled: (currentLanguage == selectedLanguage) ? false : true)

        tableView.reloadData()
    }
}

extension LanguagePickerViewController : UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return languages.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell =  tableView
            .dequeueReusableCell(withType: CategoryPickerCell.self, for: indexPath)
        
        cell.simpleConfigure(with: (name: languages[indexPath.row].name, selected: (languages[indexPath.row].code == selectedLanguage)))
        
        return cell
    }
}

