//
// PreviewQRViewController.swift
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

class PreviewQRViewController: BaseViewController {

    private var address:BMAddress!
    private var oldAddress:BMAddress!
    private var codeView:QRCodeView!
    private var fromMore = false
    private var addressLabel:UILabel!

    init(address:BMAddress) {
        super.init(nibName: nil, bundle: nil)
        
        self.address = address
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError(LocalizableStrings.fatalInitCoderError)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let qrString = AppModel.sharedManager().generateQRCodeString(address.walletId, amount: nil)
        
        codeView = QRCodeView(frame: CGRect(x: (UIScreen.main.bounds.size.width-200)/2, y: 40 , width: 200, height: 200))
        codeView.generateCode(qrString, foregroundColor: UIColor.white, backgroundColor: UIColor.clear)
        view.addSubview(codeView)
        
        let addressString = LocalizableStrings.address + ":" + "\n\n" + address.walletId
        
        let range = (addressString as NSString).range(of: String(LocalizableStrings.address + ":"))
        
        let attributedString = NSMutableAttributedString(string:addressString)
        attributedString.addAttribute(NSAttributedString.Key.font, value: BoldFont(size: 14) , range: range)
        attributedString.addAttribute(NSAttributedString.Key.foregroundColor, value: UIColor.white , range: range)

        addressLabel = UILabel(frame: CGRect(x: 30, y: 260, width: UIScreen.main.bounds.size.width-60, height: 0))
        addressLabel.numberOfLines = 0
        addressLabel.font = RegularFont(size: 14)
        addressLabel.textColor = UIColor.main.steelGrey
        addressLabel.textAlignment = .center
        addressLabel.attributedText = attributedString
        addressLabel.sizeToFit()
        view.addSubview(addressLabel)
    }
    
    public func didShow() {
        title = LocalizableStrings.qr_code
        
        addRightButton(image: MoreIcon(), target: self, selector: #selector(onMore))
        
        self.addCustomBackButton(target: self, selector: #selector(onLeftBackButton))
        
        codeView.y = codeView.y + navigationBarOffset
        addressLabel.y = addressLabel.y + navigationBarOffset
    }
    

    @objc private func onMore(sender:UIBarButtonItem) {
        fromMore = true
        
        let items = [BMPopoverMenu.BMPopoverMenuItem(name: LocalizableStrings.copy_address, icon: nil, action:.copy_address), BMPopoverMenu.BMPopoverMenuItem(name: LocalizableStrings.share_qr_code, icon: nil, action:.show_qr_code)]
        
        BMPopoverMenu.show(menuArray: items, done: { (selectedItem) in
            if let item = selectedItem {
                switch (item.action) {
                case .show_qr_code:
                  self.onShare()
                case .copy_address:
                  self.onCopy()
                default:
                    return
                }
            }
        }, cancel: {
            
        })
    }
    
    private func onShare() {
        if let image = codeView.snapshot(), let topVC = UIApplication.getTopMostViewController() {
            let activityItem: [AnyObject] = [image]
            let vc = UIActivityViewController(activityItems: activityItem, applicationActivities: [])
            vc.completionWithItemsHandler = {(activityType: UIActivity.ActivityType?, completed: Bool, returnedItems: [Any]?, error: Error?) in
                
                if completed && self.fromMore {
                    self.navigationController?.popViewController(animated: true)
                }
            }
            
            vc.excludedActivityTypes = [UIActivity.ActivityType.assignToContact, UIActivity.ActivityType.print,UIActivity.ActivityType.openInIBooks]
            
            topVC.present(vc, animated: true)
        }
    }
    
    private func onCopy() {
        UIPasteboard.general.string = self.address.walletId
        ShowCopied()
        
        if fromMore {
            navigationController?.popViewController(animated: true)
        }
    }

    override var previewActionItems: [UIPreviewActionItem] {
        
        let action1 = UIPreviewAction(title: LocalizableStrings.share_qr_code,
                                      style: .default,
                                      handler: { previewAction, viewController in
                                        self.onShare()
        })
        
        let action2 = UIPreviewAction(title: LocalizableStrings.copy_address,
                                      style: .default,
                                      handler: { previewAction, viewController in
                                        self.onCopy()
        })
        
        return [action1, action2]
    }
}
