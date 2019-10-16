//
//  BMDataPickerViewController.swift
//  BeamWallet
//
//  Created by Denis on 10/16/19.
//  Copyright © 2019 Denis. All rights reserved.
//

import UIKit

class BMDataPickerViewController: BaseTableViewController {
    enum DataType {
        case language
        case lock
        case log
        case address_expire
        case category
    }
    
    private var type: DataType!
    private var values = [BMPickerData]()
    private var selectedValue:Any?

    public var completion: ((Any?) -> Void)?
    
    init(type: DataType, selectedValue:Any? = nil) {
        super.init(nibName: nil, bundle: nil)
        
        self.type = type
        self.selectedValue = selectedValue
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError(Localizable.shared.strings.fatalInitCoderError)
    }
    
    override var isUppercasedTitle: Bool {
        get {
            return true
        }
        set {
            super.isUppercasedTitle = true
        }
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
    
    private func setValues() {
        switch type {
        case .language:
            let languages = Settings.sharedManager().languages().sorted { $0.id > $1.id }
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
            values.append(BMPickerData(title: Localizable.shared.strings.as_set, detail: nil, titleColor: UIColor.white, arrowType: BMPickerData.ArrowType.selected, unique: self.selectedValue))
            values.append(BMPickerData(title: Localizable.shared.strings.in_24_hours_now, detail: nil, titleColor: UIColor.white, arrowType: BMPickerData.ArrowType.unselected, unique: 24))
            values.append(BMPickerData(title: Localizable.shared.strings.never, detail: nil, titleColor: UIColor.white, arrowType: BMPickerData.ArrowType.unselected, unique: 0))
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

