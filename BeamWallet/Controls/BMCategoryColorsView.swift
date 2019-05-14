//
// BMCategoryColorsView.swift
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

protocol BMColorViewDelegate: AnyObject {
    func onSelectColor(color:UIColor)
}

class BMCategoryColorsView: UIView {

    class BMColorView: UIView {
        
        weak var delegate: BMColorViewDelegate?

        public var color:UIColor!
        private var circleView:UIView!

        init(color:UIColor, frame:CGRect) {
            
            super.init(frame: frame)
            
            self.color = color
            
            let button = UIButton(frame: CGRect(x: 4, y: 4, width: frame.size.width-8, height: frame.size.height - 8))
            button.cornerRadius = button.frame.size.width/2
            button.setBackgroundColor(color: color, forState: .normal)
            button.addTarget(self, action: #selector(onSelectColor), for: .touchUpInside)
            self.addSubview(button)
            
            circleView = UIView(frame: CGRect(x: 0, y: 0, width: frame.size.width, height: frame.size.height))
            circleView.backgroundColor = UIColor.clear
            circleView.layer.cornerRadius = circleView.frame.size.width/2
            circleView.layer.borderWidth = 2
            circleView.layer.borderColor = UIColor.main.brightTeal.cgColor
            circleView.alpha = 0
            self.addSubview(circleView)
        }
        
        required init?(coder aDecoder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        
        @objc private func onSelectColor() {
            self.delegate?.onSelectColor(color: self.color)
        }
        
        public var selected:Bool = false {
            didSet{
                UIView.animate(withDuration: 0.3) {
                    self.circleView.alpha = self.selected ? 1 : 0
                }
            }
        }
    }
    
    weak var delegate: BMColorViewDelegate?

    public var colors:[UIColor] = [] {
        didSet{
            fillBMColorView()
        }
    }
    
    public var selectedColor:UIColor = UIColor.clear {
        didSet{
            selectColor()
        }
    }
    
    private func selectColor() {
        for view in self.subviews {
            if let colorView = view as? BMColorView {
                if colorView.color.toHexString() == selectedColor.toHexString() {
                    colorView.selected = true
                }
                else{
                    colorView.selected = false
                }
            }
        }
    }
    
    private func fillBMColorView() {
        
        let size:CGFloat = Device.isLarge ? 38 : 30
        let space:CGFloat = Device.isLarge ? 30 : 20
        var x:CGFloat = 0
        
        for color in colors {
            
            let colorView = BMColorView(color: color, frame: CGRect(x: x, y: 0, width: size, height: size))
            colorView.delegate = self
            self.addSubview(colorView)
            
            x = x + (size + space)
        }
    }
    
    public func colorsWidht()->CGFloat {
        if self.subviews.count > 0 {
            if let last = self.subviews.last {
                return last.frame.origin.x + last.frame.size.width
            }
        }
        return 0
    }
}

extension BMCategoryColorsView : BMColorViewDelegate {
    
    func onSelectColor(color: UIColor) {
        self.delegate?.onSelectColor(color: color)
    }
}
