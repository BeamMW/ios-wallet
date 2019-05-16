//
// AddressExpiresPickerViewController.swift
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

class AddressExpiresPickerViewController: BaseViewController {

    public var completion : ((Int) -> Void)?
    
    private var items:[BMDuration] = []
    private var selectedDuration:Int!
    private var currentDuration:Int!
    
    @IBOutlet private weak var tableView: UITableView!
    
    init(duration:Int) {
        super.init(nibName: nil, bundle: nil)
        
        let h24 = BMDuration()
        h24.duration = 24
        h24.name = LocalizableStrings.in_24_hours
        
        let never = BMDuration()
        never.duration = 0
        never.name = LocalizableStrings.never
        
        items.append(h24)
        items.append(never)
        
        self.currentDuration = duration
        self.selectedDuration = duration
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError(LocalizableStrings.fatalInitCoderError)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = LocalizableStrings.address_expires;
        
        tableView.register(AddressDurationCell.self)
        
        addRightButton(title: LocalizableStrings.save, targer: self, selector: #selector(onSave), enabled: false)
    }

    @objc private func onSave(sender:UIBarButtonItem) {
        self.completion?(selectedDuration)
        self.navigationController?.popViewController(animated: true)
    }
}

extension AddressExpiresPickerViewController : UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return AddressDurationCell.height()
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        selectedDuration = (indexPath.row == 0) ? 24 : 0
        
        if selectedDuration == currentDuration {
            enableRightButton(enabled: false)
        }
        else{
            enableRightButton(enabled: true)
        }
        
        tableView.reloadData()
    }
}

extension AddressExpiresPickerViewController : UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return items.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell =  tableView
            .dequeueReusableCell(withType: AddressDurationCell.self, for: indexPath)
            .configured(with: (duration: items[indexPath.row], selected: selectedDuration == items[indexPath.row].duration))
        return cell
    }
}

