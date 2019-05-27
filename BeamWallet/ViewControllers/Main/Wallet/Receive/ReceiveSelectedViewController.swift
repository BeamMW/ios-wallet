//
// ReceiveSelectedViewController.swift
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

class ReceiveSelectedViewController: BaseTableViewController {
    
    private var address:BMAddress!
    
    init(address:BMAddress) {
        super.init(nibName: nil, bundle: nil)
        
        self.address = address
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError(LocalizableStrings.fatalInitCoderError)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.hidesBackButton = true
        
        largeTitle = LocalizableStrings.receive.uppercased()

        let footerView = UIView(frame: CGRect(x: 0, y: 0, width: UIScreen.main.bounds.size.width, height: 140))
        
        let button = BMButton.defaultButton(frame: CGRect(x: (footerView.frame.size.width - 143)/2, y: 40, width: 143, height: 44), color: UIColor.main.brightSkyBlue.withAlphaComponent(0.2))
        button.borderColor = UIColor.main.brightSkyBlue
        button.borderWidth = 1
        button.setTitleColor(UIColor.main.brightSkyBlue, for: .normal)
        button.setTitle(LocalizableStrings.next, for: .normal)
        button.setImage(IconNextLightBlue(), for: .normal)
        button.addTarget(self, action: #selector(onNext), for: .touchUpInside)
        footerView.addSubview(button)
        
        tableView.register([ReceiveAddressNewCell.self, ReceiveAddressListCell.self])
        tableView.delegate = self
        tableView.dataSource = self
        tableView.keyboardDismissMode = .interactive
        tableView.tableFooterView = footerView
        
        addLeftButton(image: IconBack())
    }
    
    @objc private func onNext() {
        let vc = ReceiveDetailViewController(address: address)
        pushViewController(vc: vc)
    }
}

extension ReceiveSelectedViewController : UITableViewDelegate {
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        self.didEndScroll(scrollView: scrollView)
    }
    
    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        self.didEndScroll(scrollView: scrollView)
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        self.didScroll(scrollView: scrollView)
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 10
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
}

extension ReceiveSelectedViewController : UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView
            .dequeueReusableCell(withType: ReceiveAddressNewCell.self, for: indexPath)
            .configured(with: (hideLine: false, address: address))
        return cell
        
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let view = UIView()
        view.backgroundColor = UIColor.clear
        return view
    }
}

