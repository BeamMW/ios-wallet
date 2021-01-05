//
// MaxPrivacyDetailViewController.swift
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
import PopOverMenu

class MaxPrivacyDetailViewController: BaseTableViewController {
    
    private let viewModel = MaxPrivacyDetailViewModel()
    @IBOutlet  private var flterView: UIView!
    @IBOutlet  private var flterSubView: UIView!
    @IBOutlet  private var filterButton1: UIButton!
    @IBOutlet  private var filterButton2: UIButton!
    @IBOutlet  private var filterButton3: UIButton!
    @IBOutlet  private var filterButton4: UIButton!

    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        filterButton1.setTitleColor(UIColor.main.marine, for: .normal)
        filterButton2.setTitleColor(UIColor.main.marine, for: .normal)
        filterButton3.setTitleColor(UIColor.main.marine, for: .normal)
        filterButton4.setTitleColor(UIColor.main.marine, for: .normal)

        filterButton1.setImage(UIImage(named: "iconDoneBlue")?.maskWithColor(color: UIColor.clear), for: .normal)
        filterButton2.setImage(UIImage(named: "iconDoneBlue")?.maskWithColor(color:UIColor.clear), for: .normal)
        filterButton3.setImage(UIImage(named: "iconDoneBlue")?.maskWithColor(color:UIColor.clear), for: .normal)
        filterButton4.setImage(UIImage(named: "iconDoneBlue")?.maskWithColor(color: UIColor.clear), for: .normal)

        filterButton1.setImage(UIImage(named: "iconDoneBlue")?.maskWithColor(color: UIColor.main.marine), for: .selected)
        filterButton2.setImage(UIImage(named: "iconDoneBlue")?.maskWithColor(color: UIColor.main.marine), for: .selected)
        filterButton3.setImage(UIImage(named: "iconDoneBlue")?.maskWithColor(color: UIColor.main.marine), for: .selected)
        filterButton4.setImage(UIImage(named: "iconDoneBlue")?.maskWithColor(color: UIColor.main.marine), for: .selected)
        
        setGradientTopBar(mainColor: UIColor.main.peacockBlue, addedStatusView: true)
        addRightButton(image: IconFilter(), target: self, selector: #selector(onFilter))

        title = Localizable.shared.strings.max_privacy
        
        tableView.register(MaxPrivacyDetailCell.self)
        tableView.separatorStyle = .none
        tableView.dataSource = self
        tableView.delegate = self
        tableView.tableHeaderView = UIView(frame: CGRect(x: 0, y: 0, width: 320, height: 10))
        
        viewModel.onDataChanged = {
            [weak self] in
            
            guard let strongSelf = self else { return }
            
            strongSelf.tableView.reloadData()
        }
        
        flterView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(onHideFilter)))
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        viewModel.filterUTXOS()
    }
    
    @objc private func onFilter() {
        self.view.addSubview(flterView)
        flterView.isHidden = false
    }
    
    @objc private func onHideFilter() {
        flterView.isHidden = true
    }
    
    @IBAction private func onSelectFilter(sender: UIButton) {
        filterButton1.isSelected = false
        filterButton2.isSelected = false
        filterButton3.isSelected = false
        filterButton4.isSelected = false
        sender.isSelected = true

        self.flterView.isHidden = true
        self.viewModel.filterType = MaxPrivacyDetailViewModel.UTXOFilterType(rawValue: sender.tag) ??  MaxPrivacyDetailViewModel.UTXOFilterType.time_ear
    }
}

extension MaxPrivacyDetailViewController : UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let header: MaxPrivacyDetailHeader = UIView.fromNib()
        header.backgroundColor = self.view.backgroundColor
        return header
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 40
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 60
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
}

extension MaxPrivacyDetailViewController : UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.utxos.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView
            .dequeueReusableCell(withType: MaxPrivacyDetailCell.self, for: indexPath)
        cell.configure(with: (row: indexPath.row, utxo: viewModel.utxos[indexPath.row]))

        return cell
    }
}
