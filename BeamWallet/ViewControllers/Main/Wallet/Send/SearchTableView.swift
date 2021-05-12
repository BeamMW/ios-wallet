//
// UTXOTableView.swift
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

@objc protocol SearchTableViewDelegate: AnyObject {
    @objc func didSelectContact(contact:BMContact)
}

class SearchTableView: UITableViewController {
    
    weak var delegate: SearchTableViewDelegate?

    public var displayEmpty = true
    public var contacts = [BMContact]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.separatorStyle = .none
        tableView.register([BMEmptyCell.self, BMAddressCell.self])
        tableView.keyboardDismissMode = .interactive
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
    }
    
    
    public func reload() {
        tableView.reloadData()
        
        if tableView.numberOfRows(inSection: 0) < 3 {
            tableView.contentInset = UIEdgeInsets.zero
        }
        else{
            tableView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 300, right: 0)
        }
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if contacts.count == 0 {
            return 300
        }
        return UITableView.automaticDimension
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        if contacts.count > 0 {
            self.delegate?.didSelectContact(contact: contacts[indexPath.row])
        }
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if displayEmpty {
            return (contacts.count == 0 ? 1 : contacts.count)
        }
        else {
            return contacts.count
        }
    }
    
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        if contacts.count == 0 {
            let cell = tableView
                .dequeueReusableCell(withType: BMEmptyCell.self, for: indexPath)
                .configured(with: (text: Localizable.shared.strings.not_found, image: IconAddressbookEmpty()))
            return cell
        }
        else {
            let cell =  tableView
                .dequeueReusableCell(withType: BMAddressCell.self, for: indexPath)
            cell.configure(with: (row: indexPath.row, address: contacts[indexPath.row].address, displayTransaction: true))
            
            return cell
        }
    }
}
