//
// UTXOViewController.swift
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

class UTXOViewController: BaseTableViewController {
    
    private let viewModel = UTXOViewModel(selected: .all)
    
    private let header = BMTableHeaderTitleView.init(segments: [Localizable.shared.strings.all, Localizable.shared.strings.available, Localizable.shared.strings.spent])
    
    private let hideUTXOView = UTXOSecurityView().loadNib()

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
        
        title = Localizable.shared.strings.utxo
                
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register([UTXOCell.self, BMEmptyCell.self])
        tableView.addPullToRefresh(target: self, handler: #selector(refreshData(_:)))
        tableView.isHidden = Settings.sharedManager().isHideAmounts
        header.isHidden = Settings.sharedManager().isHideAmounts

        hideUTXOView.isHidden = !Settings.sharedManager().isHideAmounts
        view.insertSubview(hideUTXOView, at: 0)

        header.lineColor = UIColor.main.peacockBlue
        header.selectedIndex = viewModel.selectedState.rawValue
        header.delegate = self
        view.insertSubview(header, at: 0)
        
        Settings.sharedManager().addDelegate(self)

        rightButton()
        
        subscribeUpdates()
    }
    
    deinit {
        Settings.sharedManager().removeDelegate(self)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        header.y = tableView.y - 5
        tableView.y = header.y + header.h
        tableView.h = self.view.h - tableView.y
        
        hideUTXOView.frame = CGRect(x: 0, y: header.y, width: tableView.frame.size.width, height: (UIScreen.main.bounds.size.height - (header.y)))
    }
    
    private func subscribeUpdates() {
        viewModel.onDataChanged = { [weak self] in
            UIView.performWithoutAnimation {
                self?.tableView.stopRefreshing()
                self?.tableView.reloadData()
            }
        }
        
        viewModel.onStatusChanged = { [weak self] in
            self?.tableView.stopRefreshing()
        }
    }
    
    private func rightButton() {
        addRightButton(image: Settings.sharedManager().isHideAmounts ? IconShowBalance() : IconHideBalance(), target: self, selector: #selector(onHideAmounts))
    }
    
    @objc private func refreshData(_ sender: Any) {
        AppModel.sharedManager().getWalletStatus()
        AppModel.sharedManager().getUTXO()
    }
}

extension UTXOViewController : UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UTXOCell.height()
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        if viewModel.utxos.count > 0 {
            let vc = UTXODetailViewController(utxo: viewModel.utxos[indexPath.row])
            self.pushViewController(vc: vc)
        }
    }
}

extension UTXOViewController : UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.utxos.count == 0 ? 1 : viewModel.utxos.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        if viewModel.utxos.count == 0 {
            let cell = tableView
                .dequeueReusableCell(withType: BMEmptyCell.self, for: indexPath)
                .configured(with: Localizable.shared.strings.not_found)
            cell.backgroundView?.backgroundColor = UIColor.main.marineThree
            return cell
        }
        else {
            let cell = tableView
                .dequeueReusableCell(withType: UTXOCell.self, for: indexPath)
                .configured(with: (row: indexPath.row, utxo: viewModel.utxos[indexPath.row]))
            return cell
        }
    }
}

extension UTXOViewController : SettingsModelDelegate {
    func onChangeHideAmounts() {
        rightButton()
        
        hideUTXOView.isHidden = !Settings.sharedManager().isHideAmounts
        tableView.isHidden = Settings.sharedManager().isHideAmounts
        header.isHidden = Settings.sharedManager().isHideAmounts
    }
}

extension UTXOViewController : BMTableHeaderTitleViewDelegate {
    func onDidSelectSegment(index: Int) {
        self.viewModel.selectedState = UTXOViewModel.UTXOSelectedState(rawValue: index) ?? .all
    }
}
