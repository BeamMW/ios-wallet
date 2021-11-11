//
//  DAOConfirmViewController.swift
//  BeamWallet
//
//  Created by Denis on 06.09.2021.
//  Copyright © 2021 Denis. All rights reserved.
//

import UIKit

class DAOConfirmViewController: BaseViewController {
    
    @objc public var onConfirm: ((Bool, Int, Double) -> Void)?
    @objc public var onReject: (() -> Void)?
    @objc public var infoJson:String!
    @objc public var amountJson:String!
    @objc public var app:BMApp!

    private var viewModel: DAOConfirmViewModel!
    
    @IBOutlet private weak var detailTitleLabel:UILabel!
    @IBOutlet private weak var hintLabel:UILabel!
    @IBOutlet private weak var amountLabel:UILabel!
    @IBOutlet private weak var amountSecondLabel:UILabel!
    @IBOutlet private weak var feeLabel:UILabel!
    @IBOutlet private weak var feeSecondLabel:UILabel!
    @IBOutlet private weak var confirmButton:BMButton!
    @IBOutlet private weak var cancelButton:BMButton!
    @IBOutlet private weak var assetIcon:AssetIconView!
    @IBOutlet private weak var assetFeeIcon:AssetIconView!
    @IBOutlet private weak var scrollView: UIScrollView!

    @IBOutlet private weak var passStackView:UIStackView!
    @IBOutlet private weak var passField:BMField!
    @IBOutlet private weak var viewWidth:NSLayoutConstraint!

    private var hintText:String? = nil
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        viewModel = DAOConfirmViewModel(infoJson: infoJson, amountJson: amountJson)
        
        setGradientTopBar(mainColor: UIColor.main.peacockBlue)

        title = Localizable.shared.strings.confirm.uppercased()
        passStackView.isHidden = !Settings.sharedManager().isNeedaskPasswordForSend
        
        viewWidth.constant = UIScreen.main.bounds.width
        
        if viewModel.isSpend {
            confirmButton.setBackgroundColor(color: UIColor.main.heliotrope, forState: .normal)
            confirmButton.setImage(IconSendBlue(), for: .normal)
            
            hintLabel.text = String.init(format: Localizable.shared.strings.will_take_funds, self.app.name)
            detailTitleLabel.text = Localizable.shared.strings.deposit_to_wallet
        }
        else {
            hintLabel.text = String.init(format: Localizable.shared.strings.will_send_funds, self.app.name)

            detailTitleLabel.text = Localizable.shared.strings.withdraw_to_wallet
        }
        
        hintText = hintLabel.text
        
        if let beam = AssetsManager.shared().getAsset(0) {
            let amount = Double(self.viewModel.info?.fee ?? "0") ?? 0.0
            feeLabel.text = "\(amount) BEAM"
            feeSecondLabel.text = ExchangeManager.shared().exchangeValueAsset(amount, assetID: 0)
            assetFeeIcon.setAsset(beam)
        }
        
        var suffix = ""
        if viewModel.isSpend {
            amountLabel.textColor = UIColor.main.heliotrope
            suffix = "-"
        }
        else {
            amountLabel.textColor = UIColor.main.brightSkyBlue
            suffix = "+"
        }
        
        if let asset = AssetsManager.shared().getAsset(Int32(self.viewModel.amountInfo?.assetID ?? 0)) {
            let amount = Double(self.viewModel.amountInfo?.amount ?? "0") ?? 0.0

            amountLabel.text = suffix + StringManager.shared().realAmountStringAsset(asset, value: amount)
            
            let second = ExchangeManager.shared().exchangeValueAsset(amount, assetID: asset.assetId)
            if !second.isEmpty {
                amountSecondLabel.text = suffix + second
            }
            else {
                amountSecondLabel.text = ""
            }

            assetIcon.setAsset(asset)
        }
        
        
        if let value = topOffset?.constant, Device.isXDevice {
            topOffset?.constant = value - 30
        }
        
        cancelButton.setTitleColor(.white, for: .normal)
        
        passField.showEye = true
        
