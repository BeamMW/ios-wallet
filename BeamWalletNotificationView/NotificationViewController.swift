//
// NotificationViewController.swift
// BeamWalletNotificationView
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
import UserNotifications
import UserNotificationsUI

class NotificationViewController: UIViewController, UNNotificationContentExtension {

    @IBOutlet private weak var passField: UITextField!
    @IBOutlet private weak var errorLabel: UILabel!
    @IBOutlet private weak var lineView: UIView!
    @IBOutlet private weak var touchIdButton: UIButton!
    @IBOutlet private weak var loginLabel: UILabel!
    @IBOutlet private weak var confirmView: UIView!
    @IBOutlet private weak var statusView: UIView!
    @IBOutlet private weak var loadingIndicatorView: UIActivityIndicatorView!
    @IBOutlet private weak var statusLabel: UILabel!
    @IBOutlet private weak var statusButton: UIButton!

    private var notificationData: [AnyHashable : Any]!

    override func viewDidLoad() {
        super.viewDidLoad()

        if !BiometricAuthorization.shared.canAuthenticate() {
            touchIdButton.isHidden = true
        }
        else{
            let mechanism = BiometricAuthorization.shared.faceIDAvailable() ? " Face ID " : " Touch ID "
            
            loginLabel.text = "use".localized + mechanism + "enter_password_title_2".localized
        }
        
        passField.attributedPlaceholder = NSAttributedString(string:passField.placeholder != nil ? passField.placeholder! : "", attributes:[NSAttributedString.Key.foregroundColor: UIColor.lightGray])
        
        NotificationManager.sharedManager.delegate = self
        
        if !FileManager.default.fileExists(atPath: Settings.sharedManager().walletStoragePath())
        {
            self.onTransactionStatus(succes: .failed, status: "Can not initialize the wallet\nPlease open the wallet from the main application and try again")
        }
    }
    
    func didReceive(_ notification: UNNotification) {
        notificationData = notification.request.content.userInfo
    }
 
    
    // MARK: IBAction

    @IBAction private func onTouchId(sender :UIButton) {
        touchIdButton.tintColor = UIColor.white
        
        biometricAuthorization()
    }
    
    @IBAction private func onClose(sender :UIButton) {
        
        if #available(iOS 12.0, *) {
            extensionContext?.dismissNotificationContentExtension()
        } else {
            // Fallback on earlier versions
        }
        
        UNUserNotificationCenter.current().removeAllDeliveredNotifications()
    }
    
    @IBAction private func onCancel(sender :UIButton) {
        NotificationManager.sharedManager.cancelSendAutomaticMoney(data: notificationData)
        
        if #available(iOS 12.0, *) {
            extensionContext?.dismissNotificationContentExtension()
        } else {
            // Fallback on earlier versions
        }
        
        UNUserNotificationCenter.current().removeAllDeliveredNotifications()
    }

    @IBAction private func onLogin(sender :UIButton) {
        
        if passField.text?.isEmpty ?? true {
            errorLabel.text = "empty_password".localized
            errorLabel.textColor = UIColor.main.red
            lineView.backgroundColor = UIColor.main.red
            passField.textColor = UIColor.main.red
        }
        else if let password = KeychainManager.getPassword() {
            if password == passField.text {
                passField.resignFirstResponder()

               _ =  NotificationManager.sharedManager.sendAutomaticMoney(data: notificationData)
            }
            else{
                errorLabel.text = "incorrect_password".localized
                errorLabel.textColor = UIColor.main.red
                lineView.backgroundColor = UIColor.main.red
                passField.textColor = UIColor.main.red
            }
        }
    }
    
    // MARK: Other

    private func biometricAuthorization() {
        if BiometricAuthorization.shared.canAuthenticate()  {
            
            BiometricAuthorization.shared.authenticateWithBioMetrics(success: {
                if let password = KeychainManager.getPassword() {
                    self.passField.text = password
                    
                    self.onLogin(sender: UIButton())
                }
                
            }, failure: {
                self.touchIdButton.tintColor = UIColor.main.red
            }, retry: {
                self.touchIdButton.tintColor = UIColor.white
            })
        }
    }
}

// MARK: NotificationManagerDelegate

extension NotificationViewController : NotificationManagerDelegate {
    func onTransactionStatus(succes: NotificationManager.TransactionStatus, status: String) {
        DispatchQueue.main.async {
            UIView.animate(withDuration: 0.2, animations: {
                self.confirmView.alpha = 0
                self.statusView.alpha = 1
            })
            
            self.statusLabel.text = status
            
            if succes == .failed || succes == .sent {
                AppModel.sharedManager().resetWallet(false)

                self.statusButton.alpha = 1
                self.loadingIndicatorView.stopAnimating()
                
                if succes == .failed {
                   self.statusLabel.textColor = UIColor.main.red
                }
                else{
                    self.statusLabel.textColor = UIColor.main.brightTeal
                }
            }
            else{
                self.statusButton.alpha = 0
                self.loadingIndicatorView.startAnimating()
            }
        }
    }
    

}

// MARK: TextField Actions

extension NotificationViewController : UITextFieldDelegate {
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        
        return true
    }
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        
        errorLabel.text = ""
        
        lineView.backgroundColor = UIColor.main.brightTeal
        
        passField.textColor = UIColor.white
        
        return true
    }
}
