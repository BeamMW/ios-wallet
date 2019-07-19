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

class CategoryPickerViewController: BaseTableViewController {
    
    public var completion : (([String]?) -> Void)?

    private var categories:[BMCategory]!
    private var selectedCategories:[String]?
    private var currentCategories:[String]?

    private lazy var footerView: UIView = {
        
        let label = UILabel(frame: CGRect(x: defaultX, y: 30, width: defaultWidth, height: 0))
        label.font = RegularFont(size: 16)
        label.textColor = UIColor.main.steelGrey
        label.text = Localizable.shared.strings.create_categories_in_settings
        label.numberOfLines = 0
        label.textAlignment = .center
        label.sizeToFit()
        label.frame = CGRect(x: defaultX, y: 30, width: defaultWidth, height: label.frame.size.height);
        
        let view = UIView(frame: CGRect(x: 0, y: 0, width: UIScreen.main.bounds.size.width, height:0))
        view.addSubview(label)
        
        view.frame = CGRect(x: 0, y: 0, width: UIScreen.main.bounds.size.width, height:label.frame.origin.y + label.frame.size.height + 30)
        
        return view
    }()
    
    init(categories:[String]?) {
        super.init(nibName: nil, bundle: nil)
        
        self.currentCategories = categories
        self.selectedCategories = categories
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError(Localizable.shared.strings.fatalInitCoderError)
    }
    
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

        title = Localizable.shared.strings.categories

        addRightButton(title:Localizable.shared.strings.save, target: self, selector: #selector(onSave), enabled: false)

        categories = (AppModel.sharedManager().categories as! [BMCategory])
        categories.insert(BMCategory.none(), at: 0)
        
        tableView.delegate = self
        tableView.dataSource = self
        tableView.separatorColor = UIColor.white.withAlphaComponent(0.13)
        tableView.separatorStyle = .singleLine
        tableView.contentInsetAdjustmentBehavior = .never
        tableView.tableHeaderView = UIView(frame: CGRect(x: 0.0, y: 0.0, width: 0.0, height: 20))
        tableView.tableHeaderView?.backgroundColor = UIColor.main.marine
        tableView.register(CategoryPickerCell.self)
        tableView.register(BMEmptyCell.self)
        tableView.tableFooterView = footerView
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
    }
    
    @objc private func onSave(sender:UIBarButtonItem) {
        self.completion?(selectedCategories)
        self.back()
    }
}

extension CategoryPickerViewController : UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 50
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        if indexPath.row == 0 {
            selectedCategories?.removeAll()
            selectedCategories?.append("0")
        }
        else{
            var selected = false
            let category = categories[indexPath.row]
            
            var index:Int = 0
            if let s = selectedCategories {
                for c in s {
                    if category.id == Int32(c) {
                        selected = true
                        break
                    }
                    index = index + 1
                }
            }
            
            selectedCategories?.removeAll(where: { $0 == "0" })
            
            if !selected {
                selectedCategories?.append(String(category.id))
            }
            else{
                selectedCategories?.remove(at: index)
            }
        }
        
        enableRightButton(enabled: true)

        tableView.reloadData()
    }
}

extension CategoryPickerViewController : UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return categories.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        var selected = false
        let category = categories[indexPath.row]
        
        if let s = selectedCategories {
            for c in s {
                if category.id == Int32(c) {
                    selected = true
                }
            }
        }
        
        let cell =  tableView
            .dequeueReusableCell(withType: CategoryPickerCell.self, for: indexPath)
            .configured(with: (category: categories[indexPath.row], selected: selected))
        return cell
    }
}

