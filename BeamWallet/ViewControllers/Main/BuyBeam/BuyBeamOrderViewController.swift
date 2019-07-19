//
// QRViewController.swift
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

class BuyBeamOrderViewController: BaseViewController {
    
    public var onShared : (() -> Void)?
    
    private let viewModel = BuyBeamOrderViewModel()
    
    private var order:CryptoWolfService.OrderResponse!
    private var amount:String!
    private var currency:String!
    private var timer:Timer?
    private var receiveAmount:String!

    @IBOutlet weak private var mainView: UIView!
    @IBOutlet weak private var scrollView: UIScrollView!

    @IBOutlet weak private var addressLabel: UILabel!
    @IBOutlet weak private var addressTitleLabel: UILabel!

    @IBOutlet weak private var amountLabel: UILabel!
    @IBOutlet weak private var amountTitleLabel: UILabel!
    @IBOutlet weak private var descriptionLabel: UILabel!
    
    @IBOutlet weak private var codeConentView: UIView!
    @IBOutlet weak private var codeView: QRCodeView!
    
    @IBOutlet weak private var orderLabel: UILabel!
    @IBOutlet weak private var orderTitleLabel: UILabel!
    
    @IBOutlet weak private var awaitingDepositLabel: UILabel!
    @IBOutlet weak private var awaitingDepositTitleLabel: UILabel!
    @IBOutlet weak private var awaitingDotView: UIView!

    
    let endedTime = Date().timeIntervalSince1970 + 3000

    override var isUppercasedTitle: Bool {
        get{
            return true
        }
        set{
            super.isUppercasedTitle = true
        }
    }
    
    init(order:CryptoWolfService.OrderResponse, amount:String, currency:String, receiveAmount:String) {
        super.init(nibName: nil, bundle: nil)
        
        self.order = order
        self.amount = amount
        self.currency = currency
        self.receiveAmount = receiveAmount
        self.viewModel.currency = currency
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError(Localizable.shared.strings.fatalInitCoderError)
    }
        
