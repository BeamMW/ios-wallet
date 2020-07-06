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
    private var isToken = false

    @IBOutlet weak private var infoLabel: UILabel!

    @IBOutlet weak private var addressTitleLabel: UILabel!
    @IBOutlet weak private var addressLabel: UILabel!
    @IBOutlet weak private var categoryLabel: UILabel!
    
    @IBOutlet weak private var amountStack: UIStackView!
    @IBOutlet weak private var amountLabel: UILabel!
    @IBOutlet weak private var amountTitleLabel: UILabel!

    @IBOutlet weak private var codeConentView: UIView!
    @IBOutlet weak private var codeView: QRCodeView!
    @IBOutlet weak private var shareAddress: UIButton!
    
    @IBOutlet private weak var scrollView: UIScrollView!
    @IBOutlet private weak var mainView: BaseView!

    @IBOutlet weak private var secondAvailableLabel: UILabel!

    init(address:BMAddress, amount:String?, isToken: Bool) {
        super.init(nibName: nil, bundle: nil)
        
        self.isToken = isToken
        self.address = address
        self.amount = amount
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError(Localizable.shared.strings.fatalInitCoderError)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
                
        secondAvailableLabel.textColor = Settings.sharedManager().isDarkMode ? UIColor.main.steel : UIColor.main.blueyGrey
        secondAvailableLabel.font = RegularFont(size: 14)
        
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        
        if let image = appDelegate.window?.snapshot() {
            let blured = image.blurredImage(withRadius: 10, iterations: 5, tintColor: UIColor.main.blurBackground)
            let imageView = UIImageView(frame: UIScreen.main.bounds)
            imageView.image = blured
            view.insertSubview(imageView, at: 0)
        }
        
        mainView.addShadow(offset: CGSize(width: 0, height: -5), color: UIColor.black, opacity: 0.3, radius: 5)
        
        amountTitleLabel.text = Localizable.shared.strings.requested_amount.uppercased()
        
        infoLabel.text = Localizable.shared.strings.send_qr_secure + "\n\n" + Localizable.shared.strings.receive_notice
        
        addressTitleLabel.text = Localizable.shared.strings.transaction_token.uppercased()
       
        if isToken {
            addressLabel.text = address.token
        }
        else {
            addressLabel.text = address.walletId
        }
        
        if address.categories.count > 0
        {
            categoryLabel.attributedText = address.categoriesName()
            categoryLabel.isHidden = address.categoriesName().length > 0 ? false : true
        }
        else{
            categoryLabel.isHidden = true
        }
        
        if let a = amount, !a.isEmpty {
            amountStack.isHidden = false
            
            let amount = Double(a) ?? 0

            amountLabel.text = Localizable.shared.strings.beam_amount(a)
            
            if amount > 0 {
                secondAvailableLabel.isHidden = false
                secondAvailableLabel.text = AppModel.sharedManager().exchangeValue(amount)
            }
        }
        else{
            amountStack.isHidden = true
        }
        
        let qrString = AppModel.sharedManager().generateQRCodeString((isToken ? address.token : address.walletId) ?? String.empty(), amount: amount)
        
        codeView.generateCode(qrString, foregroundColor: UIColor.white, backgroundColor: UIColor.clear)
        
        addSwipeToDismiss()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        if mainView.frame.size.height > (self.view.frame.size.height - 40)
        {
            view.backgroundColor = mainView.backgroundColor
            
            mainView.removeFromSuperview()
            scrollView.addSubview(mainView)

            mainView.translatesAutoresizingMaskIntoConstraints = true
            mainView.frame = CGRect(x: 0, y: 15, width: view.frame.size.width, height: mainView.frame.size.height)
            
            scrollView.contentSize = CGSize(width: 0, height: mainView.frame.size.height + 15)
        }
        else if Settings.sharedManager().isDarkMode {
            mainView.backgroundColor = UIColor.main.twilightBlue2
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
