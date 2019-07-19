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

class AddressExpiresPickerViewController: BaseTableViewController {

    public var completion : ((Int) -> Void)?
    
    private var items:[BMDuration] = []
    private var selectedDuration:Int!
    private var currentDuration:Int!
    
    init(duration:Int) {
        super.init(nibName: nil, bundle: nil)
        
        let current = BMDuration()
        current.name = Localizable.shared.strings.as_set
        current.duration = Int32(duration)
        current.selected = true
        
        let h24 = BMDuration()
        h24.duration = 24
        h24.name = Localizable.shared.strings.in_24_hours
        h24.selected = false

        let never = BMDuration()
        never.duration = 0
        never.name = Localizable.shared.strings.never
        never.selected = false

        items.append(current)
        items.append(h24)
        items.append(never)
        
        self.currentDuration = (duration > 0) ? 24 : 0
        self.selectedDuration = -1
    }
    
    required init?(coder aDecoder: NSCoder) {
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
    
    override var isUppercasedTitle: Bool {
        get{
            return true
        }
        set{
            super.isUppercasedTitle = true
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        isGradient = true
        setGradientTopBar(mainColor: UIColor.main.peacockBlue, addedStatusView: true)

        title = Localizable.shared.strings.exp_date.uppercased()

     //   addRightButton(title: Localizable.shared.strings.save, target: self, selector: #selector(onSave), enabled: false)
        
        tableView.delegate = self
        tableView.dataSource = self
        tableView.separatorColor = UIColor.white.withAlphaComponent(0.13)
        tableView.separatorStyle = .singleLine
        tableView.contentInsetAdjustmentBehavior = .never
        tableView.tableHeaderView = UIView(frame: CGRect(x: 0.0, y: 0.0, width: 0.0, height: 20))
        tableView.tableHeaderView?.backgroundColor = UIColor.main.marine
        tableView.register(AddressDurationCell.self)
    }
    
    @objc private func onSave(sender:UIBarButtonItem) {
        self.completion?(selectedDuration)
        self.back()
    }
}

extension AddressExpiresPickerViewController : UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        for item in items {
            item.selected = false
        }
        
        items[indexPath.row].selected = true

        selectedDuration = (indexPath.row == 1) ? 24 : 0
        
       // enableRightButton(enabled: (indexPath.row != 0))
       
        tableView.reloadData()
        
        self.completion?(selectedDuration)
        
        self.back()
    }
}

extension AddressExpiresPickerViewController : UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return items.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let duration = items[indexPath.row]
        
        let cell =  tableView
            .dequeueReusableCell(withType: AddressDurationCell.self, for: indexPath)
            .configured(with: (duration:duration , selected: duration.selected))
        
        return cell
    }
}

