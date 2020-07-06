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

        if send {
            setGradientTopBar(mainColor: UIColor.main.heliotrope, addedStatusView: false)
        }
        else {
            setGradientTopBar(mainColor: UIColor.main.brightSkyBlue)
        }
        
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register([BMMultiLinesCell.self])
                
        title = Localizable.shared.strings.show_token
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
        return 1
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let item = BMMultiLineItem(title: Localizable.shared.strings.transaction_token, detail: token, detailFont: RegularFont(size: 16), detailColor: nil, copy: true)
        let cell = tableView
            .dequeueReusableCell(withType: BMMultiLinesCell.self, for: indexPath)
            .configured(with: item)
        cell.increaseSpace = true
        return cell
    }
}
