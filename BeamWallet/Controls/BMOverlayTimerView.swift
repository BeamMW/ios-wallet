//
// BMOverlayTimerView.swift
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

class BMOverlayTimerView: UIView, BMCountdownViewDelegate {

    private var seconds = 0
    private var url:URL!
    
    public static func show (text:String, link:URL) {
        let view = BMOverlayTimerView(text: text, link: link)
        view.display()
     }
    
    init(text:String, link:URL) {
        super.init(frame: UIScreen.main.bounds)
        
        alpha = 0
        
        let blurEffect = UIBlurEffect(style: .dark)
        let blurView = UIVisualEffectView(effect: blurEffect)
        blurView.frame = frame
        addSubview(blurView)
        
        url = link
        
        let window = (UIApplication.shared.delegate as! AppDelegate).window

        self.backgroundColor = UIColor.main.marine.withAlphaComponent(0.4)
        
        let label = UILabel(frame: CGRect.zero)
        label.font = RegularFont(size: 17)
        label.textColor = UIColor.white
        label.numberOfLines = 0
        label.text = Localizable.shared.strings.faucet_redirect_text
        label.textAlignment = .center
        let size = label.sizeThatFits(CGSize(width: 260, height: 99999))
        label.frame = CGRect(x: (self.width - size.width)/2,y: (self.h - size.height)/2, width: size.width, height: size.height)
        addSubview(label)
        
        let timer = BMCountdownView(frame: CGRect(x: (self.width - 28)/2, y: label.frame.origin.y - 40, width: 28, height: 28))
        timer.delegate = self
        timer.backgroundColor = UIColor.clear
        timer.lineColor = UIColor.white
        timer.trailLineColor = UIColor.main.steelGrey.withAlphaComponent(0.1)
        timer.counterLabel.textColor = UIColor.white
        timer.start(beginingValue: 4)
        addSubview(timer)
        
        window?.addSubview(self)
    }
    
    public func display()
    {
        UIView.animate(withDuration: 0.3) {
            self.alpha = 1
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError(Localizable.shared.strings.fatalInitCoderError)
    }
    
    internal func timerDidEnd() {
        UIApplication.shared.open(url, options: [:], completionHandler: nil)
        removeFromSuperview()
    }
}
