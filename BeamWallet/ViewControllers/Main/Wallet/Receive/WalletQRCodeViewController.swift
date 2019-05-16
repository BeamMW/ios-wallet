//
// WalletQRCodeViewController.swift
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

protocol WalletQRCodeViewControllerDelegate: AnyObject {
    func onCopyDone()
}

class WalletQRCodeViewController: BaseViewController {

    weak var delegate: WalletQRCodeViewControllerDelegate?

    private var address:BMAddress!
    private var amount:String?

    @IBOutlet weak private var addressLabel: UILabel!
    @IBOutlet weak private var codeView: QRCodeView!
    @IBOutlet weak private var shareAddress: UIButton!
    
    init(address:BMAddress, amount:String?) {
        super.init(nibName: nil, bundle: nil)
        
        self.address = address
        self.amount = amount
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError(LocalizableStrings.fatalInitCoderError)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        addressLabel.text = address.walletId
        
        if let category = AppModel.sharedManager().findCategory(byAddress: address.walletId)
        {
            let name = "(" + category.name + ")"
            let text = address.walletId + "\n" + name
            
            let range = (text as NSString).range(of: String(name))
            
            let attributedString = NSMutableAttributedString(string:text)
            attributedString.addAttribute(NSAttributedString.Key.foregroundColor, value: UIColor.init(hexString: category.color) , range: range)
            attributedString.addAttribute(NSAttributedString.Key.font, value: RegularFont(size: 14) , range: range)
            
            addressLabel.attributedText = attributedString
        }
        
        view.backgroundColor = UIColor.clear
        view.isOpaque = false
        
        let qrString = AppModel.sharedManager().generateQRCodeString(address.walletId, amount: amount)
        
        codeView.generateCode(qrString, foregroundColor: UIColor.white, backgroundColor: UIColor.clear)
        
        addSwipeToDismiss()
    }

    @IBAction func onShare(sender :UIButton) {
        let vc = UIActivityViewController(activityItems: [address.walletId ?? ""], applicationActivities: [])
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
        
    @IBAction func onClose(sender :UIButton) {
        dismiss(animated: true, completion:nil)
    }
}
