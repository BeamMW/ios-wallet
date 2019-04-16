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

class WalletReceiveViewController: BaseViewController {

    @IBOutlet weak private var addressLabel: UILabel!
    @IBOutlet weak private var expireLabel: UILabel!
    @IBOutlet weak private var mainStack: UIStackView!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = "Receive"
        
        hideKeyboardWhenTappedAround()
        
        addressLabel.text = AppModel.sharedManager().walletAddress?.walletId
                
        if Device.screenType == .iPhone_XSMax || Device.screenType == .iPhones_Plus {
            mainStack.spacing = 70
        }
        else if Device.screenType == .iPhones_5 {
            mainStack.spacing = 50
        }
    }
    
    //MARK: IBAction
    
    @IBAction func onExpire(sender :UIButton) {
        
        if let address = self.addressLabel.text {
            
            let alert = UIAlertController(title: "Expires", message: nil, preferredStyle: .actionSheet)
            
            alert.addAction(UIAlertAction(title: "24 hours", style: .default , handler:{ (UIAlertAction)in
                self.expireLabel.text = "24 hours"
                
                AppModel.sharedManager().setExpires(24, toAddress: address)
            }))
            
            alert.addAction(UIAlertAction(title: "Never", style: .default , handler:{ (UIAlertAction)in
                self.expireLabel.text = "Never"
                
                AppModel.sharedManager().setExpires(0, toAddress: address)
            }))
            
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler:{ (UIAlertAction)in
            }))
            
            self.present(alert, animated: true)
        }
    }
    
    @IBAction func onCopy(sender :UIButton) {
        UIPasteboard.general.string = addressLabel.text

        SVProgressHUD.showSuccess(withStatus: "copied to clipboard")
        SVProgressHUD.dismiss(withDelay: 1.5)
        
        self.navigationController?.popViewController(animated: true)
    }
    
    @IBAction func onQRCode(sender :UIButton) {
        let modalViewController = WalletQRCodeViewController().withAddress(address: addressLabel.text!)
        modalViewController.delegate = self
        modalViewController.modalPresentationStyle = .overFullScreen
        modalViewController.modalTransitionStyle = .crossDissolve
        present(modalViewController, animated: true, completion: nil)
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

extension WalletReceiveViewController : WalletQRCodeViewControllerDelegate {
    func onCopyDone() {
        self.navigationController?.popViewController(animated: true)
    }
}

