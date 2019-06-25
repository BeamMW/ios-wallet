//
// SendConfirmViewController.swift
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

class ConfirmItem {
    public var title:String!
    public var detail:String?
    public var detailFont:UIFont?
    public var detailColor:UIColor?

    required init(title:String!, detail:String?, detailFont:UIFont?, detailColor:UIColor?) {
        self.title = title
        self.detail = detail
        self.detailFont = detailFont
        self.detailColor = detailColor
    }
}

class SendConfirmViewController: BaseTableViewController {

    private lazy var footerView: UIView = {
        var view = UIView(frame: CGRect(x: 0, y: 0, width: UIScreen.main.bounds.size.width, height: 95))
        
        var sendButton = BMButton.defaultButton(frame: CGRect(x: (UIScreen.main.bounds.size.width-143)/2, y: 40, width: 143, height: 44), color: UIColor.main.heliotrope)
        sendButton.setImage(IconSendBlue(), for: .normal)
        sendButton.setTitle(Localizables.shared.strings.send.lowercased(), for: .normal)
        sendButton.setTitleColor(UIColor.main.marineOriginal, for: .normal)
        sendButton.setTitleColor(UIColor.main.marineOriginal.withAlphaComponent(0.5), for: .highlighted)
        sendButton.addTarget(self, action: #selector(onNext), for: .touchUpInside)
        view.addSubview(sendButton)
        
        
        return view
    }()
    
    private var items = [ConfirmItem]()
    private var password:String?
    private var passwordError:String?
    
    private var viewModel:SendTransactionViewModel!
    
    init(viewModel:SendTransactionViewModel!) {
        super.init(nibName: nil, bundle: nil)
        
        self.viewModel = viewModel
        self.items.append(contentsOf: self.viewModel.buildConfirmItems())
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
    
    override func viewDidLoad() {
        super.viewDidLoad()
                
        isGradient = true
        
        setGradientTopBar(mainColor: UIColor.main.heliotrope)
        
        title = Localizables.shared.strings.confirm.uppercased()
        
        tableView.register([ConfirmCell.self, BMFieldCell.self])
        
        tableView.delegate = self
        tableView.dataSource = self
        tableView.keyboardDismissMode = .interactive
        tableView.tableFooterView = footerView
    }
    
    @objc private func onTouchId() {
        if BiometricAuthorization.shared.canAuthenticate() && Settings.sharedManager().isEnableBiometric {
            
            BiometricAuthorization.shared.authenticateWithBioMetrics(success: { [weak self] in
                guard let strongSelf = self else { return }
                if KeychainManager.getPassword() != nil {
                    strongSelf.askForSaveContact()
                }
                
            }, failure: {
            }, retry: {
            })
        }
    }
     
    @objc private func onNext() {
        view.endEditing(true)
        
        if Settings.sharedManager().isNeedaskPasswordForSend {
            if let pass = password {
                if pass.isEmpty {
                    passwordError = Localizables.shared.strings.empty_password
                    tableView.reloadData()
                    tableView.scrollToRow(at: IndexPath(row: 0, section: items.count), at: .bottom, animated: true)
                }
                else if(AppModel.sharedManager().isValidPassword(pass) == false) {
                    passwordError = Localizables.shared.strings.incorrect_password
                    tableView.reloadData()
                    tableView.scrollToRow(at: IndexPath(row: 0, section: items.count), at: .bottom, animated: true)
                    return
                }
            }
            else{
                passwordError = Localizables.shared.strings.empty_password
                tableView.reloadData()
                tableView.scrollToRow(at: IndexPath(row: 0, section: items.count), at: .bottom, animated: true)
                return
            }
        }
        
        askForSaveContact()
    }
    
    private func askForSaveContact() {
        if viewModel.isNeedSaveContact() {
            if var controllers = self.navigationController?.viewControllers {
                controllers.removeLast()
                controllers.removeLast()
                
                let vc = SaveContactViewController(address: self.viewModel.toAddress)
                controllers.append(vc)
                self.navigationController?.setViewControllers(controllers, animated: true)
            }
            self.onSend(needBack: false)
        }
        else{
            self.onSend(needBack: true)
        }
    }
    
    private func onSend(needBack:Bool) {
        viewModel.send()
        
        if needBack {
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
}

extension SendConfirmViewController : UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let view = UIView()
        view.backgroundColor = UIColor.clear
        return view
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return (section > 0) ? 20 : 10
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
}


extension SendConfirmViewController : UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return items.count + (Settings.sharedManager().isNeedaskPasswordForSend ? 1 : 0)
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        if indexPath.section == items.count {
            var icon = (BiometricAuthorization.shared.canAuthenticate() && Settings.sharedManager().isEnableBiometric && Settings.sharedManager().isNeedaskPasswordForSend) ? IconTouchid() : nil
            
            if icon != nil {
                if BiometricAuthorization.shared.faceIDAvailable()  {
                    icon = IconFaceId()
                }
            }
            
            let cell = tableView
                .dequeueReusableCell(withType: BMFieldCell.self, for: indexPath)
                .configured(with: (name: Localizables.shared.strings.enter_password_title.uppercased(), value: password ?? "", rightIcon:icon))
            cell.delegate = self
            cell.error = passwordError
            cell.isSecure = true
            
            return cell
        }
        else{
            let cell =  tableView
                .dequeueReusableCell(withType: ConfirmCell.self, for: indexPath)
                .configured(with: items[indexPath.section])
            
            return cell
        }
    }
}

extension SendConfirmViewController : BMCellProtocol {
    
    func onRightButton(_ sender: UITableViewCell) {
        self.onTouchId()
    }
    
    func textValueDidBegin(_ sender: UITableViewCell) {
        if let path = tableView.indexPath(for: sender)  {
            tableView.scrollToRow(at: path, at: .middle, animated: true)
        }
    }
    
    func textValueDidChange(_ sender: UITableViewCell, _ text: String, _ input:Bool) {
        password = text
        
        UIView.performWithoutAnimation {
            tableView.beginUpdates()
            tableView.endUpdates()
        }
    }
}

