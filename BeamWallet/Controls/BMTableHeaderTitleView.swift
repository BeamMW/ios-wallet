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
    static let boldHeight:CGFloat = 60

    public var titleLabel:UILabel!

    public var isCenter = false {
        didSet {
            if isCenter {
                titleLabel.y = 0
                titleLabel.h = self.h
            }
        }
    }
    
    init(title:String, bold:Bool) {
        super.init(frame: CGRect(x: 0, y: 0, width: UIScreen.main.bounds.size.width, height: bold ? BMTableHeaderTitleView.boldHeight : BMTableHeaderTitleView.height))
        
        self.backgroundColor = UIColor.main.marine

        addLabel(title: title, bold: bold)
    }
    
    init(title:String, handler:Selector, target:Any) {
        super.init(frame: CGRect(x: 0, y: 0, width: UIScreen.main.bounds.size.width, height: BMTableHeaderTitleView.height))

        self.backgroundColor = UIColor.main.marine
        
        addLabel(title: title, bold: true)
        
        titleLabel.font = BoldFont(size: 18)
        titleLabel.y = 22
        
        let button = UIButton(frame: CGRect(x: self.frame.size.width-45, y: 10, width: 40, height: 40))
        button.setImage(MoreIcon(), for: .normal)
        button.contentHorizontalAlignment = .right
        button.addTarget(target, action: handler, for: .touchUpInside)
        self.addSubview(button)
    }
    
    private func addLabel(title:String, bold:Bool) {
        titleLabel = UILabel(frame: CGRect(x: defaultX, y: 25, width: defaultWidth, height: 15))
        titleLabel.adjustFontSize = true
        titleLabel.font = bold ? BoldFont(size: 16) : RegularFont(size: 12)
        titleLabel.text = bold ? title : title.uppercased()
        titleLabel.textColor = bold ? UIColor.white : UIColor.main.blueyGrey
        titleLabel.adjustsFontSizeToFitWidth = true
        titleLabel.minimumScaleFactor = 0.3
        self.addSubview(titleLabel)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError(Localizable.shared.strings.fatalInitCoderError)
    }
    
    var letterSpacing: CGFloat = 0 {
        didSet {
            if self.letterSpacing > 0 {
                if let titleString = self.titleLabel.text {
                    let attributedString = NSMutableAttributedString(string: titleString)
                    attributedString.addAttribute(NSAttributedString.Key.kern, value: CGFloat(self.letterSpacing), range: NSRange(location: 0, length: titleString.count))
                    attributedString.addAttribute(NSAttributedString.Key.font, value: BoldFont(size: 14), range: NSRange(location: 0, length: titleString.count))
                    attributedString.addAttribute(NSAttributedString.Key.foregroundColor, value: UIColor.main.blueyGrey, range: NSRange(location: 0, length: titleString.count))
                    
                    self.titleLabel.attributedText = attributedString
                }
            }
        }
    }
}