    override func viewDidLoad() {
        super.viewDidLoad()
        
        awaitingDotView.backgroundColor = UIColor.main.red
        
        UIView.animate(withDuration: 0.7, delay: 0.0, options:[.repeat, .autoreverse], animations: {
            [weak self] in
            self?.awaitingDotView.backgroundColor = UIColor.main.heliotrope
        }, completion:nil)
        
        onTimer()
        
        timer = Timer.scheduledTimer(timeInterval: TimeInterval(1), target: self, selector: #selector(onTimer), userInfo: nil, repeats: true)
        
        setGradientTopBar(mainColor: UIColor.main.heliotrope, addedStatusView: false)
        
        title = Localizable.shared.strings.buy_beam.uppercased()
        
        let fullname = CryptoWolfManager.sharedManager.fullName(coin: currency).uppercased()
        
        addressTitleLabel.text = (fullname + Localizable.shared.strings.space + Localizable.shared.strings.address).uppercased()
        addressTitleLabel.letterSpacing = 1.5
        addressLabel.text = order.address
       
        amountTitleLabel.text = Localizable.shared.strings.you_get.uppercased()
        amountTitleLabel.letterSpacing = 1.5
        amountLabel.text = receiveAmount + Localizable.shared.strings.space + Localizable.shared.strings.beam
        
        orderTitleLabel.text = orderTitleLabel.text?.uppercased()
        orderTitleLabel.letterSpacing = 1.5
        orderLabel.text = order.status
        
        awaitingDepositTitleLabel.text = Localizable.shared.strings.addDots(value: Localizable.shared.strings.awaiting_deposit)
        
        let value = "\(amount ?? "") \(currency ?? "")"
        let description = (Localizable.shared.strings.buy_send_money(value: value, name: fullname).lowercased().replacingOccurrences(of: currency.lowercased(), with: currency.uppercased()).capitalizingFirstLetter() + "\n\n" + Localizable.shared.strings.receiving_amount_dif).replacingOccurrences(of: currency.lowercased(), with: currency.uppercased())
        
        let range = (description as NSString).range(of: String(value))
        
        let attributedString = NSMutableAttributedString(string:description)
        attributedString.addAttribute(NSAttributedString.Key.foregroundColor, value: UIColor.main.heliotrope, range: range)

        descriptionLabel.attributedText = attributedString
        
        codeView.generateCode(CryptoWolfManager.sharedManager.orderQRCode(amount: self.amount, currency: self.currency), foregroundColor: UIColor.white, backgroundColor: UIColor.clear)
                
        subscribeToChages()
        
        viewModel.updateOrderStatus()
        
        view.addSubview(scrollView)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        mainView.removeFromSuperview()
        scrollView.addSubview(mainView)
        
        mainView.translatesAutoresizingMaskIntoConstraints = true
        mainView.frame = CGRect(x: 0, y: 15, width: view.frame.size.width, height: mainView.frame.size.height)
        
        scrollView.contentSize = CGSize(width: 0, height: mainView.frame.size.height + 15)
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        
        timer?.invalidate()
        timer = nil
        
        viewModel.stopUpdates()
    }
    
    private func subscribeToChages() {
        viewModel.onOrderStatusChange = {
            [weak self] result in

            guard let strongSelf = self else { return }
            
            if let transaction = result {
                if transaction.code == -1 {
                    strongSelf.timer?.invalidate()
                    strongSelf.timer = nil
                    strongSelf.viewModel.stopUpdates()
                    
                    strongSelf.alert(title: Localizable.shared.strings.buy_transaction_failed_title, message: Localizable.shared.strings.buy_transaction_failed_text_1, handler: { (_ ) in
                        strongSelf.back()
                    })
                }
                else if transaction.code == -2 {
                    strongSelf.timer?.invalidate()
                    strongSelf.timer = nil
                    strongSelf.viewModel.stopUpdates()

                    strongSelf.alert(title: Localizable.shared.strings.buy_transaction_failed_title, message: Localizable.shared.strings.buy_transaction_failed_text_2, handler: { (_ ) in
                        strongSelf.back()
                    })
                }
                else if transaction.code == 4 {
                    strongSelf.timer?.invalidate()
                    strongSelf.timer = nil
                    strongSelf.viewModel.stopUpdates()

                    strongSelf.alert(title: Localizable.shared.strings.buy_transaction_success_title, message: Localizable.shared.strings.buy_transaction_success_text, handler: { (_ ) in
                        strongSelf.closeOrder()
                    })
                }
            }
        }
    }
    
    @objc func closeOrder() {
        let vc = WalletViewController()
        self.navigationController?.setViewControllers([vc], animated: true)
    }
    
    @objc private func onTimer() {
        let value = endedTime -  Date().timeIntervalSince1970
        if value <= 0 {
            timer?.invalidate()
            timer = nil
            closeOrder()
        }
        else{
            let timeEnded = value.asTime(style: .short)
            awaitingDepositLabel.text = timeEnded
        }
    }
    
    @IBAction func onShareAddress(sender :UIButton) {
        let vc = UIActivityViewController(activityItems: [addressLabel.text!], applicationActivities: [])
        vc.completionWithItemsHandler = {[weak self] (activityType: UIActivity.ActivityType?, completed: Bool, returnedItems: [Any]?, error: Error?) in
            if completed {
                if activityType == UIActivity.ActivityType.copyToPasteboard {
                    ShowCopied()
                }
                
                self?.onShared?()
            }
        }
        vc.excludedActivityTypes = [UIActivity.ActivityType.assignToContact, UIActivity.ActivityType.print,UIActivity.ActivityType.openInIBooks]
        self.present(vc, animated: true)
    }
    
    @IBAction func onShareQR(sender :UIButton) {
        if let image = codeConentView.snapshot() {
            let activityItem: [AnyObject] = [image]
            let vc = UIActivityViewController(activityItems: activityItem, applicationActivities: [])
            vc.completionWithItemsHandler = {(activityType: UIActivity.ActivityType?, completed: Bool, returnedItems: [Any]?, error: Error?) in
                if completed {
                    if activityType == UIActivity.ActivityType.copyToPasteboard {
                        ShowCopied()
                    }
                    self.onShared?()
                }
            }
            
            vc.excludedActivityTypes = [UIActivity.ActivityType.assignToContact, UIActivity.ActivityType.print,UIActivity.ActivityType.openInIBooks]
            
            self.present(vc, animated: true)
        }
    }
}
