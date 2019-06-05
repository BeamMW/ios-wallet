//
// BMSlider.swift
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

class BMSlider: UISlider {
    
    private var maxSteps = 5
    private var height:CGFloat = 4
    
//    override func beginTracking(_ touch: UITouch, with event: UIEvent?) -> Bool {
//        return true
//    }
    
    override func trackRect(forBounds bounds: CGRect) -> CGRect {
        var newBounds = super.trackRect(forBounds: bounds)
        newBounds.size.height = height
        return newBounds
    }
    
    override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        var bounds: CGRect = self.bounds
        bounds = bounds.insetBy(dx: -10, dy: -15)
        return bounds.contains(point)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        for i in 1 ... maxSteps + 1 {
            if let line = viewWithTag(i) {
                line.removeFromSuperview()
            }
            if i > 1 {
                let x = CGFloat(i-1) * (self.frame.size.width-2) / (CGFloat(maxSteps-1))
                
                if i == maxSteps {
                    let w = (self.frame.size.width-2) / (CGFloat(maxSteps-1))
                    let line = UIView(frame: CGRect(x: x-w, y: (self.frame.size.height - 6)/2 + 2.5, width: w, height: height - 0.5))
                    line.clipsToBounds = true
                    line.backgroundColor = Settings.sharedManager().target == Testnet ? UIColor.main.red.withAlphaComponent(0.5) : UIColor.main.red.withAlphaComponent(0.95)

                    let rectShape = CAShapeLayer()
                    rectShape.bounds = line.frame
                    rectShape.position = line.center
                    rectShape.path = UIBezierPath(roundedRect: line.bounds, byRoundingCorners: [.bottomRight , .topRight], cornerRadii: CGSize(width: 2.25, height: 2.25)).cgPath
                    line.layer.mask = rectShape
                    line.tag = i
                    
                    addLine(x: line.frame.size.width-2, y:0, toView: line, tag:i)
                    addLine(x: 0, y:0, toView: line, tag:i-1)
                    
                    insertSubview(line, at: 0)
                }
                else if i < (maxSteps-1) {
                    addLine(x: x, y: 7, toView: self, tag:i)
                }
            }
        }
    }
    
    private func addLine(x:CGFloat, y:CGFloat, toView:UIView, tag:Int)
    {
        let v = UIView(frame: CGRect(x: x, y: y, width: 2, height: height))
        v.tag = tag
        v.backgroundColor = UIColor.lightGray
        toView.insertSubview(v, at: 0)
    }

}
