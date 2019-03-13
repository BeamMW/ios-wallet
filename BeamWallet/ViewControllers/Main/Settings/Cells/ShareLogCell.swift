//
//  ShareLogCell.swift
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

protocol ShareLogCellDelegate: AnyObject {
    func onClickReport()
}

class ShareLogCell: UITableViewCell {

    weak var delegate: ShareLogCellDelegate?

    override func awakeFromNib() {
        super.awakeFromNib()
       
        selectionStyle = .none
    }
    
    @IBAction func onReport(sender :UIButton) {
        self.delegate?.onClickReport()
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
    
}
