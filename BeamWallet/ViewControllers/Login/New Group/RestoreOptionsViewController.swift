//
// RestoreOptionsViewController.swift
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

class RestoreOptionsViewController: BaseViewController {
    
    private var password: String!
    private var phrase: String!
    
    @IBOutlet private weak var scrollView: UIScrollView!

    @IBOutlet private var manualButton: UIButton!
    @IBOutlet private var automaticButton: UIButton!
    
    @IBOutlet private var manualStackView: UIStackView!
    @IBOutlet private var automaticStackView: UIStackView!
    
    init(password: String, phrase: String) {
        super.init(nibName: nil, bundle: nil)

        self.password = password
        self.phrase = phrase
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError(Localizable.shared.strings.fatalInitCoderError)
    }
    
  
    override func viewDidLoad() {
        super.viewDidLoad()
                
        setGradientTopBar(mainColor: UIColor.main.peacockBlue, addedStatusView: false)

        title = Localizable.shared.strings.restore_wallet_title

        manualStackView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(onManual)))
        automaticStackView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(onAuto)))

        onOption(sender: automaticButton)
    }
    
    @objc private func onManual() {
        onOption(sender: manualButton)
    }
    
    @objc private func onAuto() {
        onOption(sender: automaticButton)
    }
    
    @IBAction func onOption(sender: UIButton) {
        if sender == automaticButton {
            manualButton.isSelected = false
            automaticButton.isSelected = true
            AppModel.sharedManager().restoreType = BMRestoreType(BMRestoreAutomatic)
        }
        else if sender == manualButton {
            automaticButton.isSelected = false
            manualButton.isSelected = true
            AppModel.sharedManager().restoreType = BMRestoreType(BMRestoreManual)
        }
    }
    
    @IBAction func onNext(sender: UIButton) {
        if AppModel.sharedManager().restoreType == BMRestoreAutomatic {
            confirmAlert(title: Localizable.shared.strings.restore_wallet_title, message: Localizable.shared.strings.auto_restore_warning, cancelTitle: Localizable.shared.strings.cancel, confirmTitle: Localizable.shared.strings.understand, cancelHandler: { _ in
                
            }) { _ in
                Settings.sharedManager().connectToRandomNode = true
                Settings.sharedManager().nodeAddress = AppModel.chooseRandomNode()
                
                let vc = OpenWalletProgressViewController(password: self.password, phrase: self.phrase)
                self.pushViewController(vc: vc)
            }
        }
        else {
            confirmAlert(title: Localizable.shared.strings.restore_wallet_title, message: Localizable.shared.strings.manual_restore_warning, cancelTitle: Localizable.shared.strings.cancel, confirmTitle: Localizable.shared.strings.understand, cancelHandler: { _ in
                
            }) { _ in
                let created = AppModel.sharedManager().createWallet(self.phrase, pass: self.password)
                if !created {
                    self.alert(title: Localizable.shared.strings.error, message: Localizable.shared.strings.wallet_not_created) { _ in
                        if AppModel.sharedManager().isInternetAvailable {
                            self.navigationController?.popToRootViewController(animated: true)
                        }
                        else {
                            DispatchQueue.main.async {
                                self.back()
                            }
                        }
                    }
                }
                else {
                    SVProgressHUD.show()
                    AppModel.sharedManager().exportOwnerKey(self.password) { [weak self] key in
                        SVProgressHUD.dismiss()
                        
                        guard let strongSelf = self else { return }
                        
                        let vc = OwnerKeyViewController()
                        vc.ownerKey = key
                        strongSelf.pushViewController(vc: vc)
                    }
                }
            }
        }
    }
}
