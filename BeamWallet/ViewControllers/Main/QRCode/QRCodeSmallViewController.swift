//
// QRCodeSmallViewController.swift
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


class QRCodeSmallViewController: BaseViewController {
    
    weak var delegate: QRViewControllerDelegate?
    public var onShared : (() -> Void)?
        
    @IBOutlet weak private var infoLabel: UILabel!
    @IBOutlet weak private var codeConentView: UIView!
    @IBOutlet weak private var codeView: QRCodeView!
    @IBOutlet private weak var mainView: BaseView!
        
    private var qrString = ""
    
    init(qrString:String) {
        super.init(nibName: nil, bundle: nil)
        
        self.qrString = qrString
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError(Localizable.shared.strings.fatalInitCoderError)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        
        if let image = appDelegate.window?.snapshot() {
            let blured = image.blurredImage(withRadius: 10, iterations: 5, tintColor: UIColor.main.blurBackground)
            let imageView = UIImageView(frame: UIScreen.main.bounds)
            imageView.image = blured
            view.insertSubview(imageView, at: 0)
        }
        
        mainView.addShadow(offset: CGSize(width: 0, height: -5), color: UIColor.black, opacity: 0.3, radius: 5)
                
        infoLabel.text = Localizable.shared.strings.receive_notice
                
        codeView.generateCode(qrString, foregroundColor: UIColor.white, backgroundColor: UIColor.clear)
        
        addSwipeToDismiss()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
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
