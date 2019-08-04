//
// BMSegmentView.swift
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

class BMSegmentView: UIView {
    
    weak var delegate: BMTableHeaderTitleViewDelegate?
    
    static let height:CGFloat = 50
    
    private var segmentLine:UIView!
    private var lineOffset:CGFloat = 3
    private var segmentScroll:UIScrollView!
    
    public var selectedIndex:Int = 0 {
        didSet{
            if let button = segmentScroll.viewWithTag(selectedIndex+1) as? UIButton {
                UIView.animate(withDuration: 0.15) {
                    self.segmentLine.frame = CGRect(x: button.x - self.lineOffset, y: self.frame.size.height - 3, width: button.width + (self.lineOffset * 2), height: 3)
                }
            }
        }
    }
    
    public var lineColor:UIColor = UIColor.main.heliotrope {
        didSet {
            segmentLine.backgroundColor = lineColor
        }
    }
    
    init(segments:[String]) {
        super.init(frame: CGRect(x: 0, y: 0, width: UIScreen.main.bounds.size.width, height: BMSegmentView.height))
        
        segmentScroll = UIScrollView(frame: self.bounds)
        segmentScroll.showsVerticalScrollIndicator = false
        segmentScroll.showsHorizontalScrollIndicator = false
        
        if segments.count == 3 {
            lineOffset = 0
        }
        
        self.backgroundColor = UIColor.main.marine
        
        segmentLine = UIView(frame: CGRect(x: 0, y: 0, width: 0, height: 3))
        segmentLine.backgroundColor = lineColor
        
        var x:CGFloat = (segments.count == 3) ? 0 : 15
        var tag:Int = 1
        
        var fontSize:CGFloat = 16
        
        if Device.screenType == .iPhone_XSMax || Device.screenType == .iPhones_Plus {
            fontSize = fontSize + 1.0
        }
        else if Device.screenType == .iPhones_5{
            fontSize = fontSize - 1.5
        }
        
        for title in segments {
            let attributedString = NSMutableAttributedString(string: title.uppercased())
            attributedString.addAttribute(NSAttributedString.Key.kern, value: CGFloat(1.5), range: NSRange(location: 0, length: title.uppercased().count))
            attributedString.addAttribute(NSAttributedString.Key.foregroundColor, value: UIColor.main.blueyGrey, range: NSRange(location: 0, length: title.uppercased().count))
            attributedString.addAttribute(NSAttributedString.Key.font, value: BoldFont(size: fontSize), range: NSRange(location: 0, length: title.uppercased().count))
            
            let highlightedAttributedString = NSMutableAttributedString(attributedString: attributedString)
            highlightedAttributedString.addAttribute(NSAttributedString.Key.foregroundColor, value: UIColor.main.blueyGrey.withAlphaComponent(0.4), range: NSRange(location: 0, length: title.uppercased().count))
            
            let stringSize = attributedString.boundingRect(with: CGSize(width: 9999, height: 15), options: .usesLineFragmentOrigin, context: nil)
            let rectNeeded = CGSize(width: stringSize.width + 4, height: 40)
            
            let titleLabel = UIButton(frame: CGRect(x: x, y: 0, width: (segments.count == 3) ? (self.width / 3) : rectNeeded.width, height: 40))
            titleLabel.titleEdgeInsets = UIEdgeInsets(top: 25, left: 0, bottom: 0, right: 0)
            titleLabel.tag = tag
            titleLabel.addTarget(self, action: #selector(onSegmentItem), for: .touchUpInside)
            titleLabel.setAttributedTitle(attributedString, for: .normal)
            titleLabel.setAttributedTitle(highlightedAttributedString, for: .highlighted)
            
            if segments.count == 3 {
                x = x + (self.width / 3)
            }
            else{
                x = x + rectNeeded.width + 30
            }
            tag = tag + 1
            
            segmentScroll.addSubview(titleLabel)
        }
        
        segmentScroll.addSubview(segmentLine)
        
        if let button = segmentScroll.viewWithTag(selectedIndex+1) as? UIButton {
            self.segmentLine.frame = CGRect(x: button.x-lineOffset, y: self.frame.size.height - 3, width: button.width+(lineOffset*2), height: 3)
        }
        
        segmentScroll.contentSize = CGSize(width: x, height: 0)
        
        self.addSubview(segmentScroll)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError(Localizable.shared.strings.fatalInitCoderError)
    }
    
    @objc private func onSegmentItem(sender:UIButton) {
        selectedIndex = sender.tag - 1
        
        self.delegate?.onDidSelectSegment(index: selectedIndex)        
    }
}
