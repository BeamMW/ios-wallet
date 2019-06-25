//
// BuyBeamCurrencyPicker.swift
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

class BuyBeamCurrencyPicker: BaseTableViewController {
    
    public var completion : ((String?) -> Void)?
    
    private var selectedCurrency:String?
    private var currencyCurrency:String?

    init(currency:String?) {
        super.init(nibName: nil, bundle: nil)
        
        self.selectedCurrency = currency
        self.currencyCurrency = currency
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError(Localizables.shared.strings.fatalInitCoderError)
    }
    
    override var isUppercasedTitle: Bool {
        get{
            return true
        }
        set{
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
        
        setGradientTopBar(mainColor: UIColor.main.heliotrope, addedStatusView: false)

        title = Localizables.shared.strings.you_send
        
        addRightButton(title:Localizables.shared.strings.save, target: self, selector: #selector(onSave), enabled: false)
        
        tableView.delegate = self
        tableView.dataSource = self
        tableView.separatorColor = UIColor.white.withAlphaComponent(0.1)
        tableView.separatorStyle = .singleLine
        tableView.register(CategoryPickerCell.self)
        tableView.register(BMEmptyCell.self)
    }
    
    @objc private func onSave(sender:UIBarButtonItem) {
        self.completion?(selectedCurrency)
        self.navigationController?.popViewController(animated: true)
    }
}

extension BuyBeamCurrencyPicker : UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 50
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        selectedCurrency = CryptoWolfManager.sharedManager.availableCurrencies[indexPath.row]
        
        if currencyCurrency != nil {
            enableRightButton(enabled: (currencyCurrency == selectedCurrency) ? false : true)
        }
        else{
            enableRightButton(enabled: true)
        }
        
        tableView.reloadData()
    }
}

extension BuyBeamCurrencyPicker : UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return CryptoWolfManager.sharedManager.availableCurrencies.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let name = CryptoWolfManager.sharedManager.availableCurrencies[indexPath.row]
        let fullname = CryptoWolfManager.sharedManager.fullName(coin: name)
        let title = fullname + " (" + name + ")"
        
        let cell = tableView
            .dequeueReusableCell(withType: CategoryPickerCell.self, for: indexPath)
        
        cell.simpleConfigure(with: (name: title, selected: name == selectedCurrency))
        
        return cell
    }
}

