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

@objc protocol BMUTXOTableDelegate: AnyObject {
    @objc func didScroll(scrollView:UIScrollView)
}

class UTXOTableView: UITableViewController {

    weak var delegate: BMUTXOTableDelegate?

    public var viewModel = UTXOViewModel()

    public var selectedIndex = 0 {
        didSet{
            viewModel.selectedState = UTXOViewModel.UTXOSelectedState(rawValue: selectedIndex) ?? .available
            tableView.tag = selectedIndex
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.separatorStyle = .none
        tableView.register([BMEmptyCell.self, UTXOCell.self])
        
        subscribeUpdates()
    }
    
    private func subscribeUpdates() {
        viewModel.onDataChanged = { [weak self] in
            UIView.performWithoutAnimation {
                self?.tableView.stopRefreshing()
                self?.tableView.reloadData()
            }
        }
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if viewModel.utxos.count == 0 {
            return tableView.h - 120
        }
        return UITableView.automaticDimension
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        if viewModel.utxos.count > 0 {
            if let top = UIApplication.getTopMostViewController() {
                let vc = UTXODetailViewController(utxo: viewModel.utxos[indexPath.row])
                top.pushViewController(vc: vc)
            }
        }
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return (Settings.sharedManager().isHideAmounts ? 0 : 1)
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return (viewModel.utxos.count == 0 ? 1 : viewModel.utxos.count)
    }
    

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        if viewModel.utxos.count == 0 {
            let cell = tableView
                .dequeueReusableCell(withType: BMEmptyCell.self, for: indexPath)
                .configured(with: (text: selectedIndex == 1 ? Localizable.shared.strings.utxo_empty_progress : Localizable.shared.strings.utxo_empty, image: IconUtxoEmpty()))
            return cell
        }
        else{
            let cell = tableView
                .dequeueReusableCell(withType: UTXOCell.self, for: indexPath)
                .configured(with: (row: indexPath.row, utxo: viewModel.utxos[indexPath.row]))
            return cell
        }
    }
    
    override func scrollViewDidScroll(_ scrollView: UIScrollView) {
        self.delegate?.didScroll(scrollView: scrollView)
    }
}
