//
// AssetSwapsViewController.swift
// BeamWallet
//
// Copyright 2026 Beam Development
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

class AssetSwapsViewController: BaseTableViewController {

    private let viewModel = AssetSwapsViewModel()
    private let segmented = UISegmentedControl(items: [
        Localizable.shared.strings.asset_swap_open_orders,
        Localizable.shared.strings.asset_swap_my_orders,
        Localizable.shared.strings.asset_swap_history,
    ])
    private let segmentedHeader = UIView()
    private let emptyLabel = UILabel()
    private let segmentedHeaderHeight: CGFloat = 60

    override func viewDidLoad() {
        super.viewDidLoad()

        setGradientTopBar(mainColor: UIColor.main.peacockBlue, addedStatusView: true, menu: self.navigationController?.viewControllers.count == 1)

        title = Localizable.shared.strings.asset_swaps

        addRightButton(image: IconAdd(), target: self, selector: #selector(onNewSwap))

        segmented.selectedSegmentIndex = 0
        segmented.addTarget(self, action: #selector(onSegmentChange), for: .valueChanged)
        if #available(iOS 13.0, *) {
            segmented.selectedSegmentTintColor = UIColor.main.brightTeal
            segmented.setTitleTextAttributes([.foregroundColor: UIColor.white], for: .normal)
            segmented.setTitleTextAttributes([.foregroundColor: UIColor.main.marineOriginal], for: .selected)
        }

        segmentedHeader.backgroundColor = UIColor.main.marine
        segmentedHeader.addSubview(segmented)
        view.addSubview(segmentedHeader)

        tableView.delegate = self
        tableView.dataSource = self
        tableView.separatorStyle = .none
        tableView.register(AssetSwapOrderCell.self, forCellReuseIdentifier: "AssetSwapOrderCell")
        tableView.addPullToRefresh(target: self, handler: #selector(refresh(_:)))

        emptyLabel.text = Localizable.shared.strings.asset_swap_no_orders
        emptyLabel.textAlignment = .center
        emptyLabel.numberOfLines = 0
        emptyLabel.font = RegularFont(size: 16)
        emptyLabel.textColor = Settings.sharedManager().isDarkMode ? UIColor.main.steel : UIColor.main.blueyGrey
        view.addSubview(emptyLabel)

        viewModel.onDataChanged = { [weak self] in
            self?.tableView.stopRefreshing()
            self?.tableView.reloadData()
            self?.updateEmptyState()
        }

        viewModel.reload()
        updateEmptyState()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        viewModel.reload()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        let tableTop = tableView.frame.origin.y
        let width = view.bounds.width
        segmentedHeader.frame = CGRect(x: 0, y: tableTop, width: width, height: segmentedHeaderHeight)
        segmented.frame = CGRect(x: defaultX, y: 12, width: width - 2 * defaultX, height: 36)
        view.bringSubviewToFront(segmentedHeader)

        tableView.frame = CGRect(
            x: tableView.frame.origin.x,
            y: tableTop + segmentedHeaderHeight,
            width: tableView.frame.width,
            height: tableView.frame.height - segmentedHeaderHeight
        )

        emptyLabel.frame = CGRect(x: 20, y: navigationBarOffset + 120, width: view.bounds.width - 40, height: 60)
    }

    private func updateEmptyState() {
        emptyLabel.isHidden = !viewModel.ordersForActiveTab.isEmpty
    }

    @objc private func onNewSwap() {
        pushViewController(vc: AssetSwapCreateViewController())
    }

    @objc private func onSegmentChange() {
        viewModel.selectedTab = AssetSwapsTab(rawValue: segmented.selectedSegmentIndex) ?? .open
        tableView.reloadData()
        updateEmptyState()
    }

    @objc private func refresh(_ sender: Any) {
        viewModel.reload()
    }
}

extension AssetSwapsViewController: UITableViewDelegate, UITableViewDataSource {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.ordersForActiveTab.count
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 80
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "AssetSwapOrderCell", for: indexPath) as! AssetSwapOrderCell
        cell.configure(with: viewModel.ordersForActiveTab[indexPath.row], row: indexPath.row)
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let order = viewModel.ordersForActiveTab[indexPath.row]
        let vc = AssetSwapDetailsViewController(order: order)
        pushViewController(vc: vc)
    }
}
