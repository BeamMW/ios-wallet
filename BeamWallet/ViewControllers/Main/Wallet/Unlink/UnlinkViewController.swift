//
// UnlinkViewController.swift
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

class UnlinkViewController: BaseTableViewController {

    private let viewModel = UnlinkTransactionViewModel()

    override var tableStyle: UITableView.Style {
        get {
            return .grouped
        }
        set {
            super.tableStyle = newValue
        }
    }
    
    private lazy var footerView: UIView = {
        let view = UIView(frame: CGRect(x: 0, y: 0, width: UIScreen.main.bounds.size.width, height: 0))
        
        let button = BMButton.defaultButton(frame: CGRect(x: (UIScreen.main.bounds.size.width - 143) / 2, y: 60, width: 143, height: 44), color: UIColor.main.brightTeal.withAlphaComponent(0.1))
        button.setImage(IconNextPink()?.maskWithColor(color: UIColor.main.brightTeal), for: .normal)
        button.setTitle(Localizable.shared.strings.next.lowercased(), for: .normal)
        button.layer.borderWidth = 1
        button.layer.borderColor = UIColor.main.brightTeal.cgColor
        button.setTitleColor(UIColor.main.brightTeal, for: .normal)
        button.addTarget(self, action: #selector(onNext), for: .touchUpInside)
        view.addSubview(button)
        
        view.frame = CGRect(x: 0, y: 0, width: UIScreen.main.bounds.size.width, height: button.frame.origin.y + button.frame.size.height + 40)
        
        return view
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        setGradientTopBar(mainColor: UIColor.main.brightSkyBlue)
        
        title = Localizable.shared.strings.unlink.uppercased()
        
        tableView.register([SendAllCell.self, BMAmountCell.self, FeeCell.self])
        tableView.dataSource = self
        tableView.delegate = self
        tableView.keyboardDismissMode = .interactive
        tableView.tableFooterView = footerView
        tableView.contentInsetAdjustmentBehavior = .never
        tableView.tableHeaderView = UIView(frame: CGRect(x: 0.0, y: 0.0, width: 0.0, height: 1))
        tableView.tableHeaderView?.backgroundColor = UIColor.main.marine
        tableView.sectionHeaderHeight = 0.0
        tableView.sectionFooterHeight = 0.0
        
        addRightButton(image: Settings.sharedManager().isHideAmounts ? IconShowBalance() : IconHideBalance(), target: self, selector: #selector(onHideAmounts))
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        Settings.sharedManager().addDelegate(self)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        view.endEditing(true)
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        
        Settings.sharedManager().removeDelegate(self)
    }
    
    // MARK: - IBAction
    
    @objc private func onNext() {
      //  viewModel.send()
        if !viewModel.canSend() {
            tableView.reloadData()
            tableView.scrollToRow(at: IndexPath(row: 0, section: 0), at: .top, animated: false)
        }
        else {
           let vc = UnlinkConfirmViewController(viewModel: self.viewModel)
           pushViewController(vc: vc)
        }
    }
}


extension UnlinkViewController: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return 3
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0:
            return 2
        case 1:
            return Settings.sharedManager().isHideAmounts ? 0 : 1
        default:
            return 1
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch indexPath.section {
        case 0:
            if indexPath.row == 0 {
                let cell = tableView
                    .dequeueReusableCell(withType: BMAmountCell.self, for: indexPath)
                cell.setType(type:  BMTransactionType(BMTransactionTypePushTransaction))
                cell.delegate = self
                cell.error = viewModel.amountError
                cell.fee = Double(viewModel.fee) ?? 0
                cell.contentView.backgroundColor = UIColor.main.marineThree
                cell.configure(with: (name: Localizable.shared.strings.amount.uppercased(), value: viewModel.amount))
                return cell
            }
            else {
                var cell = tableView.dequeueReusableCell(withIdentifier: "cell")
                
                if cell == nil {
                    cell = SecondCell(style: .default, reuseIdentifier: "cell")
                    
                    cell?.textLabel?.textColor = UIColor.main.blueyGrey
                    cell?.textLabel?.font = RegularFont(size: 14)
                    
                    cell?.selectionStyle = .none
                    cell?.separatorInset = UIEdgeInsets.zero
                    cell?.indentationLevel = 0
                    
                    cell?.backgroundColor = UIColor.main.marineThree
                    cell?.contentView.backgroundColor = UIColor.clear
                }
                
                let fee = "+ \(viewModel.fee) GROTH " + Localizable.shared.strings.transaction_fee.lowercased()
                let second = AppModel.sharedManager().exchangeValue(Double(viewModel.amount) ?? 0)
                
                if viewModel.sendAll {
                    cell?.textLabel?.text = second + " (" + fee + ")"
                }
                else if (Double(viewModel.amount) ?? 0) > 0 {
                    cell?.textLabel?.text = second
                }
                else {
                    cell?.textLabel?.text = nil
                }
                
                if Settings.sharedManager().isDarkMode {
                    cell?.textLabel?.textColor = UIColor.main.steel
                }
                
                return cell!
            }
        case 1:
            let cell = tableView
                .dequeueReusableCell(withType: SendAllCell.self, for: indexPath).configured(with: (realAmount:  AppModel.sharedManager().walletStatus?.realAmount ?? 0, isAll: viewModel.sendAll, type: 1, onlyUnlink: false))
            cell.delegate = self
            return cell
        case 2:
            let cell = tableView
                .dequeueReusableCell(withType: FeeCell.self, for: indexPath)
                .configured(with: Double(viewModel.fee) ?? 0)
            cell.delegate = self
            cell.setType(type: 1)
            
            if Settings.sharedManager().isHideAmounts {
                cell.contentView.backgroundColor = UIColor.clear
            }
            else {
                cell.contentView.backgroundColor = UIColor.main.marineThree
            }
            
            return cell
        default:
            return BaseCell()
        }
    }
}

