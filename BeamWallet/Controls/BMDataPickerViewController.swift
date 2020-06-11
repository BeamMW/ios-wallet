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
        case export_data
        case currency
        case notifications
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
        case .export_data:
            title = Localizable.shared.strings.export_data
            addRightButton(title: Localizable.shared.strings.export, target: self, selector: #selector(onRightButton), enabled: true)
        case .currency:
            title = Localizable.shared.strings.second_currency
        case .notifications:
            title = Localizable.shared.strings.notifications
        default:
            title = String.empty()
        }
        
        setValues()
        
        tableView.register(BMPickerCell.self)
        tableView.register(UINib(nibName: "BMPickerCell2", bundle: nil), forCellReuseIdentifier: "BMPickerCell2")
        tableView.register(UINib(nibName: "BMPickerCell3", bundle: nil), forCellReuseIdentifier: "BMPickerCell3")
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
                    case 4:
                        deleted.append(Localizable.shared.strings.categories.lowercased())
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
            else if deleted.count > 2 {
                str = deleted.joined(separator: ", ")
            }
            
            confirmAlert(title: Localizable.shared.strings.clear_data, message: Localizable.shared.strings.delete_data_text(str: str), cancelTitle: Localizable.shared.strings.cancel, confirmTitle: Localizable.shared.strings.delete, cancelHandler: { _ in
                
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
                        case 4:
                            AppModel.sharedManager().clearAllCategories()
                        default:
                            break
                        }
                    }
                }
                self.back()
            }
        }
        else if type == .category || type == .export_data {
            var selectedValues = [String]()
            for item in values {
                if item.arrowType == BMPickerData.ArrowType.selected {
                    if type == .category {
                        selectedValues.append(String(item.unique as! Int32))
                    }
                    else {
                        selectedValues.append(item.unique as! String)
                    }
                }
            }
            
            if type == .export_data {
                let data = AppModel.sharedManager().exportData(selectedValues)

                let date = Int64(Date().timeIntervalSince1970)
                let fileName = "wallet_data_\(date).dat"

                if let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
                    let fileURL = dir.appendingPathComponent(fileName)

                    do {
                        try data.write(to: fileURL, atomically: false, encoding: .utf8)

                        let vc = UIActivityViewController(activityItems: [fileURL], applicationActivities: [])
                        vc.completionWithItemsHandler = { (activityType, completed:Bool, returnedItems:[Any]?, error: Error?) in
                           if completed {
                                self.back()
                           }
                        }
                        vc.excludedActivityTypes = [UIActivity.ActivityType.postToFacebook, UIActivity.ActivityType.assignToContact, UIActivity.ActivityType.copyToPasteboard, UIActivity.ActivityType.print, UIActivity.ActivityType.openInIBooks]

                        self.present(vc, animated: true)
                    }
                    catch {}
                }
            }
            else{
                completion?(selectedValues)
                back()
            }
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
            values.append(BMPickerData(title: Localizable.shared.strings.in_24_hours_now, detail: nil, titleColor: UIColor.white, arrowType: BMPickerData.ArrowType.unselected, unique: Int32(24)))
            values.append(BMPickerData(title: Localizable.shared.strings.never, detail: nil, titleColor: UIColor.white, arrowType: BMPickerData.ArrowType.unselected, unique: Int32(0)))
        case .clear:
            values.append(BMPickerData(title: Localizable.shared.strings.delete_all_addresses, detail: nil, titleColor: UIColor.white, arrowType: BMPickerData.ArrowType.unselected, unique: 1, multiplie: true))
            values.append(BMPickerData(title: Localizable.shared.strings.delete_all_contacts, detail: nil, titleColor: UIColor.white, arrowType: BMPickerData.ArrowType.unselected, unique: 2, multiplie: true))
            values.append(BMPickerData(title: Localizable.shared.strings.delete_all_tags, detail: nil, titleColor: UIColor.white, arrowType: BMPickerData.ArrowType.unselected, unique: 4, multiplie: true))
            values.append(BMPickerData(title: Localizable.shared.strings.delete_all_transactions, detail: nil, titleColor: UIColor.white, arrowType: BMPickerData.ArrowType.unselected, unique: 3, multiplie: true))
        case .category:
            var selectedCategories = (selectedValue as! [String])
            if selectedCategories.count == 0 {
                selectedCategories.append("0")
            }
            
            let none = BMCategory.none()
            none.name = none.name.capitalizingFirstLetter()
           
            var categories = AppModel.sharedManager().sortedCategories() as! [BMCategory]
            categories.insert(none, at: 0)
            
            for category in categories {
                let selected = selectedCategories.contains(String(category.id))
                values.append(BMPickerData(title: category.name, detail: nil, titleColor: UIColor(hexString: category.color), arrowType: selected ? BMPickerData.ArrowType.selected : BMPickerData.ArrowType.unselected, unique: category.id, multiplie: true))
            }
        case .export_data:
            values.append(BMPickerData(title: Localizable.shared.strings.transaction_history, detail: nil, titleColor: UIColor.white, arrowType: BMPickerData.ArrowType.selected, unique: "transaction", multiplie: true))
            values.append(BMPickerData(title: Localizable.shared.strings.categories, detail: nil, titleColor: UIColor.white, arrowType: BMPickerData.ArrowType.selected, unique: "category", multiplie: true))
            values.append(BMPickerData(title: Localizable.shared.strings.addresses, detail: nil, titleColor: UIColor.white, arrowType: BMPickerData.ArrowType.selected, unique: "address", multiplie: true))
            values.append(BMPickerData(title: Localizable.shared.strings.contacts, detail: nil, titleColor: UIColor.white, arrowType: BMPickerData.ArrowType.selected, unique: "contact", multiplie: true))
        case .currency:
            var currencies = AppModel.sharedManager().currencies as! [BMCurrency]
            currencies.sort {
                $0.type < $1.type
            }
            
            values.append(BMPickerData(title: Localizable.shared.strings.off, detail: nil, titleColor: UIColor.white, arrowType: (BMCurrencyOff == Settings.sharedManager().currency) ? BMPickerData.ArrowType.selected : BMPickerData.ArrowType.unselected, unique: Int32(3)))

            for currency in currencies {
                values.append(BMPickerData(title: currency.currencyLongName(), detail: nil, titleColor: UIColor.white, arrowType: (currency.type == Settings.sharedManager().currency) ? BMPickerData.ArrowType.selected : BMPickerData.ArrowType.unselected, unique: currency.type))
            }            
        case .notifications:
            values.append(BMPickerData(title: Localizable.shared.strings.wallet_updates, detail: nil, titleColor: UIColor.white, arrowType: Settings.sharedManager().isNotificationWalletON ? BMPickerData.ArrowType.selected : BMPickerData.ArrowType.unselected, unique: Localizable.shared.strings.wallet_updates, multiplie: false, isSwitch: true))
            values.append(BMPickerData(title: Localizable.shared.strings.news, detail: nil, titleColor: UIColor.white, arrowType: Settings.sharedManager().isNotificationNewsON ? BMPickerData.ArrowType.selected : BMPickerData.ArrowType.unselected, unique: Localizable.shared.strings.news, multiplie: false, isSwitch: true))
          //  values.append(BMPickerData(title: Localizable.shared.strings.address_expiration, detail: nil, titleColor: UIColor.white, arrowType: Settings.sharedManager().isNotificationAddressON ? BMPickerData.ArrowType.selected : BMPickerData.ArrowType.unselected, unique: Localizable.shared.strings.address_expiration, multiplie: false, isSwitch: true))
            values.append(BMPickerData(title: Localizable.shared.strings.transaction_status, detail: nil, titleColor: UIColor.white, arrowType: Settings.sharedManager().isNotificationTransactionON ? BMPickerData.ArrowType.selected : BMPickerData.ArrowType.unselected, unique: Localizable.shared.strings.transaction_status, multiplie: false, isSwitch: true))
        
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
        case .clear, .export_data:
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
        case .currency:
            Settings.sharedManager().currency = data.unique as! BMCurrencyType
            completion?(data.unique)
            back()
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
        
        if type == .clear || type == .export_data {
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
       let value = values[indexPath.row]
        if value.multiplie {
            let cell = tableView
                .dequeueReusableCell(withIdentifier: "BMPickerCell2", for: indexPath) as! BMPickerCell
            cell.configure(data: values[indexPath.row])
            return cell
        }
        else if value.isSwitch {
            let cell = tableView
                .dequeueReusableCell(withIdentifier: "BMPickerCell3", for: indexPath) as! BMPickerCell
            cell.configure(data: values[indexPath.row])
            cell.delegate = self
            return cell
        }
        else{
            let cell = tableView
                .dequeueReusableCell(withType: BMPickerCell.self, for: indexPath)
            cell.configure(data: values[indexPath.row])
            return cell
        }

    }
}

extension BMDataPickerViewController: BMPickerCellDelegate {
    func onClickSwitch(value: Bool, cell: BMPickerCell) {
        if(type == .notifications) {
            if let indexPath = tableView.indexPath(for: cell) {
                let item = values[indexPath.row]
                item.arrowType = value ? BMPickerData.ArrowType.selected : BMPickerData.ArrowType.unselected
                if(item.title == Localizable.shared.strings.wallet_updates) {
                    Settings.sharedManager().isNotificationWalletON = value
                }
                else if(item.title == Localizable.shared.strings.news) {
                    Settings.sharedManager().isNotificationNewsON = value
                }
                else if(item.title == Localizable.shared.strings.transaction_status) {
                    Settings.sharedManager().isNotificationTransactionON = value
                }
                else if(item.title == Localizable.shared.strings.address_expiration) {
                    Settings.sharedManager().isNotificationAddressON = value
                }
                
                if(value) {
                    AppModel.sharedManager().getWalletStatus()
                }
            }
        }
    
    }
}

