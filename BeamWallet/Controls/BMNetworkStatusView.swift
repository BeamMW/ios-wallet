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
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        statusView = UIView(frame: CGRect(x: 0, y: 0, width: 12, height: 12))
        statusView.layer.cornerRadius = 6
        statusView.layer.masksToBounds = true
        addSubview(statusView)
        
        statusLabel = UILabel(frame: CGRect(x: 17, y: 0, width: 120, height: 12))
        statusLabel.font = UIFont(name: "SFProDisplay-Regular", size: 14)
        addSubview(statusLabel)

        onNetwotkStatusChange(AppModel.sharedManager().isConnected)
        
        AppModel.sharedManager().addDelegate(self)
    }
    
    deinit {
        AppModel.sharedManager().removeDelegate(self)
    }
}

extension BMNetworkStatusView: WalletModelDelegate {
    func onNetwotkStatusChange(_ connected: Bool) {
        DispatchQueue.main.async {
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
}