extension UnlinkViewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        let view = UIView()
        view.backgroundColor = UIColor.clear
        return view
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let view = UIView()
        if section == 0 || section == 2 {
            if section == 2 && !Settings.sharedManager().isHideAmounts {
                view.backgroundColor = UIColor.main.marineThree
            }
            else {
                view.backgroundColor = UIColor.clear
            }
        }
        else {
            view.backgroundColor = UIColor.clear
        }
        return view
    }
    
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        switch section {
        case 1:
            return Settings.sharedManager().isHideAmounts ? 0 : 25
        default:
            return 0
        }
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        switch section {
        case 1:
            return Settings.sharedManager().isHideAmounts ? 0 : 30
        case 2:
            return 15
        default:
            return 30
        }
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if indexPath.section == 0, indexPath.row == 1 {
            let amount = (Double(viewModel.amount) ?? 0)
            return ((viewModel.sendAll || amount > 0) ? 27 : 17)
        }
        return UITableView.automaticDimension
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
}

extension UnlinkViewController: BMCellProtocol {
    func textDidChangeStatus(_ sender: UITableViewCell) {

    }
    
    func textValueDidBegin(_ sender: UITableViewCell) {

    }
    
    func textValueDidChange(_ sender: UITableViewCell, _ text: String, _ input: Bool) {
        if let path = tableView.indexPath(for: sender) {
            if path.section == 0 {
                if input {
                    viewModel.sendAll = false
                    if let cell = tableView.findCell(SendAllCell.self) as? SendAllCell {
                        cell.configure(with: (realAmount: AppModel.sharedManager().walletStatus?.realAmount ?? 0, isAll: viewModel.sendAll, type: 1, onlyUnlink: false))
                    }
                }
                viewModel.amount = text
                tableView.reloadRows(at: [IndexPath(row: 1, section: 0)], with: .none)
            }
        }
    }
    
    func textValueDidReturn(_ sender: UITableViewCell) {
        if let path = tableView.indexPath(for: sender) {
            if path.section == 0 {
                viewModel.checkAmountError()
                UIView.performWithoutAnimation {
                    tableView.reloadData()
                }
            }
        }
    }
    
    func onRightButton(_ sender: UITableViewCell) {
        if let path = tableView.indexPath(for: sender) {
            if path.section == 1 {
                view.endEditing(true)
                viewModel.sendAll = true
                viewModel.checkFeeError()
                UIView.performWithoutAnimation {
                    tableView.reloadData()
                }
            }
        }
    }
    
    func onExpandCell(_ sender: UITableViewCell) {
 
    }
    
    func onDidChangeFee(value: Double) {
        viewModel.fee = String(Int(value))
        viewModel.checkAmountError()
        viewModel.checkFeeError()
        
        UIView.performWithoutAnimation {
            tableView.reloadData()
        }
    }
}

extension UnlinkViewController: SettingsModelDelegate {
    func onChangeHideAmounts() {
        addRightButton(image: Settings.sharedManager().isHideAmounts ? IconShowBalance() : IconHideBalance(), target: self, selector: #selector(onHideAmounts))
        
        if Settings.sharedManager().isHideAmounts {
            tableView.deleteRows(at: [IndexPath(row: 0, section: 1)], with: .fade)
        }
        else {
            tableView.insertRows(at: [IndexPath(row: 0, section: 1)], with: .fade)
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            self.tableView.reloadData()
        }
    }
}
