//
//  DAOAppsViewController.swift
//  BeamWallet
//
//  Created by Denis on 08.09.2021.
//  Copyright © 2021 Denis. All rights reserved.
//

import Foundation

class DAOAppsViewController: BaseTableViewController {
    
    private let viewModel = DAOListViewModel()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        viewModel.onDataChanged = { [weak self] in
            self?.tableView.reloadData()
        }
        viewModel.loadItems()
        
        setGradientTopBar(mainColor: UIColor.main.peacockBlue, addedStatusView: true)

        title = Localizable.shared.strings.dAppStore.uppercased()
        
        tableView.register([DAOAppCell.self])
        
        tableView.delegate = self
        tableView.dataSource = self
    }
}


extension DAOAppsViewController : UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let view = UIView()
        view.backgroundColor = UIColor.clear
        return view
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 10
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 100
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        AppModel.sharedManager().startApp(self, app: viewModel.items[indexPath.row])
    }
}


extension DAOAppsViewController : UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.items.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell =  tableView
            .dequeueReusableCell(withType: DAOAppCell.self, for: indexPath)
           
        cell.configure(with: (row: indexPath.row, app: viewModel.items[indexPath.row]))
        
        return cell
    }
}
