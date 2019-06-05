//
// SendConfirmViewController.swift
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

class ConfirmItem {
    public var title:String!
    public var detail:String?
    public var detailFont:UIFont?
    public var detailColor:UIColor?
    
    required init(title:String!, detail:String?, detailFont:UIFont?, detailColor:UIColor?) {
        self.title = title
        self.detail = detail
        self.detailFont = detailFont
        self.detailColor = detailColor
    }
}

class SendConfirmViewController: BaseTableViewController {

    private lazy var footerView: UIView = {
        let view = UIView(frame: CGRect(x: 0, y: 0, width: UIScreen.main.bounds.size.width, height: 95))
        
        let button = BMButton.defaultButton(frame: CGRect(x: (UIScreen.main.bounds.size.width-143)/2, y: 40, width: 143, height: 44), color: UIColor.main.heliotrope)
        button.setImage(IconSendBlue(), for: .normal)
        button.setTitle(LocalizableStrings.send, for: .normal)
        button.setTitleColor(UIColor.main.marineOriginal, for: .normal)
        button.setTitleColor(UIColor.main.marineOriginal.withAlphaComponent(0.5), for: .highlighted)
        button.addTarget(self, action: #selector(onNext), for: .touchUpInside)
        view.addSubview(button)
        
        return view
    }()
    
    private var items = [ConfirmItem]()
    private var toAddress:String!
    private var amount:String!
    private var fee:String!
    private var comment:String!
    private var contact:BMContact?

    init(toAddress:String, amount:String!, fee:String!, comment:String!, contact:BMContact?) {
        super.init(nibName: nil, bundle: nil)
        
        self.toAddress = toAddress
        self.amount = amount
        self.fee = fee
        self.comment = comment
        self.contact = contact
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError(LocalizableStrings.fatalInitCoderError)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let total = AppModel.sharedManager().realTotal(Double(amount) ?? 0, fee: Double(fee) ?? 0)
        let totalString = String.currency(value: total) + LocalizableStrings.beam
        
        items.append(ConfirmItem(title: LocalizableStrings.send_to, detail: toAddress, detailFont: RegularFont(size: 16), detailColor: UIColor.white))
        items.append(ConfirmItem(title: LocalizableStrings.amount_to_send, detail: amount + LocalizableStrings.beam, detailFont: SemiboldFont(size: 16), detailColor: UIColor.main.heliotrope))
        items.append(ConfirmItem(title: LocalizableStrings.transaction_fees, detail: fee + LocalizableStrings.groth, detailFont: SemiboldFont(size: 16), detailColor: UIColor.main.heliotrope))
        items.append(ConfirmItem(title: LocalizableStrings.total_utxo, detail: totalString, detailFont: SemiboldFont(size: 16), detailColor: UIColor.white))
        items.append(ConfirmItem(title: LocalizableStrings.send_notice, detail: nil, detailFont: nil, detailColor: nil))

        
        isGradient = true
        
        setGradientTopBar(mainColor: UIColor.main.heliotrope)
        
        attributedTitle = LocalizableStrings.confirm.uppercased()
        
        tableView.register([ConfirmCell.self])
        
        tableView.delegate = self
        tableView.dataSource = self
        tableView.keyboardDismissMode = .interactive
        tableView.tableFooterView = footerView
        
        (self.navigationController as! BaseNavigationController).enableSwipeToDismiss = false
        self.sideMenuController?.isLeftViewSwipeGestureEnabled = false
        
      //  hideKeyboardWhenTappedAround()
    }
    
    override func viewDidLayoutSubviews() {
        tableView.frame = CGRect(x: 0, y: gradientOffset, width: self.view.bounds.width, height: self.view.bounds.size.height - gradientOffset)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        self.navigationController?.isNavigationBarHidden = true
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
                
        if isMovingFromParent {
            self.navigationController?.isNavigationBarHidden = false
        }
    }
    
    @objc private func onNext() {
        let isContactFound = (AppModel.sharedManager().getContactFromId(toAddress) != nil)
        
        if contact == nil && !isContactFound {
            self.confirmAlert(title: LocalizableStrings.save_address_title, message: LocalizableStrings.save_address_text, cancelTitle: LocalizableStrings.not_save, confirmTitle: LocalizableStrings.save, cancelHandler: { (_) in
                self.onSend(needBack: true)
            }) { (_) in
                
                if var controllers = self.navigationController?.viewControllers {
                    controllers.removeLast()
                    controllers.removeLast()
                    
                    let vc = SaveContactViewController(address: self.toAddress)
                    controllers.append(vc)
                    self.navigationController?.setViewControllers(controllers, animated: true)
                }
                
                self.onSend(needBack: false)
            }
        }
        else{
            self.onSend(needBack: true)
        }
    }
    
    private func onSend(needBack:Bool) {
        AppModel.sharedManager().prepareSend(Double(amount) ?? 0, fee: Double(fee) ?? 0, to: toAddress, comment: comment)
        
        AppStoreReviewManager.incrementAppTransactions()
        
        if needBack {
            if let viewControllers = self.navigationController?.viewControllers{
                for vc in viewControllers {
                    if vc is WalletViewController {
                        self.navigationController?.popToViewController(vc, animated: true)
                        return
                    }
                    else if vc is AddressViewController {
                        self.navigationController?.popToViewController(vc, animated: true)
                        return
                    }
                }
            }
            
            self.navigationController?.popToRootViewController(animated: true)
        }
    }
}

extension SendConfirmViewController : UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let view = UIView()
        view.backgroundColor = UIColor.clear
        return view
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return (section > 0) ? 20 : 10
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
}


extension SendConfirmViewController : UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return items.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell =  tableView
            .dequeueReusableCell(withType: ConfirmCell.self, for: indexPath)
            .configured(with: items[indexPath.section])
        
        return cell
    }
}
