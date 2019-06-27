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
    
    public var completion : ((BMCategory?) -> Void)?

    private var categories:[BMCategory]!
    private var selectedCategory:BMCategory?
    private var currentCategory:BMCategory?

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
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if isGradient {
            var mainColor = UIColor.main.brightSkyBlue
            
            if let viewControllers = self.navigationController?.viewControllers{
                for vc in viewControllers {
                    if vc is SendViewController {
                        mainColor = UIColor.main.heliotrope
                    }
                }
            }
            
            setGradientTopBar(mainColor: mainColor, addedStatusView: false)
        }
 
        title = Localizable.shared.strings.category

        addRightButton(title:Localizable.shared.strings.save, target: self, selector: #selector(onSave), enabled: false)

        categories = (AppModel.sharedManager().categories as! [BMCategory])
        categories.insert(BMCategory.none(), at: 0)
        
        tableView.delegate = self
        tableView.dataSource = self
        tableView.separatorColor = UIColor.white.withAlphaComponent(0.1)
        tableView.separatorStyle = .singleLine
        tableView.register(CategoryPickerCell.self)
        tableView.register(BMEmptyCell.self)
        tableView.tableFooterView = footerView
    }
    
    @objc private func onSave(sender:UIBarButtonItem) {
        self.completion?(selectedCategory)
        self.back()
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

