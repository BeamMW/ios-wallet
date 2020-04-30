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
    
    public var textColor:UIColor? {
        didSet{
            titleLabel.textColor = textColor
        }
    }
    
    public var aligment:NSTextAlignment? {
        didSet{
            titleLabel.textAlignment = aligment ?? .left
        }
    }
    
    public var textFont:UIFont? {
        didSet{
            titleLabel.font = textFont
            titleLabel.adjustFontSize = true
        }
    }
    
    public var buttonImage:UIImage?{
        didSet{
            if let button = viewWithTag(10) as? UIButton {
                button.setImage(buttonImage, for: .normal)
            }
        }
    }
    
    public var buttonFrame:CGRect? {
        didSet{
            if let button = viewWithTag(10) as? UIButton, let frame = buttonFrame{
                button.frame = frame
                button.setBackgroundImage(UIImage.fromColor(color: UIColor.black.withAlphaComponent(0.3)), for: .highlighted)
                button.imageEdgeInsets = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 15)
                titleLabel.frame = CGRect(x: 15, y: 0, width: frame.size.width, height: frame.size.height)
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
        button.tag = 10
        button.contentHorizontalAlignment = .right
        button.addTarget(target, action: handler, for: .touchUpInside)
        self.addSubview(button)
    }
    
    init(title:String, handler:Selector, target:Any, expand:Bool) {
        super.init(frame: CGRect(x: 0, y: 0, width: UIScreen.main.bounds.size.width, height: BMTableHeaderTitleView.height))
        
        self.backgroundColor = UIColor.white.withAlphaComponent(0.05)
        
        addLabel(title: title, bold: true)
        
        titleLabel.h = 50
        titleLabel.y = 0
        titleLabel.font = BoldFont(size: 14)
        titleLabel.letterSpacing = 1.5
        
        let button = UIButton(frame: CGRect(x: self.frame.size.width-50, y: 0, width: 40, height: 50))
        button.setImage(expand ? IconDownArrow() : IconNextArrow(), for: .normal)
        button.contentHorizontalAlignment = .right
        button.isUserInteractionEnabled = false
        self.addSubview(button)
        
        let mainButton = UIButton(frame: self.bounds)
        mainButton.addTarget(target, action: handler, for: .touchUpInside)
        mainButton.setBackgroundImage(UIImage.fromColor(color: UIColor.main.selectedColor), for: .highlighted)
        self.addSubview(mainButton)
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
