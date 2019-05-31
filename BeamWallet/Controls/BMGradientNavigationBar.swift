//
// BMGradientNavigationBar.swift
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

class BMGradientNavigationBar: UINavigationBar {
    
    public static let height:CGFloat = 180
    private var backgroundImage:UIImageView!
    
    public var offset:CGFloat = 0 {
        didSet {
            changeFrame()
        }
    }
    
    private let colors = [UIColor.main.brightSkyBlue, UIColor.main.marine]
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        if #available(iOS 11, *) {
            translatesAutoresizingMaskIntoConstraints = false
        }
        
        layoutSubviews()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError(LocalizableStrings.fatalInitCoderError)
    }
    
    override func sizeThatFits(_ size: CGSize) -> CGSize {
        return CGSize(width: UIScreen.main.bounds.width, height: BMGradientNavigationBar.height)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        guard #available(iOS 11, *) else {
            return
        }
        
        changeFrame()
    }
    
    private func changeFrame() {
        CATransaction.begin()
        CATransaction.setDisableActions(true)

        frame = CGRect(x: frame.origin.x, y:  0, width: frame.size.width, height: BMGradientNavigationBar.height - offset)
        
        for subview in self.subviews {
            var stringFromClass = NSStringFromClass(subview.classForCoder)
            if stringFromClass.contains("BarBackground") {
                subview.frame = CGRect(x: 0, y: 0, width: UIScreen.main.bounds.self.width, height: BMGradientNavigationBar.height - offset)

                if subview.layer.sublayers?.first as? CAGradientLayer == nil {
                    let gradient: CAGradientLayer = CAGradientLayer()

                    gradient.colors = colors.map { $0.cgColor }
                    gradient.locations = [0.0, 1.0]
                    gradient.frame = CGRect(x: 0.0, y: 0.0, width: UIScreen.main.bounds.self.width, height: subview.frame.size.height)

                    subview.layer.insertSublayer(gradient, at: 0)
                }
                else{
                    let gradient = subview.layer.sublayers!.first as! CAGradientLayer
                    gradient.frame = CGRect(x: 0.0, y: 0.0, width: UIScreen.main.bounds.self.width, height: subview.frame.size.height)
                }
            }
            
            stringFromClass = NSStringFromClass(subview.classForCoder)
            if stringFromClass.contains("BarContent") {
                subview.frame = CGRect(x: subview.frame.origin.x, y: 40, width: subview.frame.width, height: subview.frame.height)
            }
        }
        
        CATransaction.commit()
    }
}
