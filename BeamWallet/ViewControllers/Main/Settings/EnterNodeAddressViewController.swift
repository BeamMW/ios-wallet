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

    public var completion : ((Bool) -> Void)?
    private var oldAddress :String!
    
    @IBOutlet private weak var nodeAddressField: UITextField!
    @IBOutlet private weak var nodeAddressView: UIView!

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "ip:port"
        
        hideKeyboardWhenTappedAround()
        
        nodeAddressView.backgroundColor = UIColor.main.marineTwo

        addRightButton(title:"Save", targer: self, selector: #selector(onSave), enabled: false)

        oldAddress = Settings.sharedManager().nodeAddress
        nodeAddressField.text = oldAddress
        
        nodeAddressField.addTarget(self, action: #selector(textFieldDidChange(_:)), for: .editingChanged)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
    }
    
    @objc func textFieldDidChange(_ textField: UITextField) {
        if let address = nodeAddressField.text {
            
            if address.isEmpty {
                enableRightButton(enabled: false)
            }
            else{
                enableRightButton(enabled: (address != oldAddress ) ? true : false )
            }
        }
    }
    
    @objc private func onSave() {
        view.endEditing(true)
        
        if let fullAddress = nodeAddressField.text {
     
            if AppModel.sharedManager().isValidNodeAddress(fullAddress) {
                
                if fullAddress != oldAddress {
                    Settings.sharedManager().nodeAddress = fullAddress
                    
                    AppModel.sharedManager().changeNodeAddress()
                    
                    completion?(true)
                    
                    self.navigationController?.popViewController(animated: true)
                }
                else{
                    completion?(true)
                    
                    self.navigationController?.popViewController(animated: true)
                }
            }
            else{
               self.alert(title: "Invalid address", message: "The provided node address is invalid.\n Please, check if the entered address is correct", handler: nil)
            }
        }
    }
}


extension EnterNodeAddressViewController : UITextFieldDelegate {
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()

        return true
    }
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {

        let textFieldText: NSString = (textField.text ?? "") as NSString
        
        let txtAfterUpdate = textFieldText.replacingCharacters(in: range, with: string)
        
        if txtAfterUpdate.countInstances(of: ":") > 1 {
            return false
        }
        else if txtAfterUpdate.contains(":") {
            let splited = txtAfterUpdate.split(separator: ":")
            if splited.count == 2 {
                let port = String(splited[1])
                let portRange = (txtAfterUpdate as NSString).range(of: String(port))

                if port.isEmpty == false && string == ":" {
                    return false
                }
                else if range.intersection(portRange) != nil || port.lengthOfBytes(using: .utf8) == 1 {
                    return (port.isNumeric() && port.isValidPort())
                }
            }
        }
        
        return true
    }
}
