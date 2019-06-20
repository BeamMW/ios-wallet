//
// ReceiveListViewController.swift
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

class ReceiveListViewController: BaseTableViewController {
    
    public var completion : ((BMAddress) -> Void)?
    public var excepted:BMAddress?
    public var currenltyPicked:BMAddress?

    private var addresses = [BMAddress]()
    private var searchString = String.empty()
    
    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.font = BoldFont(size: 14)
        label.textColor = UIColor.main.blueyGrey
        label.text = LocalizableStrings.address.uppercased()
        label.adjustFontSize = true
        label.letterSpacing = 2
        return label
    }()
    
    private lazy var textField: BMField = {
        let field = BMField()
        field.font = RegularFont(size: 16)
        field.adjustFontSize = true
        field.tintColor = UIColor.white
        field.autocorrectionType = .no
        field.spellCheckingType = .no
        field.lineHeight = 1
        field.textColor = UIColor.white
        field.placeholder = LocalizableStrings.address_search
        field.placeHolderColor = UIColor.main.steelGrey
        field.delegate = self
        return field
    }()
    
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
        
        filterAddresses()
        
        var mainColor = UIColor.main.brightSkyBlue
        
        if let viewControllers = self.navigationController?.viewControllers{
            for vc in viewControllers {
                if vc is SendViewController {
                    mainColor = UIColor.main.heliotrope
                }
            }
        }
        
        setGradientTopBar(mainColor: mainColor)
        title = LocalizableStrings.change_address.uppercased()
                
        tableView.register([ReceiveAddressListCell.self, BMFieldCell.self, BMEmptyCell.self])
        
        tableView.delegate = self
        tableView.dataSource = self
        tableView.keyboardDismissMode = .interactive
        
        titleLabel.frame = CGRect(x: 15, y: 165, width: 200, height: 20)
        view.addSubview(titleLabel)
        
        textField.frame = CGRect(x: 15, y: 190, width: UIScreen.main.bounds.size.width-30, height: 32)
        textField.awakeFromNib()
        view.addSubview(textField)
    }
    
    override func viewDidLayoutSubviews() {
        
        tableView.frame = CGRect(x: 0, y: 240, width: self.view.bounds.width, height: self.view.bounds.size.height - 240)
    }
    

    private func filterAddresses() {
        if let addresses = AppModel.sharedManager().walletAddresses {
            self.addresses = addresses as! [BMAddress]
        }
        self.addresses = self.addresses.filter { $0.isExpired() == false}
        
        if !searchString.isEmpty {
            for add in self.addresses {
                if let category = AppModel.sharedManager().findCategory(byId: add.category) {
                    add.categoryName = category.name
                }
                else{
                    add.categoryName = String.empty()
                }
            }
            
            let filterdObjects = self.addresses.filter { $0.label.lowercased().contains(searchString.lowercased()) || $0.categoryName.lowercased().contains(searchString.lowercased()) ||
                $0.walletId.lowercased().starts(with: searchString.lowercased())
            }    
            self.addresses.removeAll()
            self.addresses.append(contentsOf: filterdObjects)
        }
    }
}

extension ReceiveListViewController : UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return  BMTableHeaderTitleView.boldHeight
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return addresses.count > 0 ? UITableView.automaticDimension : BMEmptyCell.height()
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        if addresses.count > 0 {
            completion?(addresses[indexPath.row])
            navigationController?.popViewController(animated: true)
        }
    }
}

extension ReceiveListViewController : UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return addresses.count == 0 ? 1 : addresses.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        if addresses.count == 0 {
            let cell = tableView
                .dequeueReusableCell(withType: BMEmptyCell.self, for: indexPath)
                .configured(with: LocalizableStrings.not_found)
            return cell
        }
        else{
            let cell = tableView
                .dequeueReusableCell(withType: ReceiveAddressListCell.self, for: indexPath).configured(with: (row: indexPath.row, address: addresses[indexPath.row]))
            
            cell.setItalic(autoGenerated: addresses[indexPath.row].walletId == excepted?.walletId, italic: addresses[indexPath.row].isDefault)
                        
            return cell
        }
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        
        let view =  BMTableHeaderTitleView(title: LocalizableStrings.existing_addresses.uppercased(), bold: true)
        view.letterSpacing = 2
        return view
    }
}

extension ReceiveListViewController : UITextFieldDelegate {
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        
        return true
    }

    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        
        let textFieldText: NSString = (textField.text ?? String.empty()) as NSString
        let txtAfterUpdate = textFieldText.replacingCharacters(in: range, with: string)
        
        searchString = txtAfterUpdate
        filterAddresses()
        tableView.reloadData()
        
        return true
    }
}
