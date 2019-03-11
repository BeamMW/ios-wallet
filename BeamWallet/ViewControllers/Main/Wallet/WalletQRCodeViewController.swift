//
//  WalletQRCodeViewController.swift
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

class WalletQRCodeViewController: UIViewController {

    private var address:String!
    
    @IBOutlet weak private var addressLabel: UILabel!
    @IBOutlet weak private var codeView: QRCodeView!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        addressLabel.text = address
        
        view.backgroundColor = UIColor.clear
        view.isOpaque = false
        
        codeView.generateCode(address, foregroundColor: UIColor.white, backgroundColor: UIColor.clear)
    }

    @IBAction func onCopy(sender :UIButton) {
        UIPasteboard.general.string = addressLabel.text
        
        SVProgressHUD.showSuccess(withStatus: "copied to clipboard")
        SVProgressHUD.dismiss(withDelay: 1.5)
    }
    
    @IBAction func onClose(sender :UIButton) {
        dismiss(animated: true, completion: nil)
    }

}


extension WalletQRCodeViewController {
    
    func withAddress(address: String) -> Self {
        
        self.address = address
        
        return self
    }
}
