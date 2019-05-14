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
    @IBOutlet weak private var mainViewHeight: NSLayoutConstraint!
    @IBOutlet weak private var mainViewWidth: NSLayoutConstraint!
    @IBOutlet weak private var bottomYOffset: NSLayoutConstraint!

    @IBOutlet weak private var addressLabel: UILabel!
    @IBOutlet weak private var expireLabel: UILabel!
    @IBOutlet weak private var amountField: BMField!
    @IBOutlet weak private var scrollView: UIScrollView!
    @IBOutlet weak private var commentField: BMField!
    @IBOutlet weak private var amountErrorLabel: UILabel!

    @IBOutlet weak private var qrButton: UIButton!
    @IBOutlet weak private var shareAddress: UIButton!

    private var address:BMAddress!
    
    init(address:BMAddress) {
        super.init(nibName: nil, bundle: nil)

        self.address = address
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError(LocalizableStrings.fatalInitCoderError)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        mainViewWidth.constant = UIScreen.main.bounds.width
        
        if UIScreen.main.bounds.size.height > 680  {
            mainViewHeight.constant = UIScreen.main.bounds.height - 94
            scrollView.isScrollEnabled = false
        }
        else{
            mainViewHeight.constant = 650
        }
        
        if Device.screenType == .iPhones_6 {
            bottomYOffset.constant = 45
        }

        title = "Receive"
        
        hideKeyboardWhenTappedAround()
        
        addressLabel.text = address.walletId
        
        if !AppDelegate.isEnableNewFeatures {
            shareAddress.setTitle("copy address", for: .normal)
            shareAddress.setImage(UIImage(named: "iconCopyBlue"), for: .normal)
        }
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: UIResponder.keyboardWillHideNotification, object: nil)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillShowNotification , object: nil)
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillHideNotification , object: nil)
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
    
    @IBAction func onShare(sender :UIButton) {
        if let address = addressLabel.text {
            if !AppDelegate.isEnableNewFeatures {
                UIPasteboard.general.string = address
                
                ShowCopiedProgressHUD()
                
                self.navigationController?.popViewController(animated: true)
            }
            else{
                let vc = UIActivityViewController(activityItems: [address], applicationActivities: [])
                vc.completionWithItemsHandler = {(activityType: UIActivity.ActivityType?, completed: Bool, returnedItems: [Any]?, error: Error?) in
                    if completed {
                        self.navigationController?.popViewController(animated: true)
                        return
                    }
                }
                
                vc.excludedActivityTypes = [UIActivity.ActivityType.assignToContact, UIActivity.ActivityType.print,UIActivity.ActivityType.openInIBooks]
                
                self.present(vc, animated: true)
            }

        }
    }
    
    @IBAction func onQRCode(sender :UIButton) {
        let modalViewController = WalletQRCodeViewController(address: addressLabel.text!, amount: amountField.text)
        modalViewController.delegate = self
        modalViewController.modalPresentationStyle = .overFullScreen
        modalViewController.modalTransitionStyle = .crossDissolve
        present(modalViewController, animated: true, completion: nil)
    }
    
}



extension WalletReceiveViewController : WalletQRCodeViewControllerDelegate {
    func onCopyDone() {
        self.navigationController?.popViewController(animated: true)
    }
}

// MARK: TextField Actions

extension WalletReceiveViewController : UITextFieldDelegate {
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        
        scrollView.scrollRectToVisible(CGRect.zero, animated: true)
        
        if textField == amountField {
            if let text = textField.text {
                if let v = Double(text) {
                    if v == 0 {
                        textField.text = "0"
                    }
                }
                else{
                    textField.text = "0"
                }
            }
        }
        else if(textField == commentField) {
            if let comment = textField.text, let address = addressLabel.text {
                AppModel.sharedManager().setWalletComment(comment, toAddress: address)
            }
        }
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        
        
        let textFieldText: NSString = (textField.text ?? "") as NSString
        
        if textField == amountField {
            let mainCount = (textField == amountField) ? 9 : 15
            let comaCount = 8
            
            let txtAfterUpdate = textFieldText.replacingCharacters(in: range, with: string).replacingOccurrences(of: ",", with: ".")
            
            if Double(txtAfterUpdate) == nil && !txtAfterUpdate.isEmpty {
                return false
            }

            if (!txtAfterUpdate.isDecimial()) {
                return false
            }
            
            if !txtAfterUpdate.isEmpty {
                let split = txtAfterUpdate.split(separator: ".")
                if split[0].lengthOfBytes(using: .utf8) > mainCount {
                    return false
                }
                else if split.count > 1 {
                    if split[1].lengthOfBytes(using: .utf8) > comaCount {
                        return false
                    }
                    else if split[1].lengthOfBytes(using: .utf8) == comaCount && textField == amountField && Double(txtAfterUpdate) == 0 {
                        return false
                    }
                }
            }
            
            amountErrorLabel.isHidden = true
            amountField.status = .normal
            
            qrButton.isUserInteractionEnabled = true
            shareAddress.isUserInteractionEnabled = true
            
            qrButton.alpha = 1
            shareAddress.alpha = 1
            
            if let amount = Double(txtAfterUpdate) {
                if AppModel.sharedManager().canReceive(amount, fee: 0) != nil {
                    return false
                }
            }

            textField.text = txtAfterUpdate

            return false
        }
        
        return true
    }
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        let fieldPosition = textField.superview?.frame
        if let position = fieldPosition {
            scrollView.scrollRectToVisible(position, animated: true)
        }
    }
}

// MARK: Keyboard Handling

extension WalletReceiveViewController {
    @objc func keyboardWillShow(_ notification: Notification) {
        scrollView.isScrollEnabled = true

        if let keyboardFrame: NSValue = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue {
            let keyboardRectangle = keyboardFrame.cgRectValue
            let keyboardHeight = keyboardRectangle.height
            
            scrollView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: keyboardHeight, right: 0)
        }
    }
    
    @objc func keyboardWillHide(notification: NSNotification) {
        scrollView.contentInset = UIEdgeInsets.zero
        
        if UIScreen.main.bounds.size.height > 680  {
            scrollView.isScrollEnabled = false
            scrollView.setContentOffset(CGPoint.zero, animated: true)
        }
    }
}

