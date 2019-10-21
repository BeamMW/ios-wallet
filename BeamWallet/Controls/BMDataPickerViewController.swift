//
// BMDataPickerViewController.swift
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

class BMDataPickerViewController: BaseTableViewController {
    enum DataType {
        case language
        case lock
        case log
        case address_expire
        case category
        case clear
    }
    
    private var type: DataType!
    private var values = [BMPickerData]()
    private var selectedValue: Any?
    
    public var completion: ((Any?) -> Void)?
    
    init(type: DataType, selectedValue: Any? = nil) {
        super.init(nibName: nil, bundle: nil)
        
        self.type = type
        self.selectedValue = selectedValue
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
        
        setGradientTopBar(mainColor: UIColor.main.peacockBlue, addedStatusView: AppModel.sharedManager().isLoggedin)
        
        switch type {
        case .language:
            title = Localizable.shared.strings.language
        case .lock:
            title = Localizable.shared.strings.lock_screen
        case .log:
            title = Localizable.shared.strings.save_wallet_logs
        case .address_expire:
            title = Localizable.shared.strings.exp_date
        case .category:
            title = Localizable.shared.strings.categories
            addRightButton(title: Localizable.shared.strings.save, target: self, selector: #selector(onRightButton), enabled: false)
        case .clear:
            title = Localizable.shared.strings.clear_data
            addRightButton(title: Localizable.shared.strings.done, target: self, selector: #selector(onRightButton), enabled: false)
        default:
            title = String.empty()
        }
        
        setValues()
        
        tableView.register(BMPickerCell.self)
        tableView.separatorColor = UIColor.white.withAlphaComponent(0.13)
        tableView.separatorStyle = .singleLine
        tableView.dataSource = self
        tableView.delegate = self
        tableView.contentInsetAdjustmentBehavior = .never
        tableView.tableHeaderView = UIView(frame: CGRect(x: 0.0, y: 0.0, width: 0.0, height: 20))
        tableView.tableHeaderView?.backgroundColor = UIColor.main.marine
        tableView.backgroundColor = UIColor.main.marine
    }
    
    @objc private func onRightButton() {
        if type == .clear {
            var deleted = [String]()
            
            for item in values {
                if item.arrowType == BMPickerData.ArrowType.selected {
                    switch item.unique as! Int {
                    case 1:
                        deleted.append(Localizable.shared.strings.addresses.lowercased())
                    case 2:
                        deleted.append(Localizable.shared.strings.contacts.lowercased())
                    case 3:
                        deleted.append(Localizable.shared.strings.transactions.lowercased())
                    default:
                        break
                    }
                }
            }
            
            var str = String.empty()
            if deleted.count == 1 {
                str = deleted.joined(separator: String.empty())
            }
            else if deleted.count == 2 {
                str = deleted.joined(separator: " \(Localizable.shared.strings.and) ")
            }
            else if deleted.count == 3 {
                str = deleted.joined(separator: ", ")
            }
            
            confirmAlert(title: Localizable.shared.strings.clear_data, message: Localizable.shared.strings.delete_data_text(str: str), cancelTitle: Localizable.shared.strings.cancel, confirmTitle: Localizable.shared.strings.clear, cancelHandler: { _ in
                
            }) { _ in
                for item in self.values {
                    if item.arrowType == BMPickerData.ArrowType.selected {
                        switch item.unique as! Int {
                        case 1:
                            AppModel.sharedManager().clearAllAddresses()
                        case 2:
                            AppModel.sharedManager().clearAllContacts()
                        case 3:
                            AppModel.sharedManager().clearAllTransactions()
                        default:
                            break
                        }
                    }
                }
                self.back()
            }
        }
        else if type == .category {
            var newSelectedCategories = [String]()
              for item in values {
                  if item.arrowType == BMPickerData.ArrowType.selected {
                      newSelectedCategories.append(String(item.unique as! Int32))
                  }
              }
            completion?(newSelectedCategories)
            back()
        }
    }
    
    private func setValues() {
        switch type {
        case .language:
            let languages = Settings.sharedManager().languages()
            for language in languages {
                values.append(BMPickerData(title: language.localName, detail: language.enName, titleColor: UIColor.white, arrowType: (language.code == Settings.sharedManager().language) ? BMPickerData.ArrowType.selected : BMPickerData.ArrowType.unselected, unique: language.code))
            }
        case .lock:
            let locks = Settings.sharedManager().lockScreenValues()
            for lock in locks {
                values.append(BMPickerData(title: lock.name, detail: nil, titleColor: UIColor.white, arrowType: (lock.seconds == Settings.sharedManager().lockScreenSeconds) ? BMPickerData.ArrowType.selected : BMPickerData.ArrowType.unselected, unique: lock.seconds))
            }
        case .log:
            let logs = Settings.sharedManager().logValues()
            for log in logs {
                values.append(BMPickerData(title: log.name, detail: nil, titleColor: UIColor.white, arrowType: (log.days == Settings.sharedManager().logDays) ? BMPickerData.ArrowType.selected : BMPickerData.ArrowType.unselected, unique: log.days))
            }
        case .address_expire:
            values.append(BMPickerData(title: Localizable.shared.strings.as_set, detail: nil, titleColor: UIColor.white, arrowType: BMPickerData.ArrowType.selected, unique: selectedValue))
            values.append(BMPickerData(title: Localizable.shared.strings.in_24_hours_now, detail: nil, titleColor: UIColor.white, arrowType: BMPickerData.ArrowType.unselected, unique: 24))
            values.append(BMPickerData(title: Localizable.shared.strings.never, detail: nil, titleColor: UIColor.white, arrowType: BMPickerData.ArrowType.unselected, unique: 0))
        case .clear:
            values.append(BMPickerData(title: Localizable.shared.strings.delete_all_addresses, detail: nil, titleColor: UIColor.white, arrowType: BMPickerData.ArrowType.unselected, unique: 1, multiplie: true))
            values.append(BMPickerData(title: Localizable.shared.strings.delete_all_contacts, detail: nil, titleColor: UIColor.white, arrowType: BMPickerData.ArrowType.unselected, unique: 2, multiplie: true))
            values.append(BMPickerData(title: Localizable.shared.strings.delete_all_transactions, detail: nil, titleColor: UIColor.white, arrowType: BMPickerData.ArrowType.unselected, unique: 3, multiplie: true))
        case .category:
            var selectedCategories = (selectedValue as! [String])
            if selectedCategories.count == 0 {
                selectedCategories.append("0")
            }
            let none = BMCategory.none()
            none.name = none.name.capitalizingFirstLetter()
            var categories = (AppModel.sharedManager().categories as! [BMCategory])
            categories.insert(none, at: 0)
            for category in categories {
                let selected = selectedCategories.contains(String(category.id))
                values.append(BMPickerData(title: category.name, detail: nil, titleColor: UIColor(hexString: category.color), arrowType: selected ? BMPickerData.ArrowType.selected : BMPickerData.ArrowType.unselected, unique: category.id, multiplie: true))
            }
        default:
            break
        }
    }
    
    private func onSave(data: BMPickerData) {
        switch type {
        case .language:
            Settings.sharedManager().language = data.unique as! String
            Localizable.shared.reset()
            Settings.sharedManager().language = data.unique as! String
            AppModel.sharedManager().getUTXO()
            AppModel.sharedManager().getWalletStatus()
            AppModel.sharedManager().refreshAddresses()
            completion?(data.unique)
            back()
        case .lock:
            Settings.sharedManager().lockScreenSeconds = data.unique as! Int32
            completion?(data.unique)
            back()
        case .log:
            Settings.sharedManager().logDays = data.unique as! Int32
            completion?(data.unique)
            back()
        case .address_expire:
            if data.title != Localizable.shared.strings.as_set {
                completion?(data.unique)
            }
            back()
        case .clear:
            if data.arrowType == BMPickerData.ArrowType.selected {
                data.arrowType = BMPickerData.ArrowType.unselected
            }
            else {
                data.arrowType = BMPickerData.ArrowType.selected
            }
            var isAllDisabled = true
            for item in values {
                if item.arrowType == BMPickerData.ArrowType.selected {
                    isAllDisabled = false
                }
            }
            enableRightButton(enabled: !isAllDisabled)
        case .category:
            let id = data.unique as! Int32
            if id == 0 {
                for item in values {
                    item.arrowType = BMPickerData.ArrowType.unselected
                }
                data.arrowType = BMPickerData.ArrowType.selected
            }
            else {
                if data.arrowType == BMPickerData.ArrowType.selected {
                    data.arrowType = BMPickerData.ArrowType.unselected
                }
                else {
                    data.arrowType = BMPickerData.ArrowType.selected
                }
                var isAllDisabled = true
                for item in values {
                    if item.arrowType == BMPickerData.ArrowType.selected && (item.unique as! Int32) > 0 {
                        isAllDisabled = false
                    }
                }
                if isAllDisabled {
                    values[0].arrowType = BMPickerData.ArrowType.selected
                }
                else{
                    values[0].arrowType = BMPickerData.ArrowType.unselected
                }
            }
            let oldSelectedCategories = (selectedValue as! [String])
            var newSelectedCategories = [String]()
            for item in values {
                if item.arrowType == BMPickerData.ArrowType.selected {
                    newSelectedCategories.append(String(item.unique as! Int32))
                }
            }
            var sorted1 = (oldSelectedCategories.sorted { $0.localizedCaseInsensitiveCompare($1) == ComparisonResult.orderedAscending }).joined(separator:"")
            let sorted2 = (newSelectedCategories.sorted { $0.localizedCaseInsensitiveCompare($1) == ComparisonResult.orderedAscending }).joined(separator:"")
            if sorted1.isEmpty && sorted2 == "0" {
                sorted1 = "0"
            }
            enableRightButton(enabled: sorted1 != sorted2)
        default:
            break
        }
    }
}

extension BMDataPickerViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        onSave(data: values[indexPath.row])
        
        if type == .clear {
            tableView.reloadRows(at: [indexPath], with: .none)
        }
        else if type == .category {
            tableView.reloadData()
        }
    }
}

extension BMDataPickerViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return values.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView
            .dequeueReusableCell(withType: BMPickerCell.self, for: indexPath)
        cell.configure(data: values[indexPath.row])
        return cell
    }
}

