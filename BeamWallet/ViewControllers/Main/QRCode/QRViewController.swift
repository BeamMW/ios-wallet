//
// QRViewController.swift
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

protocol QRViewControllerDelegate: AnyObject {
    func onCopyDone()
}

class QRViewController: BaseViewController {

    weak var delegate: QRViewControllerDelegate?
    public var onShared : (() -> Void)?

    private var address:BMAddress!
    private var amount:String?

    @IBOutlet weak private var addressLabel: UILabel!
    @IBOutlet weak private var categoryLabel: UILabel!
    
    @IBOutlet weak private var amountStack: UIStackView!
    @IBOutlet weak private var amountLabel: UILabel!

    @IBOutlet weak private var visualEffectView: UIVisualEffectView!

    @IBOutlet weak private var codeConentView: UIView!
    @IBOutlet weak private var codeView: QRCodeView!
    @IBOutlet weak private var shareAddress: UIButton!
    
    @IBOutlet private var scrollView: UIScrollView!
    @IBOutlet private var mainView: BaseView!

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
        
        view.backgroundColor = UIColor.clear
        view.isOpaque = false
        
        addressLabel.text = address.walletId
        
        if let category = AppModel.sharedManager().findCategory(byAddress: address.walletId)
        {
            categoryLabel.isHidden = false
            categoryLabel.text = category.name
            categoryLabel.textColor = UIColor.init(hexString: category.color)
        }
        else{
            categoryLabel.isHidden = true
        }
        
        if let a = amount, !a.isEmpty {
            amountStack.isHidden = false
            amountLabel.text = LocalizableStrings.beam_amount(a)
        }
        else{
            amountStack.isHidden = true
        }
        
        let qrString = AppModel.sharedManager().generateQRCodeString(address.walletId, amount: amount)
        
        codeView.generateCode(qrString, foregroundColor: UIColor.white, backgroundColor: UIColor.clear)
        
        addSwipeToDismiss()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        if mainView.frame.size.height > (self.view.frame.size.height - 40)
        {
            visualEffectView.isHidden = true
            
            view.backgroundColor = mainView.backgroundColor
            view.isOpaque = true
            
            mainView.removeFromSuperview()
            scrollView.addSubview(mainView)

            mainView.translatesAutoresizingMaskIntoConstraints = true
            mainView.frame = CGRect(x: 0, y: 15, width: view.frame.size.width, height: mainView.frame.size.height)
            
            scrollView.contentSize = CGSize(width: 0, height: mainView.frame.size.height + 15)
        }
    }
    
    @IBAction func onShare(sender :UIButton) {
        if let image = codeConentView.snapshot() {
            let activityItem: [AnyObject] = [image]
            let vc = UIActivityViewController(activityItems: activityItem, applicationActivities: [])
            vc.completionWithItemsHandler = {(activityType: UIActivity.ActivityType?, completed: Bool, returnedItems: [Any]?, error: Error?) in
                if completed {
                    self.dismiss(animated: true, completion: {
                        if activityType == UIActivity.ActivityType.copyToPasteboard {
                            ShowCopied()
                        }
                        self.delegate?.onCopyDone()
                        self.onShared?()
                    })
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
