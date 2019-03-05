//
//  WalletStatusCell.swift
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

protocol WalletStatusCellDelegate: AnyObject {
    func onClickReceived()
    func onClickSend()
}

class WalletStatusCell: UITableViewCell {

    weak var delegate: WalletStatusCellDelegate?

    @IBOutlet weak private var statusLabel: UILabel!
    @IBOutlet weak private var statusView: UIView!

    override func awakeFromNib() {
        super.awakeFromNib()
        
        selectionStyle = .none
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
    
    @IBAction func onReceived(sender :UIButton) {
        self.delegate?.onClickReceived()
    }
    
    @IBAction func onSend(sender :UIButton) {
        self.delegate?.onClickSend()
    }
}

extension WalletStatusCell: Configurable {
    
    func configure(with networkStatus:Bool) {
        if networkStatus {
            statusView.backgroundColor = UIColor.main.green
            statusLabel.text = "online"
            statusLabel.textColor = UIColor.main.blueyGrey
        }
        else{
            statusView.backgroundColor = UIColor.main.red
            statusLabel.text = "offline"
            statusLabel.textColor = UIColor.main.red
        }
    }
}
