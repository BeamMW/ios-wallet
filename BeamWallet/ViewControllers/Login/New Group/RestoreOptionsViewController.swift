//
// RestoreOptionsViewController.swift
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

class RestoreOptionsViewController: BaseTableViewController {

    private var password:String!
    private var phrase:String!
    
    init(password:String, phrase:String) {
        super.init(nibName: nil, bundle: nil)

        self.password = password
        self.phrase = phrase
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError(Localizable.shared.strings.fatalInitCoderError)
    }
    
    private lazy var footerView: UIView = {
        var view = UIView(frame: CGRect(x: 0, y: 0, width: UIScreen.main.bounds.size.width, height: Device.screenType == .iPhones_5 ? 100 : 150))
        view.backgroundColor = UIColor.clear
        var nextButton = BMButton.defaultButton(frame: CGRect(x: (UIScreen.main.bounds.size.width-253)/2, y: Device.screenType == .iPhones_5 ? 50 : 100, width: 253, height: 44), color: UIColor.main.brightTeal)
        nextButton.setImage(IconNextBlue(), for: .normal)
        nextButton.setTitle(Localizable.shared.strings.next.lowercased(), for: .normal)
        nextButton.setTitleColor(UIColor.main.marineOriginal, for: .normal)
        nextButton.setTitleColor(UIColor.main.marineOriginal.withAlphaComponent(0.5), for: .highlighted)
        nextButton.addTarget(self, action: #selector(onNext), for: .touchUpInside)
        view.addSubview(nextButton)
        
        return view
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        title = Localizable.shared.strings.restore_wallet_title
        
        tableView.register([RestoreOptionCell.self])
        tableView.delegate = self
        tableView.dataSource = self
        tableView.tableFooterView = footerView
        tableView.tableHeaderView = UIView(frame: CGRect(x: 0, y: 0, width: 320, height: 10))
        
        AppModel.sharedManager().restoreType = BMRestoreType(BMRestoreAutomatic)
    }
        
    
    @objc private func onNext() {
        if AppModel.sharedManager().restoreType == BMRestoreAutomatic {
            self.confirmAlert(title:Localizable.shared.strings.restore_wallet_title , message: Localizable.shared.strings.auto_restore_warning, cancelTitle: Localizable.shared.strings.cancel, confirmTitle: Localizable.shared.strings.understand, cancelHandler: { (_ ) in
                
            }) { (_ ) in
                Settings.sharedManager().connectToRandomNode = true
                Settings.sharedManager().nodeAddress = AppModel.chooseRandomNode()

                let vc = CreateWalletProgressViewController(password: self.password, phrase: self.phrase)
                self.pushViewController(vc: vc)
            }
        }
        else{
            self.confirmAlert(title:Localizable.shared.strings.restore_wallet_title , message: Localizable.shared.strings.manual_restore_warning, cancelTitle: Localizable.shared.strings.cancel, confirmTitle: Localizable.shared.strings.understand, cancelHandler: { (_ ) in
                
            }) { (_ ) in
                let created = AppModel.sharedManager().createWallet(self.phrase, pass: self.password)
                if(!created)
                {
                    self.alert(title: Localizable.shared.strings.error, message: Localizable.shared.strings.wallet_not_created) { (_ ) in
                        if AppModel.sharedManager().isInternetAvailable {
                            self.navigationController?.popToRootViewController(animated: true)
                        }
                        else{
                            DispatchQueue.main.async {
                                self.back()
                            }
                        }
                    }
                }
                else{
                    SVProgressHUD.show()
                    AppModel.sharedManager().exportOwnerKey(self.password) {[weak self] (key) in
                        SVProgressHUD.dismiss()
                        
                        guard let strongSelf = self else { return }

                        let vc = OwnerKeyViewController()
                        vc.ownerKey = key
                        strongSelf.pushViewController(vc: vc)
                    }
                }
            }
        }
    }
}

extension RestoreOptionsViewController : UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let view = UIView()
        view.backgroundColor = UIColor.clear
        return view
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return (section == 1 ? 40 : 1)
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        AppModel.sharedManager().restoreType = (indexPath.section == 0 ? BMRestoreType(BMRestoreAutomatic) : BMRestoreType(BMRestoreManual))
        
        tableView.reloadData()
    }
}

extension RestoreOptionsViewController : UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let title = (indexPath.section == 0 ? Localizable.shared.strings.automatic_restore_title : Localizable.shared.strings.manual_restore_title)
        let text = (indexPath.section == 0 ? Localizable.shared.strings.automatic_restore_text : Localizable.shared.strings.manual_restore_text)
        let icon = (indexPath.section == 0 ? IconCloud() : IconManual())
        var selected = false
        
        if indexPath.section == 0 && AppModel.sharedManager().restoreType == BMRestoreAutomatic {
            selected = true
        }
        else if indexPath.section == 1 && AppModel.sharedManager().restoreType == BMRestoreManual {
            selected = true
        }
        
        let cell = tableView
            .dequeueReusableCell(withType: RestoreOptionCell.self, for: indexPath)
        cell.delegate = self
        cell.configure(with: (icon: icon, title: title, detail: text, selected: selected))

        return cell
    }
}

extension RestoreOptionsViewController : BMCellProtocol {
    func onRightButton(_ sender: UITableViewCell) {
        if let indexPath = tableView.indexPath(for: sender) {
            AppModel.sharedManager().restoreType = (indexPath.section == 0 ? BMRestoreType(BMRestoreAutomatic) : BMRestoreType(BMRestoreManual))
            tableView.reloadData()
        }
    }
}
