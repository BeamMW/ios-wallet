//
// BuyBeamViewModel.swift
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

import Foundation
import ReCaptcha

class BuyBeamViewModel: ReceiveAddressViewModel {
    
    public var onCalculationChange : (() -> Void)?

    public var minimumAmount = String.empty()
    public var amountError:String?
    
    private let recaptcha = try? ReCaptcha(
        apiKey: "6Lcatm8UAAAAABbCBiTLWV3lRlk2hq6vUYoPvmGW",
        baseURL: URL(string: "https://cryptowolf.eu")!
    )
    
    override var amount: String?{
        didSet{
            calculateReceive()
        }
    }
    
    public var currency = String.empty() {
        didSet{
            receiveAmount = String.empty()
            loading = true
            fromAddress = String.empty()
            loadRates()
        }
    }
    
    public var receiveAmount = String.empty()

    public var fromAddress = String.empty()
    public var fromAddressError:String?
    
    private var timer:Timer?
    public var loading = false

    private func calculateReceive() {
        var receive = CryptoWolfManager.sharedManager.calculateReceiving(from: currency, to: "BEAM", sending: Double(amount!) ?? 0)
        if receive.count > 0 {
            if receive[0] > 0 {
                let v = receive[0].rounded(toPlaces: Int(CryptoWolfManager.sharedManager.round(coin: currency)))
                receiveAmount = String.currency(value: v)
            }
            else{
                receiveAmount = String.empty()
            }
        }
        else{
            receiveAmount = String.empty()
        }
        
        let min = CryptoWolfManager.sharedManager.calculateMinAmount(from: currency)
        minimumAmount = (min > 0) ? (Localizables.shared.strings.minAmount(str: String.currency(value: min))) : String.empty()
    }
    
    override init() {
        super.init()
        
        amount = String.empty()
        
        if let f = CryptoWolfManager.sharedManager.availableCurrencies.first {
            currency = f
            
            let min = CryptoWolfManager.sharedManager.calculateMinAmount(from: currency)
            minimumAmount = (min > 0) ? (Localizables.shared.strings.minAmount(str: String.currency(value: min))) : String.empty()
        }
        
        loadRates()
        
        recaptcha?.forceVisibleChallenge = false
        recaptcha?.configureWebView { [weak self] webview in
            SVProgressHUD.dismiss()

            webview.tag = 901
            webview.frame = UIScreen.main.bounds
        }
    }
    
    deinit {
        timer?.invalidate()
        timer = nil
    }
    
    @objc private func loadRates() {
        CryptoWolfManager.sharedManager.refreshRates(currency: currency) {
            [weak self] in
            
            guard let strongSelf = self else { return }
            
            strongSelf.loading = false

            strongSelf.timer?.invalidate()
            strongSelf.timer = nil
            strongSelf.timer = Timer.scheduledTimer(timeInterval: TimeInterval(5), target: strongSelf, selector: #selector(strongSelf.loadRates), userInfo: nil, repeats: false)
            
            strongSelf.calculateReceive()
            DispatchQueue.main.async {
                strongSelf.onCalculationChange?()
            }
        }
    }
    

    
    public func onChangeCurrency() {
        if let top = UIApplication.getTopMostViewController() {
            let vc = BuyBeamCurrencyPicker(currency: currency)
            vc.completion = {
                [weak self] selected in
                
                if let currency = selected {
                    self?.currency = currency
                    self?.onDataChanged?()
                }
            }
            top.pushViewController(vc: vc)
        }
    }
    
    public func onCanSend() -> Bool {
        var isValid = true
        
        let round = Int(CryptoWolfManager.sharedManager.round(coin: currency))
        let am = Double(amount!)?.rounded(toPlaces: round) ?? 0
        let min = CryptoWolfManager.sharedManager.calculateMinAmount(from: currency)

        if amount!.isEmpty{
            isValid = false
            amountError = Localizables.shared.strings.amount_empty
        }
        else if am == 0 {
            isValid = false
            amountError = Localizables.shared.strings.amount_zero
        }
        else if am < min
        {
            if amount != String.currency(value: min) {
                isValid = false
                amountError = Localizables.shared.strings.incorrect_amount
            }
        }
        
        if fromAddress.isEmpty {
            isValid = false
            
            fromAddressError = Localizables.shared.strings.incorrect_address
        }
      
        return isValid
    }
    
    public func submitOrder(completion:@escaping ((CryptoWolfService.OrderResponse?,Error?) -> Void)) {
        
        if let top = UIApplication.getTopMostViewController() {
            recaptcha?.validate(on: top.view) { [weak self] (result: ReCaptchaResult) in
                guard let strongSelf = self else { return }

                top.view.viewWithTag(901)?.removeFromSuperview()
                
                if let captcha = try? result.dematerialize(){
                    CryptoWolfManager.sharedManager.submitOrder(from: strongSelf.currency, to: "BEAM", fromAddress: strongSelf.fromAddress, toAddress: strongSelf.address.walletId, amount: strongSelf.amount!, captcha: captcha, emailaddress: "") { [weak self] (response, error) in
                        
                        guard self != nil else { return }
                        
                        completion(response,error)
                    }
                }
                else{
                    completion(nil,nil)
                }
            }
        }
    }
    
    public func onScanQRCode () {
        if let top = UIApplication.getTopMostViewController() {
            let vc = QRScannerViewController()
            vc.delegate = self
            vc.isGradient = true
            if currency == "BTC" {
                vc.scanType = .bitcoin
            }
            else if currency == "LTC" {
                vc.scanType = .litecoin
            }
            else if currency == "ETH" {
                vc.scanType = .ethereum
            }
            vc.hidesBottomBarWhenPushed = true
            top.pushViewController(vc: vc)
        }
    }
}

extension BuyBeamViewModel : QRScannerViewControllerDelegate {
    
    func didScanQRCode(value: String, amount: String?) {
        fromAddress = value
        fromAddressError = nil
        onDataChanged?()
    }
}
