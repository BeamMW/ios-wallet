//
// AddressesSegmentView.swift
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

protocol AddressesSegmentViewDelegate: AnyObject {
    func onFilterClicked(index:Int)
}

class AddressesSegmentView: BaseView {

    @IBOutlet weak private var segmetnView: UISegmentedControl!

    public static let height:CGFloat = 95
    
    weak var delegate: AddressesSegmentViewDelegate?

    override func awakeFromNib() {
        super.awakeFromNib()
        
        segmetnView.removeAllSegments()
        segmetnView.insertSegment(withTitle: Localizables.shared.strings.active, at: 0, animated: false)
        segmetnView.insertSegment(withTitle: Localizables.shared.strings.expired, at: 1, animated: false)
        segmetnView.insertSegment(withTitle: Localizables.shared.strings.contacts, at: 2, animated: false)
        segmetnView.selectedSegmentIndex = 0
    }
    
    public func setSelectedIndex(index:Int) {
        segmetnView.selectedSegmentIndex = index
    }
    
    @IBAction func onFilterSegment(sender :UISegmentedControl) {
        delegate?.onFilterClicked(index: sender.selectedSegmentIndex)
    }
}
