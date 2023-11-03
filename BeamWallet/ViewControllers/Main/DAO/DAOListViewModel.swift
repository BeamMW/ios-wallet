//
//  DAOListViewModel.swift
//  BeamWallet
//
//  Created by Denis on 08.09.2021.
//  Copyright © 2021 Denis. All rights reserved.
//

import Foundation

class DAOListViewModel: NSObject, WalletModelDelegate {

    public var items = [BMApp]()
    public var onDataChanged : (() -> Void)?

    override init() {
    }
    
    deinit {
        AppModel.sharedManager().removeDelegate(self)
    }
    
    func loadItems()  {
        AppModel.sharedManager().addDelegate(self)
        AppModel.sharedManager().loadApps()
        items.append(contentsOf: AppModel.sharedManager().apps as! [BMApp])
        items.removeAll { app in
            app.name.contains("Name Service")
        }
    }
    
    func onDAPPsLoaded() {
        DispatchQueue.main.async { [weak self] in
            self?.items.removeAll()
            self?.items.append(contentsOf: AppModel.sharedManager().apps as! [BMApp])
            self?.items.removeAll { app in
                app.name.contains("Name Service")
            }
        }
    }
}
