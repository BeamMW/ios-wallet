//
// SaveContactViewController.swift
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

class SaveContactViewController: BaseTableViewController {

    private var address:String!
    private var name = ""
    private var category:BMCategory?

    private lazy var footerView: UIView = {
        let view = UIView(frame: CGRect(x: 0, y: 0, width: UIScreen.main.bounds.size.width, height: 110))
        
        let mainView = UIView(frame: CGRect(x: (UIScreen.main.bounds.size.width-300)/2, y: 60, width: 300, height: 44))
        
        let buttonCancel = BMButton.defaultButton(frame: CGRect(x:0, y: 0, width: 143, height: 44), color: UIColor.main.darkSlateBlue)
        buttonCancel.setImage(IconCancel(), for: .normal)
        buttonCancel.setTitle(LocalizableStrings.cancel, for: .normal)
        buttonCancel.setTitleColor(UIColor.white, for: .normal)
        buttonCancel.setTitleColor(UIColor.white.withAlphaComponent(0.5), for: .highlighted)
        buttonCancel.addTarget(self, action: #selector(onBack), for: .touchUpInside)
        mainView.addSubview(buttonCancel)
        
        let buttonSave = BMButton.defaultButton(frame: CGRect(x: mainView.frame.size.width - 143, y: 0, width: 143, height: 44), color: UIColor.main.heliotrope)
        buttonSave.setImage(IconDoneBlue(), for: .normal)
        buttonSave.setTitle(LocalizableStrings.save, for: .normal)
        buttonSave.setTitleColor(UIColor.main.marineOriginal, for: .normal)
        buttonSave.setTitleColor(UIColor.main.marineOriginal.withAlphaComponent(0.5), for: .highlighted)
        buttonSave.addTarget(self, action: #selector(onSave), for: .touchUpInside)
        mainView.addSubview(buttonSave)
        
        view.addSubview(mainView)
        
        return view
    }()
    
    init(address:String) {
        super.init(nibName: nil, bundle: nil)
        
        self.address = address
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError(LocalizableStrings.fatalInitCoderError)
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
        
        isGradient = true
        
        setGradientTopBar(mainColor: UIColor.main.heliotrope)
        
        title = LocalizableStrings.save_address_title.uppercased()
        
        tableView.register([BMFieldCell.self, ConfirmCell.self, BMDetailCell.self])
        
        tableView.delegate = self
        tableView.dataSource = self
        tableView.keyboardDismissMode = .interactive
        tableView.tableFooterView = footerView
        
       // hideKeyboardWhenTappedAround()
    }
    
    @objc private func onSave() {
        AppModel.sharedManager().addContact(address, name: name, category: String(category?.id ?? 0))
        onBack()
    }
    
    @objc private func onBack() {
        if let viewControllers = self.navigationController?.viewControllers{
            for vc in viewControllers {
                if vc is WalletViewController {
                    self.navigationController?.popToViewController(vc, animated: true)
                    return
                }
                else if vc is AddressViewController {
                    self.navigationController?.popToViewController(vc, animated: true)
                    return
                }
            }
        }
        
        self.navigationController?.popToRootViewController(animated: true)
    }
}

extension SaveContactViewController : UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let view = UIView()
        view.backgroundColor = UIColor.clear
        return view
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        switch section {
        case 0:
            return 10
        case 2:
            return 40
        default:
            return 30
        }
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        if indexPath.section == 2 {
            if AppModel.sharedManager().categories.count == 0 {
                self.alert(title: LocalizableStrings.categories_empty_title, message: LocalizableStrings.categories_empty_text, handler: nil)
            }
            else{
                let vc  = CategoryPickerViewController(category: self.category)
                vc.completion = {
                    obj in
                    if let category = obj {
                        self.category = category
                        self.tableView.reloadRow(BMDetailCell.self)
                    }
                }
                vc.isGradient = true
                pushViewController(vc: vc)
            }
        }
    }
}

extension SaveContactViewController : UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 3
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        switch indexPath.section {
        case 0:
            let item = ConfirmItem(title: LocalizableStrings.address.uppercased(), detail: self.address, detailFont: RegularFont(size: 16), detailColor: UIColor.white)
            let cell =  tableView
                .dequeueReusableCell(withType: ConfirmCell.self, for: indexPath)
                .configured(with: item)
            return cell
        case 1:
            let cell = tableView
                .dequeueReusableCell(withType: BMFieldCell.self, for: indexPath)
                .configured(with: (name: LocalizableStrings.name.uppercased(), value: name, rightIcon:nil))
            cell.delegate = self
            return cell
        case 2:
            let cell = tableView
                .dequeueReusableCell(withType: BMDetailCell.self, for: indexPath)
                .configured(with: (title: LocalizableStrings.category.uppercased(), value: category?.name ?? String.empty(), valueColor: UIColor.init(hexString: category?.color ?? "#FFFFFF")))
            cell.contentView.backgroundColor = UIColor.clear
            return cell
        default:
            return BaseCell()
        }
    }
}

extension SaveContactViewController : BMCellProtocol {
    
    func textValueDidBegin(_ sender: UITableViewCell) {
        if let path = tableView.indexPath(for: sender)  {
            tableView.scrollToRow(at: path, at: .middle, animated: true)
        }
    }
    
    func textValueDidChange(_ sender: UITableViewCell, _ text: String, _ input:Bool) {
        name = text
        
        UIView.performWithoutAnimation {
            tableView.beginUpdates()
            tableView.endUpdates()
        }
    }
}
