//
// UTXOSegmentView.swift
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

class UTXOSegmentView: UIView {

    public static let height:CGFloat = 55
    
    private var segmentView:UISegmentedControl!
    private var done : ((_ selectedItem : Int) -> Void)!

    init(selected: @escaping (Int) -> Void) {
        super.init(frame: CGRect(x: 0, y: 0, width: UIScreen.main.bounds.size.width, height: UTXOSegmentView.height))
        
        backgroundColor = UIColor.main.marine
        
        self.done = selected
        
        segmentView = UISegmentedControl(frame: CGRect(x: 15, y: 5, width: UIScreen.main.bounds.size.width-30, height: 27))
        segmentView.insertSegment(withTitle: LocalizableStrings.active, at: 0, animated: false)
        segmentView.insertSegment(withTitle: LocalizableStrings.all, at: 1, animated: false)
        segmentView.tintColor = UIColor.main.brightTeal
        segmentView.selectedSegmentIndex = 0
        segmentView.addTarget(self, action: #selector(onSegment), for: .valueChanged)
        addSubview(segmentView)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError(LocalizableStrings.fatalInitCoderError)
    }
    
    @objc private func onSegment() {
        self.done(segmentView.selectedSegmentIndex)
    }
    
}
