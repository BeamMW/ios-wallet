//
//  BMStatusView.swift
//  BeamWallet
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

class BMNetworkStatusView: UIView {

    private var statusLabel: UILabel!
    private var statusView: UIView!
    private var indicatorView:UIActivityIndicatorView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        statusView = UIView(frame: CGRect(x: 0, y: 2, width: 12, height: 12))
        statusView.layer.cornerRadius = 6
        statusView.layer.masksToBounds = true
        addSubview(statusView)
        
        statusLabel = UILabel(frame: CGRect(x: 18, y: 0, width: 120, height: 14))
        statusLabel.font = UIFont(name: "SFProDisplay-Regular", size: 14)
        addSubview(statusLabel)
        
        indicatorView = UIActivityIndicatorView(frame: statusView.frame)
        indicatorView.hidesWhenStopped = true
        addSubview(indicatorView)

        if (AppModel.sharedManager().isUpdating && AppModel.sharedManager().isConnected)
        {
            onSyncProgressUpdated(0, total: 1)
        }
        else{
            onNetwotkStatusChange(AppModel.sharedManager().isConnected)
        }
        
        AppModel.sharedManager().addDelegate(self)
    }
    
    deinit {
        AppModel.sharedManager().removeDelegate(self)
    }
}

extension BMNetworkStatusView: WalletModelDelegate {
    func onNetwotkStatusChange(_ connected: Bool) {
        
        DispatchQueue.main.async {
            self.indicatorView.stopAnimating()
            self.statusView.alpha = 1
            
            self.statusLabel.x = 18
            
            if connected {
                self.statusView.backgroundColor = UIColor.main.green
                self.statusLabel.text = "online (testnet)"
                self.statusLabel.textColor = UIColor.main.blueyGrey
            }
            else{
                self.statusView.backgroundColor = UIColor.main.red
                self.statusLabel.text = "offline (testnet)"
                self.statusLabel.textColor = UIColor.main.red
            }
        }
    }
    
    func onSyncProgressUpdated(_ done: Int32, total: Int32) {
        
        DispatchQueue.main.async {
            if done != total {
                self.indicatorView.color = UIColor.main.green
                self.indicatorView.startAnimating()
                
                self.statusLabel.x = 20
                self.statusLabel.text = "updating"
                self.statusView.alpha = 0
            }
            else {
                self.indicatorView.stopAnimating()
                self.onNetwotkStatusChange(AppModel.sharedManager().isConnected)
            }
        }
    }
    
    func onNetwotkStartConnecting(_ connecting: Bool) {
        DispatchQueue.main.async {
            if connecting {
                self.statusView.alpha = 0

                self.indicatorView.color = UIColor.main.orange
                self.indicatorView.startAnimating()
                
                self.statusLabel.x = 20
                self.statusLabel.text = "connecting"
                self.statusView.backgroundColor = UIColor.main.orange
                self.statusLabel.textColor = UIColor.main.orange
            }
        }
    }
}
