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
    
    private let viewModel = UTXOViewModel(selected: .available)
    
    private var header = BMSegmentView.init(segments: [Localizable.shared.strings.available, Localizable.shared.strings.in_progress, Localizable.shared.strings.spent, Localizable.shared.strings.unavailable, Localizable.shared.strings.maturing, Localizable.shared.strings.in_progress_out, Localizable.shared.strings.in_progress_in])
    
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
        tableView.register([UTXOCell.self, BMEmptyCell.self, UTXOBlockCell.self])
        tableView.addPullToRefresh(target: self, handler: #selector(refreshData(_:)))
        tableView.isUserInteractionEnabled = !Settings.sharedManager().isHideAmounts

        hideUTXOView.isHidden = !Settings.sharedManager().isHideAmounts
        view.addSubview(hideUTXOView)

        header.lineColor = UIColor.main.peacockBlue
        header.selectedIndex = viewModel.selectedState.rawValue
        header.delegate = self
        
        Settings.sharedManager().addDelegate(self)

        rightButton()
        
        subscribeUpdates()
    }
    
    deinit {
        Settings.sharedManager().removeDelegate(self)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        hideUTXOView.frame = CGRect(x: 0, y: tableView.y + 100, width: tableView.frame.size.width, height: (UIScreen.main.bounds.size.height - (tableView.y + 100)))
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
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return (section == 0 ? 0 : BMSegmentView.height)
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        if viewModel.utxos.count > 0 && indexPath.section == 1 {
            let vc = UTXODetailViewController(utxo: viewModel.utxos[indexPath.row])
            self.pushViewController(vc: vc)
        }
    }
}

extension UTXOViewController : UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return (Settings.sharedManager().isHideAmounts ? 1 : 2)
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return (section == 0 ? 1 : (viewModel.utxos.count == 0 ? 1 : viewModel.utxos.count))
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        return(section == 0 ? nil : header)
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        if indexPath.section == 0 {
            let cell = tableView
                .dequeueReusableCell(withType: UTXOBlockCell.self, for: indexPath)
                .configured(with: AppModel.sharedManager().walletStatus)
            return cell
        }
        else{
            if viewModel.utxos.count == 0 {
                let cell = tableView
                    .dequeueReusableCell(withType: BMEmptyCell.self, for: indexPath)
                    .configured(with: (text: Localizable.shared.strings.utxo_empty, image: IconUtxoEmpty()))
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
}

extension UTXOViewController : SettingsModelDelegate {
    func onChangeHideAmounts() {
        rightButton()
        
        hideUTXOView.isHidden = !Settings.sharedManager().isHideAmounts
        tableView.isUserInteractionEnabled = !Settings.sharedManager().isHideAmounts
        tableView.reloadData()
    }
}

extension UTXOViewController : BMTableHeaderTitleViewDelegate {
    func onDidSelectSegment(index: Int) {
        self.viewModel.selectedState = UTXOViewModel.UTXOSelectedState(rawValue: index) ?? .available
    }
}
