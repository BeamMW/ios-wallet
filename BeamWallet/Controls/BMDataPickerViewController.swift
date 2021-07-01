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
        case clear
        case export_data
        case currency
        case notifications
        case sendCurrency
        case max_privacy_lock
    }
    
    private var type: DataType!
    private var values = [BMPickerData]()
   
    public var selectedValue: Any?
    public var completion: ((Any?) -> Void)?
    public var isAutoSelect = true
    
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
        case .clear:
            title = Localizable.shared.strings.clear_data
            addRightButton(title: Localizable.shared.strings.done, target: self, selector: #selector(onRightButton), enabled: false)
        case .export_data:
            title = Localizable.shared.strings.export_data
            addRightButton(title: Localizable.shared.strings.export, target: self, selector: #selector(onRightButton), enabled: true)
        case .currency:
            title = Localizable.shared.strings.second_currency
        case .sendCurrency:
            title = Localizable.shared.strings.choose_currency
        case .notifications:
            title = Localizable.shared.strings.notifications
        case .max_privacy_lock:
            title = Localizable.shared.strings.lock_time_limit
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
                        default:
                            break
                        }
                    }
                }
                self.back()
            }
        }
        else if  type == .export_data {
            var selectedValues = [String]()
            for item in values {
                if item.arrowType == BMPickerData.ArrowType.selected {
                    selectedValues.append(item.unique as! String)
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
          //  values.append(BMPickerData(title: Localizable.shared.strings.as_set, detail: nil, titleColor: UIColor.white, arrowType: BMPickerData.ArrowType.selected, unique: selectedValue))
            values.append(BMPickerData(title: Localizable.shared.strings.in_24_hours_now, detail: nil, titleColor: UIColor.white, arrowType: selectedValue as! Int32 == 24 ? BMPickerData.ArrowType.selected : BMPickerData.ArrowType.unselected, unique: Int32(24)))
            values.append(BMPickerData(title: Localizable.shared.strings.never, detail: nil, titleColor: UIColor.white, arrowType: selectedValue as! Int32 == 0 ? BMPickerData.ArrowType.selected : BMPickerData.ArrowType.unselected, unique: Int32(0)))
        case .clear:
            values.append(BMPickerData(title: Localizable.shared.strings.delete_all_addresses, detail: nil, titleColor: UIColor.white, arrowType: BMPickerData.ArrowType.unselected, unique: 1, multiplie: true))
            values.append(BMPickerData(title: Localizable.shared.strings.delete_all_contacts, detail: nil, titleColor: UIColor.white, arrowType: BMPickerData.ArrowType.unselected, unique: 2, multiplie: true))
           // values.append(BMPickerData(title: Localizable.shared.strings.delete_all_tags, detail: nil, titleColor: UIColor.white, arrowType: BMPickerData.ArrowType.unselected, unique: 4, multiplie: true))
            values.append(BMPickerData(title: Localizable.shared.strings.delete_all_transactions, detail: nil, titleColor: UIColor.white, arrowType: BMPickerData.ArrowType.unselected, unique: 3, multiplie: true))
        case .export_data:
            values.append(BMPickerData(title: Localizable.shared.strings.transaction_history, detail: nil, titleColor: UIColor.white, arrowType: BMPickerData.ArrowType.selected, unique: "transaction", multiplie: true))
            values.append(BMPickerData(title: Localizable.shared.strings.addresses, detail: nil, titleColor: UIColor.white, arrowType: BMPickerData.ArrowType.selected, unique: "address", multiplie: true))
            values.append(BMPickerData(title: Localizable.shared.strings.contacts, detail: nil, titleColor: UIColor.white, arrowType: BMPickerData.ArrowType.selected, unique: "contact", multiplie: true))
        case .sendCurrency:
            let beam = BMCurrency()
            beam.type = BMCurrencyType(BEAM)
            
            let usd = BMCurrency()
            usd.type = BMCurrencyType(BMCurrencyUSD)
            
            let btc = BMCurrency()
            btc.type = BMCurrencyType(BMCurrencyBTC)
            
            let eth = BMCurrency()
            eth.type = BMCurrencyType(BMCurrencyETH)
            
            let selected = selectedValue as! Int
            
            values.append(BMPickerData(title: beam.currencyLongName(), detail: nil, titleColor: UIColor.white, arrowType: (beam.type == BMCurrencyType(selected)) ? BMPickerData.ArrowType.selected : BMPickerData.ArrowType.unselected, unique: beam.type))
            values.append(BMPickerData(title: usd.currencyLongName(), detail: nil, titleColor: UIColor.white, arrowType: (usd.type == BMCurrencyType(selected)) ? BMPickerData.ArrowType.selected : BMPickerData.ArrowType.unselected, unique: usd.type))
            values.append(BMPickerData(title: btc.currencyLongName(), detail: nil, titleColor: UIColor.white, arrowType: (btc.type == BMCurrencyType(selected)) ? BMPickerData.ArrowType.selected : BMPickerData.ArrowType.unselected, unique: btc.type))
            values.append(BMPickerData(title: eth.currencyLongName(), detail: nil, titleColor: UIColor.white, arrowType: (eth.type == BMCurrencyType(selected)) ? BMPickerData.ArrowType.selected : BMPickerData.ArrowType.unselected, unique: eth.type))


            
        case .currency:
          //  values.append(BMPickerData(title: Localizable.shared.strings.off, detail: nil, titleColor: UIColor.white, arrowType: (BMCurrencyOff == Settings.sharedManager().currency) ? BMPickerData.ArrowType.selected : BMPickerData.ArrowType.unselected, unique: Int32(3)))
            
            let usd = BMCurrency()
            usd.type = BMCurrencyType(BMCurrencyUSD)
            
            let btc = BMCurrency()
            btc.type = BMCurrencyType(BMCurrencyBTC)
            
            let eth = BMCurrency()
            eth.type = BMCurrencyType(BMCurrencyETH)
            
            values.append(BMPickerData(title: usd.currencyLongName(), detail: nil, titleColor: UIColor.white, arrowType: (usd.type == Settings.sharedManager().currency) ? BMPickerData.ArrowType.selected : BMPickerData.ArrowType.unselected, unique: usd.type))
            values.append(BMPickerData(title: btc.currencyLongName(), detail: nil, titleColor: UIColor.white, arrowType: (btc.type == Settings.sharedManager().currency) ? BMPickerData.ArrowType.selected : BMPickerData.ArrowType.unselected, unique: btc.type))
            values.append(BMPickerData(title: eth.currencyLongName(), detail: nil, titleColor: UIColor.white, arrowType: (eth.type == Settings.sharedManager().currency) ? BMPickerData.ArrowType.selected : BMPickerData.ArrowType.unselected, unique: eth.type))
            
        case .notifications:
            values.append(BMPickerData(title: Localizable.shared.strings.wallet_updates, detail: nil, titleColor: UIColor.white, arrowType: Settings.sharedManager().isNotificationWalletON ? BMPickerData.ArrowType.selected : BMPickerData.ArrowType.unselected, unique: Localizable.shared.strings.wallet_updates, multiplie: false, isSwitch: true))
          //  values.append(BMPickerData(title: Localizable.shared.strings.news, detail: nil, titleColor: UIColor.white, arrowType: Settings.sharedManager().isNotificationNewsON ? BMPickerData.ArrowType.selected : BMPickerData.ArrowType.unselected, unique: Localizable.shared.strings.news, multiplie: false, isSwitch: true))
          //  values.append(BMPickerData(title: Localizable.shared.strings.address_expiration, detail: nil, titleColor: UIColor.white, arrowType: Settings.sharedManager().isNotificationAddressON ? BMPickerData.ArrowType.selected : BMPickerData.ArrowType.unselected, unique: Localizable.shared.strings.address_expiration, multiplie: false, isSwitch: true))
            values.append(BMPickerData(title: Localizable.shared.strings.transaction_status, detail: nil, titleColor: UIColor.white, arrowType: Settings.sharedManager().isNotificationTransactionON ? BMPickerData.ArrowType.selected : BMPickerData.ArrowType.unselected, unique: Localizable.shared.strings.transaction_status, multiplie: false, isSwitch: true))
        case .max_privacy_lock:
            let locks = Settings.sharedManager().maxPrivacyLockValues()
            for lock in locks {
                values.append(BMPickerData(title: lock.name, detail: nil, titleColor: UIColor.white, arrowType: (lock.hours == Settings.sharedManager().lockMaxPrivacyValue) ? BMPickerData.ArrowType.selected : BMPickerData.ArrowType.unselected, unique: lock.hours))
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
        case .currency:
            if isAutoSelect {
                Settings.sharedManager().currency = data.unique as! BMCurrencyType
            }
            completion?(data.unique)
            back()
        case .sendCurrency:
            completion?(data.unique)
            back()
        case .max_privacy_lock:
            Settings.sharedManager().lockMaxPrivacyValue = data.unique as! Int32
            AppModel.sharedManager().setMaxPrivacyLockTime(data.unique as! Int32)
            
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

