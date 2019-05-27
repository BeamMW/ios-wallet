//
// ReceiveListViewController.swift
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

class ReceiveListViewController: BaseTableViewController {
    
    private var address:BMAddress?
    private var addresses = [BMAddress]()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        largeTitle = LocalizableStrings.receive.uppercased()
        
        if let addresses = AppModel.sharedManager().walletAddresses {
            self.addresses = addresses as! [BMAddress]
        }
        self.addresses = self.addresses.filter { $0.isExpired() == false}
        
        tableView.register([ReceiveAddressNewCell.self, ReceiveAddressListCell.self])
        tableView.delegate = self
        tableView.dataSource = self
        tableView.keyboardDismissMode = .interactive
        
        addLeftButton(image: IconBack())
    }
}

extension ReceiveListViewController : UITableViewDelegate {
    
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
        switch section {
        case 1:
           return ReceiveNewAddressHeader.height
        default:
            return 10
        }
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        if indexPath.section == 1 {
            let vc = ReceiveSelectedViewController(address: addresses[indexPath.row])
            pushViewController(vc: vc)
        }
    }
}

extension ReceiveListViewController : UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return address == nil ? 2 : 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 1:
            return addresses.count
        default:
            return 1
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        switch indexPath.section {
        case 0:
            let cell = tableView
                .dequeueReusableCell(withType: ReceiveAddressNewCell.self, for: indexPath)
                .configured(with: (hideLine: false, address: address))
            return cell
        case 1:
            let cell = tableView
                .dequeueReusableCell(withType: ReceiveAddressListCell.self, for: indexPath).configured(with: (row: indexPath.row, address: addresses[indexPath.row]))
            return cell
        default:
            return BaseCell()
        }
      
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        
        switch section {
        case 1:
            let view: ReceiveNewAddressHeader = UIView.fromNib()
            view.delegate = self
            return view
        default:
            let view = UIView()
            view.backgroundColor = UIColor.clear
            return view
        }
    }
}

extension ReceiveListViewController : ReceiveCellProtocol {
    
    func onNewAddress() {
        AppModel.sharedManager().generateNewWalletAddress { (address, error) in
            if let result = address {
                DispatchQueue.main.async {
                    NotificationManager.sharedManager.subscribeToTopic(topic: result.walletId)
                    
                    let vc = ReceiveNewAddressViewController(address: result)
                    self.pushViewController(vc: vc)
                }
            }
            else if let reason = error?.localizedDescription {
                DispatchQueue.main.async {
                    self.alert(message: reason)
                }
            }
        }

    }
}

