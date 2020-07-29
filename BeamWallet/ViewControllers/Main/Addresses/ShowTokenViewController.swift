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

    private var token = ""
    private var send = false
    private var items = [BMMultiLineItem]()
    
    private lazy var footerView: UIView = {
        var view = UIView(frame: CGRect(x: 0, y: 0, width: UIScreen.main.bounds.size.width, height: 115))
        
        var sendButton = BMButton.defaultButton(frame: CGRect(x: (UIScreen.main.bounds.size.width-143)/2, y: 40, width: 143, height: 44), color: UIColor.main.brightSkyBlue)
        sendButton.setImage(IconCopyBlue(), for: .normal)
        sendButton.setTitle(Localizable.shared.strings.copy.lowercased(), for: .normal)
        sendButton.setTitleColor(UIColor.main.marineOriginal, for: .normal)
        sendButton.setTitleColor(UIColor.main.marineOriginal.withAlphaComponent(0.5), for: .highlighted)
        sendButton.addTarget(self, action: #selector(onCopy), for: .touchUpInside)
        view.addSubview(sendButton)
        
        
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
                let amount = "\(String.currency(value: params.amount)) BEAM"
                items.append(BMMultiLineItem(title: Localizable.shared.strings.amount.uppercased(), detail: amount, detailFont: RegularFont(size: 16), detailColor: UIColor.white, copy: true))
            }
            
            items.append(BMMultiLineItem(title: Localizable.shared.strings.token_type.uppercased(), detail: params.isPermanentAddress ? Localizable.shared.strings.permanent : Localizable.shared.strings.one_time, detailFont: RegularFont(size: 16), detailColor: UIColor.white, copy: true))
            
            if params.isMaxPrivacy && !params.isOffline {
                items.append(BMMultiLineItem(title: Localizable.shared.strings.transaction_type.uppercased(), detail: Localizable.shared.strings.max_privacy_title, detailFont: RegularFont(size: 16), detailColor: UIColor.white))
            }
            else if params.isMaxPrivacy && params.isOffline {
                items.append(BMMultiLineItem(title: Localizable.shared.strings.transaction_type.uppercased(), detail: "\(Localizable.shared.strings.max_privacy_title),\(Localizable.shared.strings.offline.lowercased())", detailFont: RegularFont(size: 16), detailColor: UIColor.white))
            }
            else {
                items.append(BMMultiLineItem(title: Localizable.shared.strings.transaction_type.uppercased(), detail: Localizable.shared.strings.regular, detailFont: RegularFont(size: 16), detailColor: UIColor.white))
            }
            
            items.append(BMMultiLineItem(title: Localizable.shared.strings.address.uppercased(), detail: params.address, detailFont: RegularFont(size: 16), detailColor: UIColor.white, copy: true))
            
            if(!params.identity.isEmpty) {
                items.append(BMMultiLineItem(title: Localizable.shared.strings.identity.uppercased(), detail: params.identity, detailFont: RegularFont(size: 16), detailColor: UIColor.white, copy: true))
            }
        }
        
        items.append(BMMultiLineItem(title: Localizable.shared.strings.transaction_token, detail: token, detailFont: RegularFont(size: 16), detailColor: UIColor.white, copy: true))
        
        if send {
            setGradientTopBar(mainColor: UIColor.main.heliotrope, addedStatusView: false)
        }
        else {
            setGradientTopBar(mainColor: UIColor.main.brightSkyBlue)
        }
        
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register([BMMultiLinesCell.self])
        if !send {
            tableView.tableFooterView = footerView
        }
        
        title = Localizable.shared.strings.show_token
    }
    
    @objc private func onCopy() {
        if let token = items.last?.detail {
            UIPasteboard.general.string = token
            ShowCopied()
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
        let cell = tableView
            .dequeueReusableCell(withType: BMMultiLinesCell.self, for: indexPath)
            .configured(with: items[indexPath.row])
        cell.increaseSpace = true
        return cell
    }
}
