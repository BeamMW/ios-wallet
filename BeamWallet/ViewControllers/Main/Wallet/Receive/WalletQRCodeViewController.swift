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

protocol WalletQRCodeViewControllerDelegate: AnyObject {
    func onCopyDone()
}

class WalletQRCodeViewController: BaseViewController {

    weak var delegate: WalletQRCodeViewControllerDelegate?

    private var address:String!
    private var amount:String?

    @IBOutlet weak private var addressLabel: UILabel!
    @IBOutlet weak private var codeView: QRCodeView!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        addressLabel.text = address
        
        view.backgroundColor = UIColor.clear
        view.isOpaque = false
        
        var qrString = "beam:\(address ?? "")"
        
        if let a = self.amount {
            if let d = Double(a.replacingOccurrences(of: ",", with: "."))
            {
                if d > 0 {
                    qrString = qrString + "?amount=\(a)"
                }
            }
        }
        
        codeView.generateCode(qrString, foregroundColor: UIColor.white, backgroundColor: UIColor.clear)
        
        addSwipeToDismiss()
    }

    
    @IBAction func onShare(sender :UIButton) {
        if let address = addressLabel.text {
            let vc = UIActivityViewController(activityItems: [address], applicationActivities: [])
            vc.completionWithItemsHandler = {(activityType: UIActivity.ActivityType?, completed: Bool, returnedItems: [Any]?, error: Error?) in
                if completed {
                    self.dismiss(animated: true, completion: {
                        self.delegate?.onCopyDone()
                    })
                    return
                }
            }
            
            vc.excludedActivityTypes = [UIActivity.ActivityType.assignToContact, UIActivity.ActivityType.print,UIActivity.ActivityType.openInIBooks]
            
            self.present(vc, animated: true)
        }
    }
    
    @IBAction func onClose(sender :UIButton) {
        dismiss(animated: true, completion:nil)
    }

}


extension WalletQRCodeViewController {
    
    func withAddress(address: String, amount:String?) -> Self {
        
        self.address = address
        self.amount = amount
        
        return self
    }
}
