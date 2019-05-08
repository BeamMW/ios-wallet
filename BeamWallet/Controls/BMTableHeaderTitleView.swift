//
// BMTableHeaderTitleView.swift
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

class BMTableHeaderTitleView: UIView {
   
    static let height:CGFloat = 50
    
    init(title:String) {
        super.init(frame: CGRect(x: 0, y: 0, width: UIScreen.main.bounds.size.width, height: BMTableHeaderTitleView.height))
        
        self.backgroundColor = UIColor.main.marine

        let label = UILabel(frame: CGRect(x: 15, y: 25, width: 200, height: 15))
        label.adjustFontSize = true
        label.font = UIFont(name: "SFProDisplay-Regular", size: 12)
        label.text = title.uppercased()
        label.textColor = UIColor.main.blueyGrey
        self.addSubview(label)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
