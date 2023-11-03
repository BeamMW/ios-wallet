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

    @IBOutlet private weak var feeLabel:UILabel!
    @IBOutlet private weak var feeSecondLabel:UILabel!
    @IBOutlet private weak var confirmButton:BMButton!
    @IBOutlet private weak var cancelButton:BMButton!
    
    @IBOutlet private weak var assetFeeIcon:AssetIconView!
    @IBOutlet private weak var scrollView: UIScrollView!

    @IBOutlet private weak var assetStackView1:UIStackView!
    @IBOutlet private weak var assetIcon1:AssetIconView!
    @IBOutlet private weak var amountLabel1:UILabel!
    @IBOutlet private weak var amountSecondLabel1:UILabel!
    @IBOutlet private weak var assetIdLabel1:UILabel!
    @IBOutlet private weak var assetIdView1:UIView!
    
    @IBOutlet private weak var assetStackView2:UIStackView!
    @IBOutlet private weak var assetIcon2:AssetIconView!
    @IBOutlet private weak var amountLabel2:UILabel!
    @IBOutlet private weak var amountSecondLabel2:UILabel!
    @IBOutlet private weak var assetIdLabel2:UILabel!
    @IBOutlet private weak var assetIdView2:UIView!
    
    @IBOutlet private weak var assetStackView3:UIStackView!
    @IBOutlet private weak var assetIcon3:AssetIconView!
    @IBOutlet private weak var amountLabel3:UILabel!
    @IBOutlet private weak var amountSecondLabel3:UILabel!
    @IBOutlet private weak var assetIdLabel3:UILabel!
    @IBOutlet private weak var assetIdView3:UIView!

    @IBOutlet private weak var passStackView:UIStackView!
    @IBOutlet private weak var passField:BMField!
    @IBOutlet private weak var viewWidth:NSLayoutConstraint!

    private var hintText:String? = nil
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        AppModel.sharedManager().addDelegate(self)

        assetIdView1.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(onAssetId1Clicked)))
        assetIdView2.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(onAssetId2Clicked)))
        assetIdView3.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(onAssetId3Clicked)))

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
        
        setAmounts()
    
        if let value = topOffset?.constant, Device.isXDevice {
            topOffset?.constant = value - 30
        }
        
        cancelButton.setTitleColor(.white, for: .normal)
        
        passField.showEye = true
        
        if self.viewModel.isSpend {
            if let amountInfos = viewModel.amountInfos {
                for amount in amountInfos {
                    let error = AppModel.sharedManager().sendError(Double(amount.amount ?? "0.0") ?? 0.0, assetId: Int32(amount.assetID ?? 0), fee: Double(self.viewModel.info?.fee ?? "0.0") ?? 0.0, checkMinAmount: false)
                    
                    if error != nil {
                        self.hintLabel.textColor = UIColor.main.red
                        self.hintLabel.text = Localizable.shared.strings.no_funds_dao
                        self.confirmButton.alpha = 0.5
                        self.confirmButton.isUserInteractionEnabled = false
                        break
                    }
                }
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
        
        AppModel.sharedManager().removeDelegate(self)

        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillHideNotification, object: nil)
    }
    
    @objc func onAssetId1Clicked() {
        guard let amountInfo = viewModel.amountInfos else {
            return
        }
        
        let id = amountInfo[0].assetID ?? 0
        
        if let url = URL(string: Settings.sharedManager().assetBlockchainUrl(Int32(id))) {
            UIApplication.getTopMostViewController()?.openUrl(url: url)
        }
    }
    
    @objc func onAssetId2Clicked() {
        guard let amountInfo = viewModel.amountInfos else {
            return
        }
        
        let id = amountInfo[1].assetID ?? 0
        
        if let url = URL(string: Settings.sharedManager().assetBlockchainUrl(Int32(id))) {
            UIApplication.getTopMostViewController()?.openUrl(url: url)
        }
    }
    
    @objc func onAssetId3Clicked() {
        guard let amountInfo = viewModel.amountInfos else {
            return
        }
        
        let id = amountInfo[2].assetID ?? 0
        
        if let url = URL(string: Settings.sharedManager().assetBlockchainUrl(Int32(id))) {
            UIApplication.getTopMostViewController()?.openUrl(url: url)
        }
    }
    
    private func setAmounts() {
        assetStackView1.isHidden = true
        assetStackView2.isHidden = true
        assetStackView3.isHidden = true
        
        assetIdView1.isHidden = true
        assetIdView2.isHidden = true
        assetIdView3.isHidden = true

        guard let amountInfo = viewModel.amountInfos else {
            return
        }
        
        var index = 0
        amountInfo.forEach { amount in
            var amountLabel: UILabel!
            var amountSecondLabel: UILabel!
            var assetIcon: AssetIconView!
            let assetId = amount.assetID ?? 0
            let amountValue = amount.amount ?? "0"

            if index == 0 {
                amountLabel = amountLabel1
                amountSecondLabel = amountSecondLabel1
                assetIcon = assetIcon1
                assetStackView1.isHidden = false
                assetIdLabel1.text = "\(assetId)"
                assetIdView1.isHidden = false
            } else if index == 1 {
                amountLabel = amountLabel2
                amountSecondLabel = amountSecondLabel2
                assetIcon = assetIcon2
                assetStackView2.isHidden = false
                assetIdLabel2.text = "\(assetId)"
                assetIdView2.isHidden = false
            }
            else if index == 2 {
                amountLabel = amountLabel3
                amountSecondLabel = amountSecondLabel3
                assetIcon = assetIcon3
                assetStackView3.isHidden = false
                assetIdLabel3.text = "\(assetId)"
                assetIdView3.isHidden = false
            }
            
            var suffix = ""
            if amount.spend == true {
                amountLabel.textColor = UIColor.main.heliotrope
                suffix = "-"
            }
            else {
                amountLabel.textColor = UIColor.main.brightSkyBlue
                suffix = "+"
            }
            
            if let asset = AssetsManager.shared().getAsset(Int32(assetId)) {
                let amountDouble = Double(amountValue) ?? 0.0
                
                amountLabel.text = suffix + StringManager.shared().realAmountStringAsset(asset, value: amountDouble)
                
                let second = ExchangeManager.shared().exchangeValueAsset(amountDouble, assetID: UInt64(assetId))
                if !second.isEmpty {
                    amountSecondLabel.text = suffix + second
                }
                else {
                    amountSecondLabel.text = ""
                }
                
                assetIcon.setAsset(asset)
            }
            
            index += 1
        }
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
            var hasError = false
            
            let error = AppModel.sharedManager().sendError(Double(self.viewModel.amountInfo?.amount ?? "0.0") ?? 0.0, assetId: Int32(self.viewModel.amountInfo?.assetID ?? 0), fee: Double(self.viewModel.info?.fee ?? "0.0") ?? 0.0, checkMinAmount: false)
            
            if error != nil {
                hasError = true
                self.hintLabel.textColor = UIColor.main.red
                self.hintLabel.text = Localizable.shared.strings.no_funds_dao
                self.confirmButton.alpha = 0.5
                self.confirmButton.isUserInteractionEnabled = false
            }
            
            if !hasError {
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

extension DAOConfirmViewController: WalletModelDelegate {
    
    func onAssetInfoChange() {
        DispatchQueue.main.async {
            self.setAmounts()
        }
    }
}
