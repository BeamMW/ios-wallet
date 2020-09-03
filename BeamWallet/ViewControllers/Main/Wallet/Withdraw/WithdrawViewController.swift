//
// ReceiveViewController.swift
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

class WithdrawViewController: BaseTableViewController {

    private var items = [BMMultiLineItem]()
    private var amount:String = ""
    private var userId:String = ""
    private var address: BMAddress?
    
    init(amount:String, userId:String) {
        super.init(nibName: nil, bundle: nil)
        self.amount = amount
        self.userId = userId
    }
    
    required init?(coder: NSCoder) {
        fatalError(Localizable.shared.strings.fatalInitCoderError)
    }
    
    override var tableStyle: UITableView.Style {
        get {
            return .grouped
        }
        set {
            super.tableStyle = newValue
        }
    }
    
    private lazy var footerView: UIView = {
        var view = UIView(frame: CGRect(x: 0, y: 0, width: UIScreen.main.bounds.size.width, height: 115))
        
        var sendButton = BMButton.defaultButton(frame: CGRect(x: (UIScreen.main.bounds.size.width-143)/2, y: 20, width: 143, height: 44), color: UIColor.main.heliotrope)
        sendButton.setImage(IconSendBlue(), for: .normal)
        sendButton.setTitle(Localizable.shared.strings.confirm_2.lowercased(), for: .normal)
        sendButton.setTitleColor(UIColor.main.marineOriginal, for: .normal)
        sendButton.setTitleColor(UIColor.main.marineOriginal.withAlphaComponent(0.5), for: .highlighted)
        sendButton.addTarget(self, action: #selector(onNext), for: .touchUpInside)
        view.addSubview(sendButton)
        
        
        return view
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setGradientTopBar(mainColor: UIColor.main.heliotrope)
        
        title = Localizable.shared.strings.withdraw.uppercased()
        
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register([BMMultiLinesCell.self])
        tableView.keyboardDismissMode = .interactive
        tableView.contentInsetAdjustmentBehavior = .never
        tableView.tableHeaderView = UIView(frame: CGRect(x: 0.0, y: 0.0, width: 0.0, height: 10))
        tableView.tableHeaderView?.backgroundColor = UIColor.clear
        tableView.sectionHeaderHeight = 0.0
        tableView.sectionFooterHeight = 0.0
        tableView.tableFooterView = footerView
        
        items.append(BMMultiLineItem(title: Localizable.shared.strings.amount.uppercased(), detail: amount + Localizable.shared.strings.beam, detailFont: SemiboldFont(size: 16), detailColor: UIColor.main.heliotrope))
        items.append(BMMultiLineItem(title: Localizable.shared.strings.withdraw_cofirm, detail: nil, detailFont: nil, detailColor: nil))
        
        address = AppModel.sharedManager().generateWithdrawAddress()        
    }
    
    @objc private func onNext() {
        
    }
}


extension WithdrawViewController : UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let view = UIView()
        view.backgroundColor = UIColor.clear
        return view
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 20
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
}


extension WithdrawViewController : UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return items.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell =  tableView
            .dequeueReusableCell(withType: BMMultiLinesCell.self, for: indexPath)
            .configured(with: items[indexPath.section])
        
        return cell
    }
}
