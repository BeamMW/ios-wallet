//
// EnterNodeAddressViewController.swift
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
import SVProgressHUD

class EnterNodeAddressViewController: BaseViewController {

    private var timeoutTimer = Timer()

    public var completion : ((Bool) -> Void)?
    private var isChangeNode = false
    private var oldAddress :String!
    
    @IBOutlet private weak var nodeAddressField: UITextField!
    @IBOutlet private weak var nodePortField: UITextField!
    @IBOutlet private weak var nodeAddressView: UIView!
    @IBOutlet private weak var nodePortView: UIView!

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "Change node"
        
        hideKeyboardWhenTappedAround()
        
        nodeAddressView.backgroundColor = UIColor.main.marineTwo
        nodePortView.backgroundColor = UIColor.main.marineTwo

        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Save", style: .plain, target: self, action: #selector(onSave))
        navigationItem.rightBarButtonItem?.tintColor = UIColor.main.brightTeal
        navigationItem.rightBarButtonItem?.isEnabled = false
        
        oldAddress = Settings.sharedManager().nodeAddress
        let split = oldAddress.split(separator: ":")
        if split.count == 2 {
            nodeAddressField.text = String(split[0])
            nodePortField.text = String(split[1])
        }
        else{
            nodeAddressField.text = oldAddress
        }
        
        AppModel.sharedManager().addDelegate(self)
        
        nodePortField.addTarget(self, action: #selector(textFieldDidChange(_:)), for: .editingChanged)
        nodeAddressField.addTarget(self, action: #selector(textFieldDidChange(_:)), for: .editingChanged)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        
        AppModel.sharedManager().removeDelegate(self)
    }
    
    @objc func textFieldDidChange(_ textField: BMField) {
        if let address = nodeAddressField.text, let port = nodePortField.text {
            let fullAddress = address + ":" + port
            
            if fullAddress != oldAddress {
                navigationItem.rightBarButtonItem?.isEnabled = true
            }
            else{
                navigationItem.rightBarButtonItem?.isEnabled = false
            }
        }
    }
    
    @objc private func onSave() {
        view.endEditing(true)
        
        if let address = nodeAddressField.text, let port = nodePortField.text {
            let fullAddress = address + ":" + port
            if AppModel.sharedManager().isValidNodeAddress(fullAddress) {
                
                if fullAddress != oldAddress {
                    isChangeNode = true
                    
                    Settings.sharedManager().nodeAddress = fullAddress
                    
                    AppModel.sharedManager().changeNodeAddress()
                    
                    if !AppModel.sharedManager().isLoggedin {
                        completion?(true)
                        self.navigationController?.popViewController(animated: true)
                    }
                    else{
                        self.timeoutTimer = Timer.scheduledTimer(timeInterval: 10.0, target: self, selector: #selector(onTimeOut), userInfo: nil, repeats: false)

                        SVProgressHUD.show()
                    }
                }
                else{
                    completion?(true)
                    self.navigationController?.popViewController(animated: true)
                }
            }
            else{
               self.alert(title: "Incompatible node", message: "You’re trying to connect to an incompatible peer.", handler: nil)
            }
        }
    }
    
    @objc private func onTimeOut() {
        self.isChangeNode = false

        SVProgressHUD.dismiss()

        self.alert(title: "Incompatible node", message: "You’re trying to connect to an incompatible peer.", handler: nil)
    }
}


extension EnterNodeAddressViewController : UITextFieldDelegate {
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()

        return true
    }
}

extension EnterNodeAddressViewController : WalletModelDelegate {
    func onNetwotkStatusChange(_ connected: Bool) {
        
        DispatchQueue.main.async {
            SVProgressHUD.dismiss()
            
            self.timeoutTimer.invalidate()
            
            if self.isChangeNode && AppModel.sharedManager().isLoggedin {
                self.isChangeNode = false
                
                if connected {
                    self.completion?(true)
                    self.navigationController?.popViewController(animated: true)
                }
                else{
                    Settings.sharedManager().nodeAddress = self.oldAddress
                    AppModel.sharedManager().changeNodeAddress()
                    
                    self.alert(title: "Incompatible node", message: "You’re trying to connect to an incompatible peer.", handler: nil)
                }
            }
        }
    }
}
