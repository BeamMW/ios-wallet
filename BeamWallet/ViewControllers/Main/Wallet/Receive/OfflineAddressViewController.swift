//
//  OfflineAddressViewController.swift
//  BeamWallet
//
//  Created by Denis on 02.11.2020.
//  Copyright © 2020 Denis. All rights reserved.
//

import UIKit

class OfflineAddressViewController: BaseViewController {

    @IBOutlet weak private var infoLabel: UILabel!
    @IBOutlet weak private var addressTitleLabel: UILabel!
    @IBOutlet weak private var addressLabel: UILabel!
    @IBOutlet weak private var codeView: QRCodeView!
    @IBOutlet weak private var shqreButton: BMButton!
    @IBOutlet weak private var codeConentView: UIView!

    private var address = ""

    override func viewDidLoad() {
        super.viewDidLoad()

        setGradientTopBar(mainColor: UIColor.main.peacockBlue, addedStatusView: true)

        title = Localizable.shared.strings.offline_address.uppercased()
        
        topOffset?.constant = topOffset!.constant - 20

        shqreButton.backgroundColor = UIColor.main.marineThree;
        shqreButton.awakeFromNib()
        
        addressTitleLabel.text = Localizable.shared.strings.address.uppercased()
        infoLabel.text = Localizable.shared.strings.public_offline_address_info
        addressLabel.text = nil

        if Settings.sharedManager().isDarkMode {
            shqreButton.setTitleColor(UIColor.white, for: .normal)
            infoLabel.textColor = UIColor.main.steel;
            addressTitleLabel.textColor = UIColor.main.steel;
        }
        
        
        AppModel.sharedManager().getPublicAddress {[weak self] (address) in
            DispatchQueue.main.async {
                self?.address = address
                self?.addressLabel.text = address
                self?.codeView.generateCode(address, foregroundColor: UIColor.white, backgroundColor: UIColor.clear)
            }
        }
    }

    @IBAction private func onCopy() {
        UIPasteboard.general.string = address
        ShowCopied(text: Localizable.shared.strings.address_copied)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }
    
    @IBAction private func onShare() {
        if let image = codeConentView.snapshot() {
            let activityItem: [AnyObject] = [image]
            let vc = UIActivityViewController(activityItems: activityItem, applicationActivities: [])
            vc.completionWithItemsHandler = {(activityType: UIActivity.ActivityType?, completed: Bool, returnedItems: [Any]?, error: Error?) in
                if completed {
                    self.dismiss(animated: true, completion: {
                        if activityType == UIActivity.ActivityType.copyToPasteboard {
                            ShowCopied()
                        }
                    })
                }
            }
            
            vc.excludedActivityTypes = [UIActivity.ActivityType.assignToContact, UIActivity.ActivityType.print,UIActivity.ActivityType.openInIBooks]
            
            self.present(vc, animated: true)
        }
    }
}
