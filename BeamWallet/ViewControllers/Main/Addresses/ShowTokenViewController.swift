//
// ShowTokenViewController.swift
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

class ShowTokenViewController: BaseTableViewController {

    public var didCopyToken : (() -> Void)?
    public var isMiningPool = false
    
    private var token = ""
    private var send = false
    private var items = [BMMultiLineItem]()
    
    private lazy var footerView: UIView = {
        var view = UIView(frame: CGRect(x: 0, y: 0, width: UIScreen.main.bounds.size.width, height: 115))
        
        var copyButton = BMButton.defaultButton(frame: CGRect(x: (UIScreen.main.bounds.size.width-180)/2, y: 40, width: 180, height: 44), color: send ? UIColor.main.heliotrope : UIColor.main.brightSkyBlue)
        copyButton.setImage(IconCopyBlue(), for: .normal)
        copyButton.setTitle(Localizable.shared.strings.copy_and_close.lowercased(), for: .normal)
        copyButton.setTitleColor(UIColor.main.marineOriginal, for: .normal)
        copyButton.setTitleColor(UIColor.main.marineOriginal.withAlphaComponent(0.5), for: .highlighted)
        copyButton.addTarget(self, action: #selector(onCopy), for: .touchUpInside)
        view.addSubview(copyButton)
        
        
        return view
    }()
    
    init(token:String, send:Bool) {
        super.init(nibName: nil, bundle: nil)
        self.token = token
        self.send = send
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError(Localizable.shared.strings.fatalInitCoderError)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        
        if AppModel.sharedManager().isToken(token) {
            let params = AppModel.sharedManager().getTransactionParameters(token)

            if(params.amount > 0) {
                let amount = "\(String.currency(value: params.amount))"
                items.append(BMMultiLineItem(title: Localizable.shared.strings.amount.uppercased(), detail: amount, detailFont: RegularFont(size: 16), detailColor: UIColor.white, copy: true))
            }
            
            var addressType = AppModel.sharedManager().getAddressTypeString(params.newAddressType)
            if params.newAddressType == BMAddressTypeMaxPrivacy {
                addressType = Localizable.shared.strings.max_privacy.capitalized
            }
            else if params.newAddressType == BMAddressTypeOfflinePublic {
                addressType = Localizable.shared.strings.public_offline.capitalized
            }
            else {
                addressType = Localizable.shared.strings.regular.capitalized
            }
            
            items.append(BMMultiLineItem(title: Localizable.shared.strings.transaction_type.uppercased(), detail:addressType , detailFont: RegularFont(size: 16), detailColor: UIColor.white))

            
            if !params.address.isEmpty {
                items.append(BMMultiLineItem(title: Localizable.shared.strings.sbbs_address.uppercased(), detail: params.address, detailFont: RegularFont(size: 16), detailColor: UIColor.white, copy: true))
            }
            
            if(!params.identity.isEmpty) {
                items.append(BMMultiLineItem(title: Localizable.shared.strings.identity.uppercased(), detail: params.identity, detailFont: RegularFont(size: 16), detailColor: UIColor.white, copy: true, copiedText: Localizable.shared.strings.copied_to_clipboard))
            }
            
            items.append(BMMultiLineItem(title: Localizable.shared.strings.address, detail: token, detailFont: RegularFont(size: 16), detailColor: UIColor.white, copy: true))
        }
        else {
            let address = AppModel.sharedManager().findAddress(byID: token)
 
            var detail = Localizable.shared.strings.regular
            if isMiningPool {
                detail = detail + " (\(Localizable.shared.strings.for_pool.lowercased()))"
            }

            items.append(BMMultiLineItem(title: Localizable.shared.strings.transaction_type.uppercased(), detail: detail, detailFont: RegularFont(size: 16), detailColor: UIColor.white, copy: false))
            
            if address != nil && address?.isContact == false && send == false {
                items.append(BMMultiLineItem(title: Localizable.shared.strings.address_expiration.uppercased(), detail: address?.duration == 0 ? Localizable.shared.strings.permanent : Localizable.shared.strings.one_time, detailFont: RegularFont(size: 16), detailColor: UIColor.white, copy: true))
            }

            items.append(BMMultiLineItem(title: Localizable.shared.strings.sbbs_address, detail: token, detailFont: RegularFont(size: 16), detailColor: UIColor.white, copy: true))
        }
        
        
        if send {
            setGradientTopBar(mainColor: UIColor.main.heliotrope, addedStatusView: false)
        }
        else {
            setGradientTopBar(mainColor: UIColor.main.brightSkyBlue)
        }
        
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register([BMMultiLinesCell.self, BMCopyCell.self])
        tableView.tableFooterView = footerView

        
        title = Localizable.shared.strings.address_details
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)        
    }
    
    @objc private func onCopy() {
        if let token = items.last?.detail {
            UIPasteboard.general.string = token
            ShowCopied(text: Localizable.shared.strings.address_copied)
            didCopyToken?()
            back()
        }
    }
}

extension ShowTokenViewController : UITableViewDelegate {
        
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
}

extension ShowTokenViewController : UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return items.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let title = items[indexPath.row].title
        if title == Localizable.shared.strings.address {
            let cell = tableView
                .dequeueReusableCell(withType: BMCopyCell.self, for: indexPath)
                .configured(with: items[indexPath.row])
            cell.increaseSpace = true
            return cell
        }
        else {
            let cell = tableView
                .dequeueReusableCell(withType: BMMultiLinesCell.self, for: indexPath)
                .configured(with: items[indexPath.row])
            cell.increaseSpace = true
            return cell
        }
    }
}
