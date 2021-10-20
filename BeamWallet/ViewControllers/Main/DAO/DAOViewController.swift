//
//  DAOViewController.swift
//  BeamWallet
//
//  Created by Denis on 03.09.2021.
//  Copyright © 2021 Denis. All rights reserved.
//

import UIKit
import WebKit
import SafariServices

@objc class WBStyle:NSObject {
    @objc var appsGradientOffset = -174
    @objc var appsGradientTop = 56
    @objc var navigation_background = "#000000"
    @objc var background_main = UIColor.main.marine.toHexString()
    @objc var background_main_top = UIColor.main.marine.toHexString()
    @objc var content_main = "#ffffff"
    @objc var background_popup = "#323232"
    @objc var validator_error = "#ff625c"
}

@objc class WBBEAM: NSObject {
    @objc public var onCallWalletApi: ((NSString) -> Void)?

    @objc var style = WBStyle()
    
    var resultObject:XWVScriptObject? = nil
        
    @objc public func callWalletApi(_ json:NSString) {
        print("\(json)")
        onCallWalletApi?(json)
    }
    
    @objc public func callWalletApiResult(_ scriptObject:XWVScriptObject) {
        resultObject = scriptObject
    }
    
}

class DAOViewController: BaseViewController, WKNavigationDelegate, WKScriptMessageHandler {

    private var webView:WKWebView!
    private var loadingImage = UIImageView()
    private var loadingLabel = UILabel()

    @objc private var beam:WBBEAM? = WBBEAM()

    @objc public var app:BMApp!
    @objc public var onCallWalletApi: ((NSString) -> Void)?
    @objc public var onRejected: ((NSString) -> Void)?
    @objc public var onApproved: ((NSString) -> Void)?

    private var jsonRequest = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        stupWebView()
        
        
        setGradientTopBar(mainColor: UIColor.main.peacockBlue, addedStatusView: true, menu: self.navigationController?.viewControllers.count == 1)
        
        title = app.name
                
        beam?.onCallWalletApi = { json in
            self.onCallWalletApi?(json)
        }
        
        webView.load(URLRequest(url: URL(string: app.url)!))
    }
    
    private func stupWebView() {
        let controller = WKUserContentController()
        controller.add(self, name: "BEAM")
        
        let configuration = WKWebViewConfiguration()
        configuration.userContentController = controller
        
        let logSource = "function captureLog(msg) { window.webkit.messageHandlers.logHandler.postMessage(msg); } window.console.log = captureLog;"
        let logScript = WKUserScript(source: logSource, injectionTime: .atDocumentEnd, forMainFrameOnly: false)
        
        let jsLogScript2 = "console.log = (function(oriLogFunc){ return function(str) { window.webkit.messageHandlers.log.postMessage(str); oriLogFunc.call(console,str);} })(console.log);";
        
        webView = WKWebView(frame: self.view.bounds, configuration: configuration)
        webView.navigationDelegate = self
        webView.configuration.userContentController.addUserScript(logScript)
        webView.configuration.userContentController.addUserScript(WKUserScript(source: jsLogScript2, injectionTime: .atDocumentStart, forMainFrameOnly: true))
        webView.configuration.userContentController.add(self, name: "logHandler")
        webView.configuration.userContentController.add(self, name: "log")
        webView.loadPlugin(beam!, namespace: "BEAM")
        webView.backgroundColor = self.view.backgroundColor
        webView.isOpaque = false
        webView.scrollView.contentInset = UIEdgeInsets(top: 15, left: 0, bottom: 15, right: 0)
        webView.isHidden = true
        self.view.addSubview(webView)
        
        loadingImage.image = UIImage(named: "dapp-loading")
        loadingImage.frame = CGRect(x: (UIScreen.main.bounds.width-245)/2, y: (UIScreen.main.bounds.height-137)/2, width: 245, height: 137)
        self.view.addSubview(loadingImage)
        
        loadingLabel.font = ItalicFont(size: 16)
        loadingLabel.text = String.init(format: Localizable.shared.strings.please_wait_is_loading, app.name)
        loadingLabel.textColor =  Settings.sharedManager().isDarkMode ? UIColor.main.steel : UIColor.main.blueyGrey
        loadingLabel.textAlignment = .center
        loadingLabel.frame = CGRect(x: 20, y: loadingImage.y - 60, width: UIScreen.main.bounds.width-40, height: 30)
        self.view.addSubview(loadingLabel)

    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        var offset:CGFloat =  0
        
        if !isGradient {
            offset =  30
        }
        else if isGradient && !isAddStatusView {
            offset = 30
        }
        
        let y = navigationBarOffset - offset
        webView.frame = CGRect(x: 0, y: y , width: self.view.bounds.width, height: self.view.bounds.size.height - y)
    }
    
    @objc func showConfirmDialog(json:String, info:String, amount:String) {
        self.jsonRequest = json
        DispatchQueue.main.async {
            let vc = DAOConfirmViewController()
            vc.amountJson = amount
            vc.infoJson = info
            vc.app = self.app
            vc.onReject = {
                self.onRejected?(NSString(string: self.jsonRequest))
            }
            vc.onConfirm = { isSpend, assetId, amount in
                let transaction = BMTransaction()
                transaction.isDapps = true
                transaction.enumStatus = BMTransactionStatus(BMTransactionStatusRegistering)
                transaction.appName = self.app.name
                transaction.isIncome = !isSpend
                transaction.assetId = Int32(assetId)
                transaction.asset = AssetsManager.shared().getAsset(Int32(assetId))
                transaction.realAmount = amount
                BMNotificationView.showTransaction(transaction: transaction, delegate: nil, delay: 0.0)

                self.onApproved?(NSString(string: self.jsonRequest))                
            }
            self.pushViewController(vc: vc)
        }
    }
    
    @objc func sendDAOApiResult(json:NSString) {
        do {
           _ = try beam?.resultObject?.call(arguments: [json])
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                DispatchQueue.main.async {
                    self.webView?.isHidden = false
                    self.loadingImage.isHidden = true
                    self.loadingLabel.isHidden = true
                }
            }
        }
        catch {
            print(error)
        }
    }
    
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        if let msg = message.body as? String {
            print("--------WEB LOG--------:\n" + msg)
        }
        else {
            print(message.body)
        }
    }
    
    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        print("didFail")
    }
    
    func webView(_ webView: WKWebView, didCommit navigation: WKNavigation!) {
        print("didCommit")
    }
    
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        print("didFinish")
    }
}