        if self.viewModel.isSpend {
            let error = AppModel.sharedManager().sendError(Double(self.viewModel.amountInfo?.amount ?? "0.0") ?? 0.0, assetId: Int32(self.viewModel.amountInfo?.assetID ?? 0), fee: Double(self.viewModel.info?.fee ?? "0.0") ?? 0.0, checkMinAmount: false)
            
            if error != nil {
                self.hintLabel.textColor = UIColor.main.red
                self.hintLabel.text = Localizable.shared.strings.no_funds_dao
                self.confirmButton.alpha = 0.5
                self.confirmButton.isUserInteractionEnabled = false
            }
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: UIResponder.keyboardWillHideNotification, object: nil)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillHideNotification, object: nil)
    }
    
    @IBAction private func onCancelClicked() {
        self.onReject?()
        self.navigationController?.popViewController(animated: true)
    }
    
    @IBAction private func onConfirmClicked() {
        if Settings.sharedManager().isNeedaskPasswordForSend {
            if passField.text?.isEmpty ?? true {
                passField.error = Localizable.shared.strings.empty_password
                passField.status = BMField.Status.error
            }
            else if let pass = passField.text {
                let password = KeychainManager.getPassword() ?? String.empty()
                let valid = password == pass
                if !valid {
                    passField.error = Localizable.shared.strings.incorrect_password
                    passField.status = BMField.Status.error
                }
                else {
                    onSend()
                }
            }
        }
        else {
            onSend()
        }
    }
    
    private func onSend() {
        if self.viewModel.isSpend {
            let error = AppModel.sharedManager().sendError(Double(self.viewModel.amountInfo?.amount ?? "0.0") ?? 0.0, assetId: Int32(self.viewModel.amountInfo?.assetID ?? 0), fee: Double(self.viewModel.info?.fee ?? "0.0") ?? 0.0, checkMinAmount: false)
            
            if error != nil {
                self.hintLabel.textColor = UIColor.main.red
                self.hintLabel.text = Localizable.shared.strings.no_funds_dao
                self.confirmButton.alpha = 0.5
                self.confirmButton.isUserInteractionEnabled = false
            }
            else {
                self.onConfirm?(self.viewModel.isSpend, self.viewModel.amountInfo?.assetID ?? 0, Double(self.viewModel.amountInfo?.amount ?? "0.0") ?? 0.0)
                self.navigationController?.popViewController(animated: true)
            }
        }
        else {
            self.onConfirm?(self.viewModel.isSpend, self.viewModel.amountInfo?.assetID ?? 0, Double(self.viewModel.amountInfo?.amount ?? "0.0") ?? 0.0)
            self.navigationController?.popViewController(animated: true)
        }
    }
}

extension DAOConfirmViewController: UITextFieldDelegate {
    
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
}

extension DAOConfirmViewController {
    @objc func keyboardWillShow(_ notification: Notification) {
        if let userInfo = notification.userInfo,
           let keyboardSize = (userInfo[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue,
           let duration: TimeInterval = (userInfo[UIResponder.keyboardAnimationDurationUserInfoKey] as? NSNumber)?.doubleValue,
           let animationCurveRaw = userInfo[UIResponder.keyboardAnimationCurveUserInfoKey] as? NSNumber {
            let animationCurve: UIView.AnimationOptions = UIView.AnimationOptions(rawValue: UIView.AnimationOptions.RawValue(truncating: animationCurveRaw))
            var offset = scrollView.contentSize.height - keyboardSize.height
            offset = 250
            
            let contentInsets: UIEdgeInsets = UIEdgeInsets(top: 0.0, left: 0.0, bottom: offset, right: 0.0)
            UIView.animate(withDuration: duration, delay: 0, options: animationCurve, animations: {
                self.scrollView.contentInset = contentInsets
                self.scrollView.scrollIndicatorInsets = contentInsets
                var aRect: CGRect = self.view.frame
                aRect.size.height -= keyboardSize.height
                if !aRect.contains(self.passField.frame.origin) {
                    self.scrollView.scrollRectToVisible(self.passField.frame, animated: false)
                }
            }, completion: nil)
        }
    }
    
    @objc func keyboardWillHide(notification: NSNotification) {
        if let userInfo = notification.userInfo,
           let duration: TimeInterval = (userInfo[UIResponder.keyboardAnimationDurationUserInfoKey] as? NSNumber)?.doubleValue,
           let animationCurveRaw = userInfo[UIResponder.keyboardAnimationCurveUserInfoKey] as? NSNumber {
            let animationCurve: UIView.AnimationOptions = UIView.AnimationOptions(rawValue: UIView.AnimationOptions.RawValue(truncating: animationCurveRaw))
            UIView.animate(withDuration: duration, delay: 0, options: animationCurve, animations: {
                self.scrollView.contentInset = .zero
                self.scrollView.scrollIndicatorInsets = .zero
            }, completion: nil)
        }
    }
}
