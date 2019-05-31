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

import UIKit

class CategoryPickerViewController: BaseTableViewController {
    
    public var completion : ((BMCategory?) -> Void)?

    private var categories:[BMCategory]!
    private var selectedCategory:BMCategory?
    private var currentCategory:BMCategory?

    init(category:BMCategory?) {
        super.init(nibName: nil, bundle: nil)
        
        self.currentCategory = category
        
        if category == nil {
            self.selectedCategory = BMCategory.none()
        }
        else{
            self.selectedCategory = category
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError(LocalizableStrings.fatalInitCoderError)
    }
    
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
        
        if isNavigationGradient {
            largeTitle = LocalizableStrings.category.uppercased()
            navigationItem.hidesBackButton = true
        }
        else{
            title = LocalizableStrings.category
            addRightButton(title:LocalizableStrings.save, targer: self, selector: #selector(onSave), enabled: false)
        }
        
        categories = (AppModel.sharedManager().categories as! [BMCategory])
        categories.insert(BMCategory.none(), at: 0)
        
        tableView.delegate = self
        tableView.dataSource = self
        tableView.separatorColor = UIColor.white.withAlphaComponent(0.1)
        tableView.separatorStyle = .singleLine
        tableView.register(CategoryPickerCell.self)
        tableView.register(EmptyCell.self)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if isNavigationGradient {
            addRightButton(title:LocalizableStrings.save, targer: self, selector: #selector(onSave), enabled: false)
        }
    }
    
    @objc private func onSave(sender:UIBarButtonItem) {
        self.completion?(selectedCategory)
        self.navigationController?.popViewController(animated: true)
    }
}

extension CategoryPickerViewController : UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 50
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        selectedCategory = categories[indexPath.row]
        
        if currentCategory != nil {
            enableRightButton(enabled: (currentCategory?.id == selectedCategory?.id) ? false : true)
        }
        else{
            enableRightButton(enabled: true)
        }
        
        tableView.reloadData()
    }
}

extension CategoryPickerViewController : UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return categories.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell =  tableView
            .dequeueReusableCell(withType: CategoryPickerCell.self, for: indexPath)
            .configured(with: (category: categories[indexPath.row], selected: categories[indexPath.row].id == selectedCategory?.id))
        return cell
    }
}

