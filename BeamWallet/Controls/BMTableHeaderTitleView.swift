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

protocol BMTableHeaderTitleViewDelegate: AnyObject {
    func onDidSelectSegment(index:Int)
}


class BMTableHeaderTitleView: UIView {
   
    weak var delegate: BMTableHeaderTitleViewDelegate?

    static let height:CGFloat = 50
    static let boldHeight:CGFloat = 60
    static let segmentHeight:CGFloat = 80

    private var titleLabel:UILabel!
    private var segmentLine:UIView!

    public var selectedIndex:Int = 0 {
        didSet{
            if let button = self.viewWithTag(selectedIndex+1) as? UIButton {
                UIView.animate(withDuration: 0.15) {
                    self.segmentLine.frame = CGRect(x: button.x-3, y: button.y + button.frame.size.height + 10, width: button.width+6, height: 3)
                }
            }
        }
    }
    
    init(segments:[String]) {
        super.init(frame: CGRect(x: 0, y: 0, width: UIScreen.main.bounds.size.width, height: BMTableHeaderTitleView.boldHeight))

        self.backgroundColor = UIColor.main.marine

        segmentLine = UIView(frame: CGRect(x: 0, y: 0, width: 0, height: 3))
        segmentLine.backgroundColor = UIColor.main.heliotrope
        
        var x:CGFloat = 15
        var tag:Int = 1
        for title in segments {
            let aString:NSString = title.uppercased() as NSString
            
            let rectNeeded = aString.boundingRect(with: CGSize(width: 9999, height: 15), options: .usesLineFragmentOrigin, attributes: [NSAttributedString.Key.font: BoldFont(size: 16)], context: nil)
            
            let titleLabel = UIButton(frame: CGRect(x: x, y: 25, width: rectNeeded.width, height: 15))
            titleLabel.adjustFontSize = true
            titleLabel.titleLabel?.font = BoldFont(size: 16)
            titleLabel.setTitle(title.uppercased(), for: .normal)
            titleLabel.setTitleColor(UIColor.main.blueyGrey, for: .normal)
            titleLabel.setTitleColor(UIColor.main.blueyGrey.withAlphaComponent(0.4), for: .highlighted)
            titleLabel.tag = tag
            titleLabel.addTarget(self, action: #selector(onSegmentItem), for: .touchUpInside)
            x = x + rectNeeded.width + 30
            tag = tag + 1
            
            self.addSubview(titleLabel)
        }
        
        self.addSubview(segmentLine)
        
        if let button = self.viewWithTag(selectedIndex+1) as? UIButton {
            self.segmentLine.frame = CGRect(x: button.x-3, y: button.y + button.frame.size.height + 10, width: button.width+6, height: 3)
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
    
    @objc private func onSegmentItem(sender:UIButton) {
        selectedIndex = sender.tag - 1
        
        self.delegate?.onDidSelectSegment(index: selectedIndex)
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
        fatalError(Localizables.shared.strings.fatalInitCoderError)
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
