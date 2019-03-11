//
//  WalletReceiveViewController.swift
//  BeamWallet
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
import SelectItemController

class WalletReceiveViewController: UIViewController {

    @IBOutlet weak private var statusLabel: UILabel!
    @IBOutlet weak private var statusView: UIView!
    @IBOutlet weak private var addressLabel: UILabel!
    @IBOutlet weak private var expireLabel: UILabel!
    @IBOutlet weak private var mainStack: UIStackView!

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "Receive"
        
        hideKeyboardWhenTappedAround()
        
        addressLabel.text = AppModel.sharedManager().walletAddress?.walletId
        
        onNetwotkStatusChange(AppModel.sharedManager().isConnected)
        
        if Device.screenType == .iPhone_XSMax || Device.screenType == .iPhones_6Plus_6sPlus_7Plus_8Plus {
            mainStack.spacing = 70
        }
        else if Device.screenType == .iPhones_5_5s_5c_SE {
            mainStack.spacing = 50
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        AppModel.sharedManager().addDelegate(self)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        AppModel.sharedManager().removeDelegate(self)
    }
    
    //MARK: IBAction
    
    @IBAction func onExpire(sender :UIButton) {
        let items = ["24 hours", "Never"]
        let params = Parameters(title: "Expires", items: items, cancelButton: "Cancel")
        
        SelectItemController().show(parent: self, params: params) { (index) in
            if let index = index, let address = self.addressLabel.text {
                if index == 0 {
                    self.expireLabel.text = "24 hours"
                    AppModel.sharedManager().setExpires(24, toAddress: address)
                }
                else{
                    self.expireLabel.text = "Never"
                    AppModel.sharedManager().setExpires(0, toAddress: address)
                }
            } 
        }
    }
    
    @IBAction func onCopy(sender :UIButton) {
        UIPasteboard.general.string = addressLabel.text

        SVProgressHUD.showSuccess(withStatus: "copied to clipboard")
        SVProgressHUD.dismiss(withDelay: 1.5)
    }
    
    @IBAction func onQRCode(sender :UIButton) {
        let modalViewController = WalletQRCodeViewController().withAddress(address: addressLabel.text!)
        modalViewController.modalPresentationStyle = .overCurrentContext
        modalViewController.modalTransitionStyle = .crossDissolve
        present(modalViewController, animated: true, completion: nil)
    }
    
}

extension WalletReceiveViewController: WalletModelDelegate {
    func onNetwotkStatusChange(_ connected: Bool) {
        DispatchQueue.main.async {
            if connected {
                self.statusView.backgroundColor = UIColor.main.green
                self.statusLabel.text = "online (testnet)"
                self.statusLabel.textColor = UIColor.main.blueyGrey
            }
            else{
                self.statusView.backgroundColor = UIColor.main.red
                self.statusLabel.text = "offline (testnet)"
                self.statusLabel.textColor = UIColor.main.red
            }
        }
    }
}

// MARK: TextField Actions
extension WalletReceiveViewController : UITextFieldDelegate {
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        
        if let comment = textField.text, let address = addressLabel.text {
            AppModel.sharedManager().setWalletComment(comment, toAddress: address)
        }
    }
}

